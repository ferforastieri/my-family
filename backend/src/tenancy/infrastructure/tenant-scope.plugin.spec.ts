import { Schema } from 'mongoose';
import { tenantStorage } from '../application/tenant-context';
import { applyTenantScope } from './tenant-scope.plugin';

describe('tenant scope plugin', () => {
  function schema() {
    const value = new Schema({ title: String });
    applyTenantScope(value);
    return value;
  }

  function runPre(value: Schema, operation: string, target: object) {
    return new Promise<void>((resolve, reject) => {
      (value as any).s.hooks.execPre(operation, target, [], (error?: Error) =>
        error ? reject(error) : resolve(),
      );
    });
  }

  it('injects the active tenant in every query', async () => {
    const value = schema();
    const query = {
      filter: { title: 'hello' } as Record<string, unknown>,
      getQuery() {
        return this.filter;
      },
      setQuery(next: Record<string, unknown>) {
        this.filter = next;
      },
      getOptions() {
        return {};
      },
    };
    await tenantStorage.run({ tenantId: 'tenant-a' }, () =>
      runPre(value, 'find', query),
    );
    expect(query.filter).toEqual({ title: 'hello', tenantId: 'tenant-a' });
  });

  it('refuses queries without a tenant context', async () => {
    const value = schema();
    const query = {
      getQuery: () => ({}),
      setQuery: () => undefined,
      getOptions: () => ({}),
    };
    await expect(runPre(value, 'find', query)).rejects.toThrow(
      'TENANT_CONTEXT_MISSING',
    );
  });

  it('refuses an attempt to query a different tenant', async () => {
    const value = schema();
    const query = {
      getQuery: () => ({ tenantId: 'tenant-b' }),
      setQuery: () => undefined,
      getOptions: () => ({}),
    };
    await expect(
      tenantStorage.run({ tenantId: 'tenant-a' }, () =>
        runPre(value, 'findOne', query),
      ),
    ).rejects.toThrow('TENANT_SCOPE_VIOLATION');
  });

  it('places tenant match first in aggregations', async () => {
    const value = schema();
    const pipeline = [{ $sort: { createdAt: -1 } }];
    await tenantStorage.run({ tenantId: 'tenant-a' }, () =>
      runPre(value, 'aggregate', { pipeline: () => pipeline }),
    );
    expect(pipeline[0]).toEqual({ $match: { tenantId: 'tenant-a' } });
  });
});
