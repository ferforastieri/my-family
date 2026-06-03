export type ApiResponse<T = unknown> = {
  ok: boolean;
  message: string;
  data: T;
  meta?: Record<string, unknown>;
  timestamp: string;
};

export type ApiMessage = {
  message?: string;
};

export function isApiResponse(value: unknown): value is ApiResponse {
  return (
    typeof value === 'object' &&
    value !== null &&
    'ok' in value &&
    'message' in value &&
    'data' in value
  );
}
