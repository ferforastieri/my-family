import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { BaseWsExceptionFilter, WsException } from '@nestjs/websockets';
import { Response } from 'express';
import type { Socket } from 'socket.io';
import { AuditService } from '../../../audit/application/audit.service';
import type { UserEntity } from '@auth/domain/entities/user.entity';

@Catch()
export class ApiExceptionFilter
  extends BaseWsExceptionFilter
  implements ExceptionFilter
{
  private readonly logger = new Logger(ApiExceptionFilter.name);

  constructor(private readonly audit?: AuditService) {
    super();
  }

  catch(exception: unknown, host: ArgumentsHost) {
    if (host.getType() === 'ws') {
      const payload = {
        ok: false,
        message: exceptionMessage(exception),
        error: exceptionName(exception),
        timestamp: new Date().toISOString(),
      };
      const ack = host.getArgByIndex<
        ((value: typeof payload) => void) | undefined
      >(2);
      this.logException('ws', exception);
      if (typeof ack === 'function') {
        ack(payload);
        return;
      }
      const client = host.switchToWs().getClient<Socket>();
      const user = client.data.user as UserEntity | undefined;
      void this.audit?.record({
        action: 'websocket.error',
        resource: 'websocket',
        source: 'websocket',
        success: false,
        actorUserId: user?.id,
        actorEmail: user?.email,
        tenantId: user?.tenantId,
        metadata: {
          error: exceptionName(exception),
          message: exceptionMessage(exception),
        },
      });
      client.emit('exception', payload);
      return;
    }

    const response = host.switchToHttp().getResponse<Response>();
    const status = exceptionStatus(exception);
    this.logException('http', exception, status);

    response.status(status).json({
      ok: false,
      message: exceptionMessage(exception),
      error: exceptionName(exception),
      statusCode: status,
      timestamp: new Date().toISOString(),
    });
  }

  private logException(
    type: 'http' | 'ws',
    exception: unknown,
    status?: number,
  ) {
    const message = exceptionMessage(exception);
    const errorName = exceptionName(exception);
    const prefix =
      type === 'http' ? `HTTP ${status ?? 500}` : 'WebSocket exception';
    if (exception instanceof Error && exception.stack) {
      this.logger.error(`${prefix}: ${errorName}: ${message}`, exception.stack);
      return;
    }
    this.logger.error(`${prefix}: ${errorName}: ${message}`);
  }
}

function exceptionMessage(exception: unknown): string {
  if (exception instanceof WsException) {
    return normalizeMessage(exception.getError());
  }
  if (exception instanceof HttpException) {
    return normalizeMessage(exception.getResponse());
  }
  if (mongoErrorCode(exception) === 11000) return 'Registro duplicado.';
  if (mongoErrorName(exception) === 'CastError')
    return 'Identificador inválido.';
  if (mongoErrorName(exception) === 'ValidationError')
    return 'Dados inválidos.';
  return 'Erro interno no servidor.';
}

function exceptionStatus(exception: unknown): number {
  if (exception instanceof HttpException) return exception.getStatus();
  if (mongoErrorCode(exception) === 11000) return HttpStatus.CONFLICT;
  if (
    mongoErrorName(exception) === 'CastError' ||
    mongoErrorName(exception) === 'ValidationError'
  ) {
    return HttpStatus.BAD_REQUEST;
  }
  if (typeof exception === 'object' && exception !== null) {
    const statusCode = (exception as { statusCode?: unknown }).statusCode;
    if (typeof statusCode === 'number') return statusCode;
    const status = (exception as { status?: unknown }).status;
    if (typeof status === 'number') return status;
  }
  return HttpStatus.INTERNAL_SERVER_ERROR;
}

function exceptionName(exception: unknown): string {
  if (mongoErrorCode(exception) === 11000) return 'Conflict';
  if (
    mongoErrorName(exception) === 'CastError' ||
    mongoErrorName(exception) === 'ValidationError'
  ) {
    return 'BadRequest';
  }
  if (
    !(exception instanceof HttpException) &&
    !(exception instanceof WsException)
  ) {
    return 'InternalServerError';
  }
  if (exception instanceof Error) return exception.name;
  return 'WebSocketError';
}

function mongoErrorCode(exception: unknown): number | undefined {
  if (typeof exception !== 'object' || exception === null) return undefined;
  const code = (exception as { code?: unknown }).code;
  return typeof code === 'number' ? code : undefined;
}

function mongoErrorName(exception: unknown): string | undefined {
  if (typeof exception !== 'object' || exception === null) return undefined;
  const name = (exception as { name?: unknown }).name;
  return typeof name === 'string' ? name : undefined;
}

function normalizeMessage(value: unknown): string {
  if (typeof value === 'string') return value;
  if (Array.isArray(value)) return value.join(', ');
  if (typeof value === 'object' && value !== null) {
    const map = value as Record<string, unknown>;
    const message = map.message;
    if (Array.isArray(message)) return message.join(', ');
    if (typeof message === 'string') return message;
    if (typeof map.error === 'string') return map.error;
  }
  return 'Erro interno no servidor.';
}
