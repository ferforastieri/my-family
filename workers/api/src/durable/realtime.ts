import { DurableObject } from 'cloudflare:workers';
import type { Env } from '../env';
import { routeRealtimeEvent, type RealtimeSession } from '../realtime-service';

export class TenantRealtime extends DurableObject<Env> {
  async fetch(request: Request): Promise<Response> {
    const url = new URL(request.url);

    if (request.method === 'POST' && url.pathname === '/broadcast') {
      const body = (await request.json()) as {
        event: string;
        data: unknown;
        conversationId?: string;
      };
      this.broadcast(body.event, body.data, body.conversationId);
      return new Response(null, { status: 204 });
    }

    if (request.headers.get('upgrade')?.toLowerCase() !== 'websocket') {
      return new Response('Expected websocket', { status: 426 });
    }

    const session: RealtimeSession = {
      userId: request.headers.get('x-user-id') ?? '',
      tenantId: request.headers.get('x-tenant-id') ?? '',
      name: decodeURIComponent(request.headers.get('x-user-name') ?? ''),
      role: request.headers.get('x-user-role') ?? 'friends',
      access: (request.headers.get('x-user-access') ?? '').split(',').filter(Boolean),
      isAdmin: request.headers.get('x-user-admin') === '1',
      conversationIds: [],
    };
    if (!session.userId || !session.tenantId) {
      return new Response('Unauthorized', { status: 401 });
    }

    const pair = new WebSocketPair();
    const client = pair[0];
    const server = pair[1];
    this.ctx.acceptWebSocket(server, [session.tenantId]);
    server.serializeAttachment(session);
    return new Response(null, { status: 101, webSocket: client });
  }

  async webSocketMessage(ws: WebSocket, message: string | ArrayBuffer): Promise<void> {
    if (typeof message !== 'string') return;
    let payload: { id?: string | number; event?: string; data?: unknown };
    try {
      payload = JSON.parse(message);
    } catch {
      ws.send(JSON.stringify({ event: 'exception', data: { message: 'Payload inválido.' } }));
      return;
    }
    if (!payload.event) return;
    if (payload.event === 'ping') {
      ws.send(JSON.stringify({ event: 'pong', data: null }));
      return;
    }
    const session = (ws.deserializeAttachment() ?? {}) as RealtimeSession;
    try {
      const result = await routeRealtimeEvent(this.env, session, payload.event, payload.data);
      if (result.conversationId && !session.conversationIds.includes(result.conversationId)) {
        session.conversationIds = [...session.conversationIds, result.conversationId];
        ws.serializeAttachment(session);
      }
      for (const broadcast of result.broadcasts ?? []) {
        this.broadcast(broadcast.event, broadcast.data, broadcast.conversationId);
      }
      ws.send(
        JSON.stringify({
          id: payload.id,
          ok: true,
          message: result.message,
          data: result.data,
        }),
      );
    } catch (error) {
      ws.send(
        JSON.stringify({
          id: payload.id,
          ok: false,
          message: error instanceof Error ? error.message : 'Erro no servidor.',
        }),
      );
    }
  }

  async webSocketClose(ws: WebSocket, code: number, reason: string): Promise<void> {
    try {
      ws.close(code, reason);
    } catch {
      // already closed
    }
  }

  private broadcast(event: string, data: unknown, conversationId?: string): void {
    const encoded = JSON.stringify({ event, data });
    for (const ws of this.ctx.getWebSockets()) {
      if (conversationId) {
        const session = (ws.deserializeAttachment() ?? {}) as RealtimeSession;
        if (!session.conversationIds?.includes(conversationId)) continue;
      }
      try {
        ws.send(encoded);
      } catch {
        // socket closed between listing and sending
      }
    }
  }
}
