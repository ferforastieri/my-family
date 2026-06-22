import { Controller, Get, Req } from '@nestjs/common';
import { Public } from '@auth/decorators/public.decorator';
import { Request } from 'express';

@Controller('csrf')
@Public()
export class CsrfController {
  @Get('token')
  token(@Req() request: Request & { csrfToken?: () => string }) {
    return {
      message: 'Token CSRF gerado.',
      csrfToken: request.csrfToken?.(),
    };
  }
}
