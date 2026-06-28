import {
  Body,
  BadRequestException,
  Controller,
  Get,
  Param,
  Patch,
  ParseIntPipe,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  IsBoolean,
  IsDateString,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';
import { PlatformAdminGuard } from './platform-admin.guard';
import { PlatformAdminService } from './platform-admin.service';
import {
  SubscriptionPlanInterval,
  subscriptionPlanIntervals,
} from '../billing/infrastructure/persistence/subscription-plan.schema';
import {
  LandingLocale,
  LegalDocumentFormat,
  landingLocales,
  legalDocumentFormats,
} from '../landing/persistence/legal-document.schema';

class UpdateSubscriptionPlanDto {
  @IsOptional()
  @IsString()
  @MinLength(2)
  @MaxLength(80)
  name?: string;

  @IsOptional()
  @IsString()
  @MinLength(2)
  @MaxLength(300)
  description?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(99999900)
  priceCents?: number;

  @IsOptional()
  @IsString()
  @MinLength(3)
  @MaxLength(3)
  currency?: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  stripePriceId?: string | null;

  @IsOptional()
  @IsBoolean()
  active?: boolean;

  @IsOptional()
  @IsBoolean()
  highlighted?: boolean;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(9999)
  sortOrder?: number;
}

class UpdatePrivacyPolicyDto {
  @IsString()
  @MinLength(2)
  @MaxLength(160)
  title: string;

  @IsString()
  @MinLength(20)
  body: string;

  @IsOptional()
  @IsIn(legalDocumentFormats)
  format?: LegalDocumentFormat;

  @IsOptional()
  @IsBoolean()
  published?: boolean;

  @IsOptional()
  @IsDateString()
  effectiveDate?: string | null;
}

@Controller('platform/admin')
@UseGuards(PlatformAdminGuard)
export class PlatformAdminController {
  constructor(private readonly platform: PlatformAdminService) {}

  @Get('overview')
  overview() {
    return this.platform.overview();
  }

  @Get('audit')
  audit(
    @Query('page', new ParseIntPipe({ optional: true })) page = 1,
    @Query('limit', new ParseIntPipe({ optional: true })) limit = 30,
  ) {
    return this.platform.auditLogs(page, limit);
  }

  @Get('plans')
  async plans() {
    return { plans: await this.platform.listPlans() };
  }

  @Patch('plans/:interval')
  updatePlan(
    @Param('interval') interval: SubscriptionPlanInterval,
    @Body() body: UpdateSubscriptionPlanDto,
  ) {
    if (!subscriptionPlanIntervals.includes(interval)) {
      throw new BadRequestException('Tipo de assinatura inválido.');
    }
    return this.platform.updatePlan(interval, body);
  }

  @Get('legal/privacy-policy')
  privacyPolicies() {
    return this.platform.privacyPolicies();
  }

  @Get('legal/privacy-policy/:locale')
  privacyPolicy(@Param('locale') locale: LandingLocale) {
    if (!landingLocales.includes(locale)) {
      throw new BadRequestException('Locale inválido.');
    }
    return this.platform.privacyPolicy(locale);
  }

  @Patch('legal/privacy-policy/:locale')
  updatePrivacyPolicy(
    @Param('locale') locale: LandingLocale,
    @Body() body: UpdatePrivacyPolicyDto,
  ) {
    if (!landingLocales.includes(locale)) {
      throw new BadRequestException('Locale inválido.');
    }
    return this.platform.updatePrivacyPolicy(locale, body);
  }
}
