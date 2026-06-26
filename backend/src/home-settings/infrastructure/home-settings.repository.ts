import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  HomeSettingsDocument,
  HomeSettingsMongoDocument,
} from './persistence/home-settings.schema';

export type HomeEventWrite = {
  title: string;
  icon: string;
  date: Date;
  message: string;
  countDirection?: 'forward' | 'backward';
  hidden?: boolean;
};

export type HomeSettingsWrite = {
  events: HomeEventWrite[];
  galleryImages?: string[];
  galleryOrder?: number;
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

  async save(settings: HomeSettingsWrite) {
    return this.model
      .findOneAndUpdate(
        { key: 'home' },
        { $set: settings },
        { upsert: true, new: true, setDefaultsOnInsert: true },
      )
      .lean()
      .exec();
  }
}
