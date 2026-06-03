import { Controller, Get, Req } from '@nestjs/common';
import { Request } from 'express';

@Controller('csrf')
export class CsrfController {
  @Get('token')
  token(@Req() request: Request & { csrfToken?: () => string }) {
    return {
      message: 'Token CSRF gerado.',
      csrfToken: request.csrfToken?.(),
    };
  }
}
