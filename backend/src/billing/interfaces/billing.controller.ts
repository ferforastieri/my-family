import {
  Controller,
  Get,
  Headers,
  Post,
  RawBodyRequest,
  Req,
} from '@nestjs/common';
import type { Request } from 'express';
import { Public } from '@auth/decorators/public.decorator';
import { BillingService } from '../application/billing.service';

@Controller('billing')
export class BillingController {
  constructor(private billing: BillingService) {}

  @Get('status')
  status() {
    return this.billing.status();
  }

  @Post('checkout')
  checkout(
    @Req() request: Request & { user: { email: string; role: string } },
  ) {
    return this.billing.createCheckout(request.user);
  }

  @Post('portal')
  portal(@Req() request: Request & { user: { role: string } }) {
    return this.billing.createPortal(request.user);
  }

  @Post('webhook')
  @Public()
  webhook(
    @Req() request: RawBodyRequest<Request>,
    @Headers('stripe-signature') signature?: string,
  ) {
    return this.billing.handleWebhook(
      request.rawBody ?? Buffer.alloc(0),
      signature,
    );
  }
}
