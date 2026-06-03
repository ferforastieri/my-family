import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { map, Observable } from 'rxjs';
import { ApiMessage, ApiResponse, isApiResponse } from './api-response';

@Injectable()
export class ApiResponseInterceptor<T> implements NestInterceptor<
  T,
  ApiResponse<T>
> {
  intercept(
    context: ExecutionContext,
    next: CallHandler<T>,
  ): Observable<ApiResponse<T>> {
    const type = context.getType<'http' | 'ws' | 'rpc'>();
    return next.handle().pipe(
      map((body: T) => {
        if (isApiResponse(body)) return body as ApiResponse<T>;
        if (isStreamableResponse(body)) return body as ApiResponse<T>;
        const message = this.responseMessage(context, type, body);
        return {
          ok: true,
          message,
          data: stripMessage(body),
          timestamp: new Date().toISOString(),
        };
      }),
    );
  }

  private responseMessage(
    context: ExecutionContext,
    type: string,
    body: unknown,
  ): string {
    if (hasMessage(body)) return body.message;
    return type === 'ws'
      ? 'Ação realizada com sucesso.'
      : 'Requisição concluída.';
  }
}

function stripMessage<T>(body: T): T {
  if (!hasMessage(body)) return body;
  if (!isPlainObject(body)) return body;
  const { message: _message, ...rest } = body as ApiMessage &
    Record<string, unknown>;
  return rest as T;
}

function hasMessage(value: unknown): value is Required<ApiMessage> {
  return (
    isPlainObject(value) &&
    typeof (value as ApiMessage).message === 'string' &&
    Boolean((value as ApiMessage).message?.trim())
  );
}

function isPlainObject(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function isStreamableResponse(value: unknown): boolean {
  return (
    typeof value === 'object' &&
    value !== null &&
    value.constructor?.name === 'StreamableFile'
  );
}
