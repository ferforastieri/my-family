import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { PasswordResetDocument, PasswordResetMongoDocument } from '@shared/infrastructure/database/schemas';
import { toId } from '@shared/infrastructure/database/mongo.utils';
import type { PasswordResetEntity } from '@shared/domain/entities';

@Injectable()
export class PasswordResetRepository {
  constructor(@InjectModel(PasswordResetDocument.name) private model: Model<PasswordResetMongoDocument>) {}

  private toEntity(doc: PasswordResetMongoDocument | null): PasswordResetEntity | null {
    if (!doc) return null;
    return {
      id: toId(doc),
      userId: toId(doc.userId),
      token: doc.token,
      expiresAt: doc.expiresAt,
      used: doc.used ?? null,
      createdAt: doc.createdAt,
    };
  }

  async create(data: { userId: string; token: string; expiresAt: Date }): Promise<PasswordResetEntity> {
    return this.toEntity(await this.model.create(data))!;
  }

  async findByToken(token: string): Promise<PasswordResetEntity | null> {
    return this.toEntity(await this.model.findOne({ token }).exec());
  }

  async markUsed(id: string): Promise<void> {
    await this.model.findByIdAndUpdate(id, { $set: { used: new Date() } }).exec();
  }
}
