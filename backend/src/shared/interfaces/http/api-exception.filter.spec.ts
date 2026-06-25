import { HttpStatus, Logger } from '@nestjs/common';
import type { ArgumentsHost } from '@nestjs/common';
import { ApiExceptionFilter } from './api-exception.filter';

describe('ApiExceptionFilter', () => {
  beforeEach(() => {
    jest.spyOn(Logger.prototype, 'error').mockImplementation(() => undefined);
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  function httpHost() {
    const response = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn(),
    };
    const host = {
      getType: () => 'http',
      switchToHttp: () => ({ getResponse: () => response }),
    } as unknown as ArgumentsHost;
    return { host, response };
  }

  it('does not expose unexpected error messages', () => {
    const { host, response } = httpHost();
    new ApiExceptionFilter().catch(
      new Error('mongodb://user:secret@internal/database'),
      host,
    );

    expect(response.status).toHaveBeenCalledWith(
      HttpStatus.INTERNAL_SERVER_ERROR,
    );
    expect(response.json).toHaveBeenCalledWith(
      expect.objectContaining({
        message: 'Erro interno no servidor.',
        error: 'InternalServerError',
      }),
    );
  });

  it('maps duplicate key errors without exposing index details', () => {
    const { host, response } = httpHost();
    const error = Object.assign(new Error('E11000 secret index details'), {
      code: 11000,
    });
    new ApiExceptionFilter().catch(error, host);

    expect(response.status).toHaveBeenCalledWith(HttpStatus.CONFLICT);
    expect(response.json).toHaveBeenCalledWith(
      expect.objectContaining({ message: 'Registro duplicado.' }),
    );
  });
});
