import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { BaseWsExceptionFilter, WsException } from '@nestjs/websockets';
import { Response } from 'express';

@Catch()
export class ApiExceptionFilter
  extends BaseWsExceptionFilter
  implements ExceptionFilter
{
  catch(exception: unknown, host: ArgumentsHost) {
    if (host.getType() === 'ws') {
      const client = host.switchToWs().getClient();
      client.emit('exception', {
        ok: false,
        message: exceptionMessage(exception),
        error: exceptionName(exception),
        timestamp: new Date().toISOString(),
      });
      return;
    }

    const response = host.switchToHttp().getResponse<Response>();
    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;

    response.status(status).json({
      ok: false,
      message: exceptionMessage(exception),
      error: exceptionName(exception),
      statusCode: status,
      timestamp: new Date().toISOString(),
    });
  }
}

function exceptionMessage(exception: unknown): string {
  if (exception instanceof WsException) {
    return normalizeMessage(exception.getError());
  }
  if (exception instanceof HttpException) {
    return normalizeMessage(exception.getResponse());
  }
  if (exception instanceof Error && exception.message) return exception.message;
  return 'Erro interno no servidor.';
}

function exceptionName(exception: unknown): string {
  if (exception instanceof Error) return exception.name;
  if (exception instanceof HttpException) return exception.name;
  return 'InternalServerError';
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
