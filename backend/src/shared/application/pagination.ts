export type PaginationQuery = {
  page?: number | string;
  limit?: number | string;
  album?: string;
};

export type PaginatedResult<T> = {
  items: T[];
  page: number;
  limit: number;
  total: number;
  pages: number;
};
