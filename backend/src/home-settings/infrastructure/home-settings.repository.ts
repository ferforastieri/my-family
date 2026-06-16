import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  HomeSettingsDocument,
  HomeSettingsMongoDocument,
} from '@shared/infrastructure/database/schemas';

export type HomeEventWrite = {
  title: string;
  icon: string;
  date: Date;
  message: string;
  countDirection?: 'forward' | 'backward';
};

@Injectable()
export class HomeSettingsRepository {
  constructor(
    @InjectModel(HomeSettingsDocument.name)
    private model: Model<HomeSettingsMongoDocument>,
  ) {}

  async find() {
    return this.model.findOne({ key: 'home' }).lean().exec();
  }

  async save(events: HomeEventWrite[]) {
    return this.model
      .findOneAndUpdate(
        { key: 'home' },
        { $set: { events } },
        { upsert: true, new: true, setDefaultsOnInsert: true },
      )
      .lean()
      .exec();
  }
}
