export function toId(value: unknown): string {
  return String((value as { _id?: unknown })?._id ?? value);
}

export function cleanUndefined<T extends Record<string, unknown>>(value: T): Partial<T> {
  return Object.fromEntries(Object.entries(value).filter(([, v]) => v !== undefined)) as Partial<T>;
}
