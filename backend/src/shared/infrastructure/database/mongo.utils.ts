export function toId(value: unknown): string {
  return String((value as { _id?: unknown })?._id ?? value);
}

export function cleanUndefined<T extends Record<string, unknown>>(
  value: T,
): Partial<T> {
  return Object.fromEntries(
    Object.entries(value).filter(([, v]) => v !== undefined),
  ) as Partial<T>;
}

export type PaginationQuery = {
  page?: number | string;
  limit?: number | string;
  titlePrefix?: string;
  album?: string;
};

export type PaginatedResult<T> = {
  items: T[];
  page: number;
  limit: number;
  total: number;
  pages: number;
};

export function normalizePagination(
  query?: PaginationQuery,
  defaults = { page: 1, limit: 24, maxLimit: 100 },
) {
  const page = Math.max(
    1,
    Number(query?.page ?? defaults.page) || defaults.page,
  );
  const rawLimit = Math.max(
    1,
    Number(query?.limit ?? defaults.limit) || defaults.limit,
  );
  const limit = Math.min(rawLimit, defaults.maxLimit);
  return { page, limit, skip: (page - 1) * limit };
}

export function paginated<T>(
  items: T[],
  total: number,
  page: number,
  limit: number,
): PaginatedResult<T> {
  return {
    items,
    page,
    limit,
    total,
    pages: Math.max(1, Math.ceil(total / limit)),
  };
}
