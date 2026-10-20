export type SqlValue = string | number | null;

export function toSql(value: unknown): SqlValue {
  if (value === undefined || value === null) return null;
  if (typeof value === 'boolean') return value ? 1 : 0;
  if (value instanceof Date) return value.getTime();
  return value as SqlValue;
}

export function statement(db: D1Database, sql: string, params: unknown[] = []) {
  return db.prepare(sql).bind(...params.map(toSql));
}

export async function queryAll<T>(
  db: D1Database,
  sql: string,
  params: unknown[] = [],
): Promise<T[]> {
  const result = await statement(db, sql, params).all<T>();
  return result.results ?? [];
}

export async function queryOne<T>(
  db: D1Database,
  sql: string,
  params: unknown[] = [],
): Promise<T | null> {
  return (await statement(db, sql, params).first<T>()) ?? null;
}

export async function execute(
  db: D1Database,
  sql: string,
  params: unknown[] = [],
): Promise<D1Result> {
  return statement(db, sql, params).run();
}

export function jsonArray(value: unknown): string[] {
  if (Array.isArray(value)) return value.filter((item): item is string => typeof item === 'string');
  if (typeof value !== 'string' || !value) return [];
  try {
    const parsed = JSON.parse(value);
    return Array.isArray(parsed)
      ? parsed.filter((item): item is string => typeof item === 'string')
      : [];
  } catch {
    return [];
  }
}

export function jsonValue<T>(value: unknown, fallback: T): T {
  if (typeof value !== 'string' || !value) return fallback;
  try {
    return JSON.parse(value) as T;
  } catch {
    return fallback;
  }
}

export function iso(value: unknown): string | null {
  if (value === null || value === undefined) return null;
  if (typeof value === 'number') return new Date(value).toISOString();
  const date = new Date(String(value));
  return Number.isNaN(date.getTime()) ? null : date.toISOString();
}

export function now(): number {
  return Date.now();
}

export function placeholders(count: number): string {
  return Array.from({ length: count }, () => '?').join(',');
}
