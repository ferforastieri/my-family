import {
  Body,
  Controller,
  Get,
  Headers,
  Post,
  RawBodyRequest,
  Req,
} from '@nestjs/common';
import { IsIn, IsOptional } from 'class-validator';
import type { Request } from 'express';
import { Public } from '@auth/decorators/public.decorator';
import { BillingService } from '../application/billing.service';
import type { UserEntity } from '@auth/domain/entities/user.entity';
import { subscriptionPlanIntervals } from '../infrastructure/persistence/subscription-plan.schema';

class CheckoutDto {
  @IsOptional()
  @IsIn(subscriptionPlanIntervals)
  planInterval?: (typeof subscriptionPlanIntervals)[number];
}

@Controller('billing')
export class BillingController {
  constructor(private billing: BillingService) {}

  @Get('plans')
  @Public()
  async plans() {
    return { plans: await this.billing.listPlans() };
  }

  @Get('status')
  status() {
    return this.billing.status();
  }

  @Post('checkout')
  checkout(
    @Req() request: Request & { user: UserEntity },
    @Body() body: CheckoutDto = {},
  ) {
    return this.billing.createCheckout(request.user, body.planInterval);
  }

  @Post('portal')
  portal(@Req() request: Request & { user: UserEntity }) {
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
