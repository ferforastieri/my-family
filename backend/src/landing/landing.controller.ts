import { Controller, Get, Query } from '@nestjs/common';
import { Public } from '@auth/decorators/public.decorator';
import { LandingService } from './landing.service';

@Controller('public/landing')
@Public()
export class LandingController {
  constructor(private readonly landing: LandingService) {}

  @Get()
  index(@Query('locale') locale?: string) {
    return this.landing.landing(locale);
  }

  @Get('privacy-policy')
  privacyPolicy(@Query('locale') locale?: string) {
    return this.landing.privacyPolicy(locale);
  }
}
