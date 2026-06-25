import {
  CallHandler,
  ExecutionContext,
  Injectable,
  Logger,
  NestInterceptor,
} from '@nestjs/common';
import { map, Observable } from 'rxjs';
import { ApiMessage, ApiResponse, isApiResponse } from './api-response';
import { AuditService } from '../../../audit/application/audit.service';
import type { Socket } from 'socket.io';
import type { UserEntity } from '@auth/domain/entities/user.entity';

@Injectable()
export class ApiResponseInterceptor<T> implements NestInterceptor<
  T,
  ApiResponse<T>
> {
  private readonly logger = new Logger(ApiResponseInterceptor.name);

  constructor(private readonly audit: AuditService) {}

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
        this.logWsSuccess(context, type, message);
        return {
          ok: true,
          message,
          data: stripMessage(body),
          timestamp: new Date().toISOString(),
        };
      }),
    );
  }

  private logWsSuccess(
    context: ExecutionContext,
    type: string,
    message: string,
  ) {
    if (type !== 'ws') return;
    const client = context.switchToWs().getClient<Socket>();
    const user = client.data.user as UserEntity | undefined;
    const handler = context.getHandler().name;
    const resource = context
      .getClass()
      .name.replace(/Gateway$/, '')
      .toLowerCase();
    this.logger.log(`${context.getClass().name}.${handler} -> ${message}`);
    if (isMutationHandler(handler)) {
      void this.audit.record({
        action: `websocket.${resource}.${handler}`,
        resource,
        source: 'websocket',
        success: true,
        actorUserId: user?.actorUserId ?? user?.id,
        actorEmail: user?.actorEmail ?? user?.email,
        effectiveUserId: user?.actorUserId ? user.id : undefined,
        effectiveUserEmail: user?.actorUserId ? user.email : undefined,
        tenantId: user?.tenantId ?? undefined,
        membershipId: user?.membershipId ?? undefined,
        supportSessionId: user?.supportSessionId ?? undefined,
        metadata: { message },
      });
    }
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

function isMutationHandler(handler: string): boolean {
  return /create|update|delete|send|schedule|clear|read|subscribe|complete/i.test(
    handler,
  );
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
