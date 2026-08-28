import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  PhoneChallengeDocument,
  PhoneChallengeMongoDocument,
} from '@shared/infrastructure/database/schemas';

@Injectable()
export class PhoneChallengeRepository {
  constructor(
    @InjectModel(PhoneChallengeDocument.name)
    private model: Model<PhoneChallengeMongoDocument>,
  ) {}

  async replace(data: {
    phoneNumber: string;
    codeHash: string;
    channel: 'whatsapp' | 'sms';
    expiresAt: Date;
  }) {
    await this.model.deleteMany({ phoneNumber: data.phoneNumber }).exec();
    return this.model.create({ ...data, attempts: 0 });
  }

  findActive(phoneNumber: string) {
    return this.model
      .findOne({
        phoneNumber,
        consumedAt: { $exists: false },
        expiresAt: { $gt: new Date() },
        attempts: { $lt: 5 },
      })
      .sort({ createdAt: -1 })
      .exec();
  }

  registerFailure(id: string) {
    return this.model.updateOne({ _id: id }, { $inc: { attempts: 1 } }).exec();
  }

  consume(id: string) {
    return this.model
      .updateOne(
        { _id: id, consumedAt: { $exists: false } },
        { $set: { consumedAt: new Date() } },
      )
      .exec();
  }
}
