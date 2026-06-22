import {
  Controller,
  Get,
  Headers,
  Post,
  RawBodyRequest,
  Req,
  UseGuards,
} from '@nestjs/common';
import type { Request } from 'express';
import { JwtAuthGuard } from '@auth/guards/jwt-auth.guard';
import { BillingService } from '../application/billing.service';

@Controller('billing')
export class BillingController {
  constructor(private billing: BillingService) {}

  @Get('status')
  @UseGuards(JwtAuthGuard)
  status() {
    return this.billing.status();
  }

  @Post('checkout')
  @UseGuards(JwtAuthGuard)
  checkout(@Req() request: Request & { user: { email: string; role: string } }) {
    return this.billing.createCheckout(request.user);
  }

  @Post('portal')
  @UseGuards(JwtAuthGuard)
  portal(@Req() request: Request & { user: { role: string } }) {
    return this.billing.createPortal(request.user);
  }

  @Post('webhook')
  webhook(
    @Req() request: RawBodyRequest<Request>,
    @Headers('stripe-signature') signature?: string,
  ) {
    return this.billing.handleWebhook(request.rawBody ?? Buffer.alloc(0), signature);
  }
}

