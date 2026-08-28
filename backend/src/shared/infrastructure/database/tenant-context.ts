import { AsyncLocalStorage } from 'node:async_hooks';
import { ForbiddenException, Injectable } from '@nestjs/common';
import type { Schema } from 'mongoose';

type TenantStore = { tenantId?: string };
const storage = new AsyncLocalStorage<TenantStore>();

function currentTenantId() {
  return storage.getStore()?.tenantId;
}

export function tenantScopePlugin(schema: Schema) {
  schema.add({ tenantId: { type: String, required: true, index: true } });
  const queryHooks = [
    'countDocuments',
    'deleteMany',
    'deleteOne',
    'find',
    'findOne',
    'findOneAndDelete',
    'findOneAndReplace',
    'findOneAndUpdate',
    'replaceOne',
    'updateMany',
    'updateOne',
  ] as const;
  for (const hook of queryHooks) {
    schema.pre(hook, function tenantQueryScope() {
      const store = storage.getStore();
      if (!store?.tenantId)
        throw new ForbiddenException('Contexto de família obrigatório.');
      this.where({ tenantId: store.tenantId });
      const update =
        'getUpdate' in this
          ? (this.getUpdate() as Record<string, unknown> | null)
          : null;
      if (update && hook.startsWith('update')) {
        const setOnInsert = (update.$setOnInsert ?? {}) as Record<
          string,
          unknown
        >;
        update.$setOnInsert = { ...setOnInsert, tenantId: store.tenantId };
      }
    });
  }
  schema.pre('aggregate', function tenantAggregateScope() {
    const store = storage.getStore();
    if (!store?.tenantId)
      throw new ForbiddenException('Contexto de família obrigatório.');
    this.pipeline().unshift({ $match: { tenantId: store.tenantId } });
  });
  schema.pre('save', function tenantDocumentScope(next) {
    const store = storage.getStore();
    if (!store?.tenantId)
      return next(new ForbiddenException('Contexto de família obrigatório.'));
    this.set('tenantId', store.tenantId);
    next();
  });
  schema.pre('insertMany', function tenantInsertMany(next, docs) {
    const store = storage.getStore();
    if (!store?.tenantId)
      return next(new ForbiddenException('Contexto de família obrigatório.'));
    for (const doc of docs as Array<Record<string, unknown>>) {
      doc.tenantId = store.tenantId;
    }
    next();
  });
}

@Injectable()
export class TenantContextService {
  enter(tenantId: string) {
    storage.enterWith({ tenantId });
  }
  run<T>(tenantId: string, callback: () => T): T {
    return storage.run({ tenantId }, callback);
  }
  get tenantId() {
    return currentTenantId();
  }
}
