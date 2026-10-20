import { HTTPException } from 'hono/http-exception';

export type ErrorCode =
  | 'unauthenticated'
  | 'forbidden'
  | 'two_factor_required'
  | 'not_found'
  | 'conflict'
  | 'validation_failed'
  | 'bad_origin';

const STATUS: Record<ErrorCode, 400 | 401 | 403 | 404 | 409 | 422> = {
  unauthenticated: 401,
  forbidden: 403,
  two_factor_required: 403,
  not_found: 404,
  conflict: 409,
  validation_failed: 422,
  bad_origin: 403,
};

export class ApiError extends HTTPException {
  constructor(
    readonly code: ErrorCode,
    message: string = code,
    readonly details?: unknown,
  ) {
    super(STATUS[code], { message });
  }
}

/** Postgres error codes we translate into API errors. */
export function mapDbError(err: unknown): ApiError | null {
  const code = (err as { code?: string } | null)?.code ?? (err as { cause?: { code?: string } })?.cause?.code;
  if (code === '23503') return new ApiError('conflict', 'Referenced by other records or references a missing record');
  if (code === '23505') return new ApiError('conflict', 'Already exists');
  return null;
}
