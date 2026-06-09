import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  UserDocument,
  UserMongoDocument,
} from '@shared/infrastructure/database/schemas';
import {
  cleanUndefined,
  normalizePagination,
  paginated,
  PaginationQuery,
  toId,
} from '@shared/infrastructure/database/mongo.utils';
import {
  normalizeAccessKeys,
  type UserAccessKey,
  type UserEntity,
  type UserRole,
} from '@auth/domain/entities/user.entity';

export type CreateUserData = {
  email: string;
  passwordHash: string;
  name?: string;
  role?: UserRole;
  access?: UserAccessKey[];
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
      email: doc.email,
      passwordHash: doc.passwordHash ?? null,
      name: doc.name ?? null,
      role: doc.role,
      access: normalizeAccessKeys(doc.access),
      avatarPath: doc.avatarPath ?? null,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
    };
  }

  async list(query?: PaginationQuery) {
    const { page, limit, skip } = normalizePagination(query, {
      page: 1,
      limit: 20,
      maxLimit: 100,
    });
    const [docs, total] = await Promise.all([
      this.model.find().sort({ createdAt: -1 }).skip(skip).limit(limit).exec(),
      this.model.countDocuments().exec(),
    ]);
    return paginated(
      docs.map((doc) => this.toEntity(doc)!),
      total,
      page,
      limit,
    );
  }

  async findById(id: string): Promise<UserEntity | null> {
    return this.toEntity(await this.model.findById(id).exec());
  }

  async findByEmail(email: string): Promise<UserEntity | null> {
    return this.toEntity(
      await this.model.findOne({ email: email.toLowerCase() }).exec(),
    );
  }

  async create(data: CreateUserData): Promise<UserEntity> {
    const doc = await this.model.create(data);
    return this.toEntity(doc)!;
  }

  async update(
    id: string,
    data: {
      name?: string;
      role?: UserRole;
      access?: UserAccessKey[];
      avatarPath?: string;
      passwordHash?: string;
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
