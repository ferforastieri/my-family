import type { Context } from 'hono';
import type { ContentfulStatusCode } from 'hono/utils/http-status';
import type { ZodType } from 'zod';
import type { AppEnv } from './env';

export class ApiError extends Error {
  constructor(
    public readonly status: ContentfulStatusCode,
    message: string,
    public readonly code = 'HttpException',
  ) {
    super(message);
    this.name = code;
  }
}

export const badRequest = (message: string) => new ApiError(400, message, 'BadRequestException');
export const unauthorized = (message = 'Autenticação obrigatória') =>
  new ApiError(401, message, 'UnauthorizedException');
export const forbidden = (message: string) => new ApiError(403, message, 'ForbiddenException');
export const notFound = (message: string) => new ApiError(404, message, 'NotFoundException');
export const conflict = (message: string) => new ApiError(409, message, 'ConflictException');
export const unavailable = (message: string) =>
  new ApiError(503, message, 'ServiceUnavailableException');

function isPlainObject(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

export function envelope<T>(
  c: Context<AppEnv>,
  body: T,
  defaultMessage = 'Requisição concluída.',
) {
  let message = defaultMessage;
  let data: unknown = body;
  if (isPlainObject(body) && typeof body.message === 'string' && body.message.trim()) {
    message = body.message;
    const { message: _message, ...rest } = body;
    data = rest;
  }
  return c.json({
    ok: true,
    message,
    data,
    timestamp: new Date().toISOString(),
  });
}

export async function parseBody<T>(
  c: Context<AppEnv>,
  schema: ZodType<T>,
): Promise<T> {
  let raw: unknown;
  try {
    raw = await c.req.json();
  } catch {
    throw badRequest('Corpo da requisição inválido.');
  }
  const result = schema.safeParse(raw);
  if (!result.success) {
    throw badRequest(result.error.issues.map((issue) => issue.message).join(', '));
  }
  return result.data;
}

export function queryInt(value: string | undefined, fallback: number, max: number): number {
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed < 1) return fallback;
  return Math.min(Math.floor(parsed), max);
}

export function paginated<T>(
  items: T[],
  total: number,
  page: number,
  limit: number,
): { items: T[]; page: number; limit: number; total: number; pages: number } {
  return {
    items,
    page,
    limit,
    total,
    pages: Math.max(1, Math.ceil(total / limit)),
  };
}

export function errorResponse(
  c: Context<AppEnv>,
  error: unknown,
): Response {
  const status = error instanceof ApiError ? error.status : 500;
  const message =
    error instanceof ApiError
      ? error.message
      : error instanceof Error && error.message
        ? error.message
        : 'Erro interno no servidor.';
  const name = error instanceof Error ? error.name : 'InternalServerError';
  if (status >= 500) {
    console.error(
      JSON.stringify({
        level: 'error',
        message,
        name,
        stack: error instanceof Error ? error.stack : undefined,
        path: c.req.path,
        requestId: c.get('requestId'),
      }),
    );
  }
  return c.json(
    {
      ok: false,
      message,
      error: name,
      statusCode: status,
      timestamp: new Date().toISOString(),
    },
    status,
  );
}
