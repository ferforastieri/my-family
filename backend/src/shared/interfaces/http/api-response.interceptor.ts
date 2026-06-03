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
        const message = responseMessage(context, type, body);
        return {
          ok: true,
          message,
          data: stripMessage(body),
          timestamp: new Date().toISOString(),
        };
      }),
    );
  }
}

function responseMessage(
  context: ExecutionContext,
  type: string,
  body: unknown,
): string {
  if (hasMessage(body)) return body.message;
  const key = `${context.getClass().name}.${context.getHandler().name}`;
  if (responseMessages[key]) return responseMessages[key];
  return type === 'ws'
    ? 'Ação realizada com sucesso.'
    : 'Requisição concluída.';
}

function stripMessage<T>(body: T): T {
  if (!hasMessage(body)) return body;
  if (!isPlainObject(body)) return body;
  const { message: _message, ...rest } = body as ApiMessage &
    Record<string, unknown>;
  return rest as T;
}

const responseMessages: Record<string, string> = {
  'AuthGateway.login': 'Login realizado com sucesso.',
  'AuthGateway.register': 'Cadastro realizado com sucesso.',
  'AuthGateway.updateMe': 'Perfil atualizado.',
  'AuthGateway.forgotPassword': 'Se o email existir, você receberá instruções.',
  'AuthGateway.resetPassword': 'Senha redefinida com sucesso.',
  'AuthGateway.updateUser': 'Usuário atualizado.',
  'AuthGateway.deleteUser': 'Usuário removido.',
  'AuthController.register': 'Cadastro realizado com sucesso.',
  'AuthController.login': 'Login realizado com sucesso.',
  'AuthController.uploadAvatar': 'Foto do perfil atualizada.',
  'AuthController.forgotPassword':
    'Se o email existir, você receberá instruções.',
  'AuthController.resetPassword': 'Senha redefinida com sucesso.',
  'FotosGateway.create': 'Memória salva com sucesso.',
  'FotosGateway.update': 'Memória atualizada.',
  'FotosGateway.delete': 'Memória removida.',
  'MusicasGateway.create': 'Música salva com sucesso.',
  'MusicasGateway.update': 'Música atualizada.',
  'MusicasGateway.delete': 'Música removida.',
  'CartasGateway.create': 'Texto salvo.',
  'CartasGateway.update': 'Texto atualizado.',
  'CartasGateway.delete': 'Texto removido.',
  'ListsGateway.createList': 'Lista criada.',
  'ListsGateway.updateList': 'Lista atualizada.',
  'ListsGateway.deleteList': 'Lista removida.',
  'ListsGateway.createItem': 'Item adicionado.',
  'ListsGateway.updateItem': 'Item atualizado.',
  'ListsGateway.deleteItem': 'Item removido.',
  'ChatGateway.createConversation': 'Conversa criada.',
  'ChatGateway.send': 'Mensagem enviada.',
  'GamesGateway.createQuestion': 'Pergunta salva.',
  'GamesGateway.updateQuestion': 'Pergunta atualizada.',
  'GamesGateway.deleteQuestion': 'Pergunta removida.',
  'GamesGateway.createWord': 'Palavra salva.',
  'GamesGateway.updateWord': 'Palavra atualizada.',
  'GamesGateway.deleteWord': 'Palavra removida.',
  'GamesGateway.complete': 'Jogo concluído.',
  'NotificationsGateway.create': 'Notificação salva.',
  'NotificationsGateway.update': 'Notificação atualizada.',
  'NotificationsGateway.delete': 'Notificação removida.',
  'NotificationsGateway.clear': 'Notificações limpas.',
  'NotificationsGateway.send': 'Notificação enfileirada para envio.',
  'NotificationsGateway.schedule': 'Notificação agendada.',
  'NotificationsGateway.subscribe': 'Notificações ativadas.',
  'NotificationsGateway.unsubscribe': 'Notificações desativadas.',
};

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
