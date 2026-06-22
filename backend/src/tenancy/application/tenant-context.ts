import { AsyncLocalStorage } from 'node:async_hooks';
import { Injectable, UnauthorizedException } from '@nestjs/common';
import type { TenantContextValue } from '../domain/tenant.entity';
import type { Server } from 'socket.io';

export const tenantStorage = new AsyncLocalStorage<TenantContextValue>();

@Injectable()
export class TenantContext {
  run<T>(context: TenantContextValue, callback: () => T): T {
    return tenantStorage.run(context, callback);
  }

  enter(context: TenantContextValue): void {
    tenantStorage.enterWith(context);
  }

  get optional(): TenantContextValue | undefined {
    return tenantStorage.getStore();
  }

  get current(): TenantContextValue {
    const context = this.optional;
    if (!context?.tenantId) {
      throw new UnauthorizedException('Contexto da família não selecionado.');
    }
    return context;
  }

  get tenantId(): string {
    return this.current.tenantId;
  }
}

export function tenantRoom(tenantId: string): string {
  return `tenant:${tenantId}`;
}

export function emitToTenant(
  server: Server | undefined,
  event: string,
  payload?: unknown,
): void {
  const tenantId = tenantStorage.getStore()?.tenantId;
  if (!tenantId) {
    throw new Error('TENANT_CONTEXT_MISSING: emissão realtime sem tenantId.');
  }
  server?.to(tenantRoom(tenantId)).emit(event, payload);
}
