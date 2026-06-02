import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { mongoModels } from './schemas';

@Module({
  imports: [MongooseModule.forFeature(mongoModels)],
  exports: [MongooseModule],
})
export class MongoModelsModule {}
