import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  UserDocument,
  UserMongoDocument,
} from '@shared/infrastructure/database/schemas';
import {
  cleanUndefined,
  toId,
} from '@shared/infrastructure/database/mongo.utils';
import {
  normalizeAccessKeys,
  type UserAccessKey,
  type UserEntity,
  type UserRole,
} from '@auth/domain/entities/user.entity';

export type CreateUserData = {
  phoneNumber: string;
  name?: string;
  role?: UserRole;
  access?: UserAccessKey[];
  platformRole?: 'super_admin';
};

@Injectable()
export class UserRepository {
  constructor(
    @InjectModel(UserDocument.name) private model: Model<UserMongoDocument>,
  ) {}

  toEntity(doc: UserMongoDocument | null): UserEntity | null {
    if (!doc) return null;
    return {
      id: toId(doc),
      phoneNumber: doc.phoneNumber,
      name: doc.name ?? null,
      role: doc.role,
      access: normalizeAccessKeys(doc.access),
      avatarPath: doc.avatarPath ?? null,
      platformRole: doc.platformRole ?? null,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
    };
  }

  async findById(id: string): Promise<UserEntity | null> {
    return this.toEntity(await this.model.findById(id).exec());
  }

  async findByPhoneNumber(phoneNumber: string): Promise<UserEntity | null> {
    return this.toEntity(await this.model.findOne({ phoneNumber }).exec());
  }

  async create(data: CreateUserData): Promise<UserEntity> {
    const doc = await this.model.create(data);
    return this.toEntity(doc);
  }

  async update(
    id: string,
    data: {
      name?: string;
      role?: UserRole;
      access?: UserAccessKey[];
      avatarPath?: string;
      platformRole?: 'super_admin';
    },
  ): Promise<UserEntity | null> {
    const doc = await this.model
      .findByIdAndUpdate(id, { $set: cleanUndefined(data) }, { new: true })
      .exec();
    return this.toEntity(doc);
  }

  async delete(id: string): Promise<boolean> {
    const result = await this.model.findByIdAndDelete(id).exec();
    return !!result;
  }
}
