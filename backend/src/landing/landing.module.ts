import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { BillingModule } from '../billing/billing.module';
import { LandingController } from './landing.controller';
import { LandingService } from './landing.service';
import {
  LegalDocument,
  LegalDocumentSchema,
} from './persistence/legal-document.schema';

@Module({
  imports: [
    BillingModule,
    MongooseModule.forFeature([
      { name: LegalDocument.name, schema: LegalDocumentSchema },
    ]),
  ],
  controllers: [LandingController],
  providers: [LandingService],
  exports: [LandingService],
})
export class LandingModule {}
