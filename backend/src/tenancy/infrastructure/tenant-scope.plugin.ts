import { Schema } from 'mongoose';
import { tenantStorage } from '../application/tenant-context';

const scopedQueryOperations = [
  'count',
  'countDocuments',
  'deleteMany',
  'deleteOne',
  'distinct',
  'find',
  'findOne',
  'findOneAndDelete',
  'findOneAndReplace',
  'findOneAndUpdate',
  'replaceOne',
  'updateMany',
  'updateOne',
] as const;

function requiredTenantId(): string {
  const tenantId = tenantStorage.getStore()?.tenantId;
  if (!tenantId) {
    throw new Error(
      'TENANT_CONTEXT_MISSING: operação em coleção isolada sem tenantId.',
    );
  }
  return tenantId;
}

export function applyTenantScope(schema: Schema): void {
  schema.add({
    tenantId: { type: String, required: true, index: true, immutable: true },
  });

  for (const operation of scopedQueryOperations) {
    schema.pre(operation as any, function tenantQueryScope(this: any) {
      const tenantId = requiredTenantId();
      const current = this.getQuery();
      if (current.tenantId && String(current.tenantId) !== tenantId) {
        throw new Error('TENANT_SCOPE_VIOLATION: tenantId divergente.');
      }
      this.setQuery({ ...current, tenantId });

      if (typeof this.getOptions === 'function' && this.getOptions().upsert) {
        const update = (this.getUpdate() ?? {}) as Record<string, any>;
        this.setUpdate({
          ...update,
          $setOnInsert: { ...(update.$setOnInsert ?? {}), tenantId },
        });
      }
    });
  }

  schema.pre('save', function tenantDocumentScope() {
    const tenantId = requiredTenantId();
    const document = this as unknown as { tenantId?: string };
    if (document.tenantId && String(document.tenantId) !== tenantId) {
      throw new Error('TENANT_SCOPE_VIOLATION: tenantId divergente.');
    }
    document.tenantId = tenantId;
  });

  schema.pre('insertMany', function tenantInsertManyScope(_next, documents) {
    const tenantId = requiredTenantId();
    for (const document of documents as Array<{ tenantId?: string }>) {
      if (document.tenantId && String(document.tenantId) !== tenantId) {
        throw new Error('TENANT_SCOPE_VIOLATION: tenantId divergente.');
      }
      document.tenantId = tenantId;
    }
  });

  schema.pre('aggregate', function tenantAggregateScope(this: any) {
    const tenantId = requiredTenantId();
    const pipeline = this.pipeline();
    const match = { $match: { tenantId } };
    if ((pipeline[0] as any)?.$geoNear) pipeline.splice(1, 0, match as any);
    else pipeline.unshift(match);
  });
}
