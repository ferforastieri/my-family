import { Injectable, Inject } from '@nestjs/common';
import { DATABASE_CONNECTION } from '@shared/infrastructure/database/database.module';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import type * as schema from '@shared/infrastructure/database/schema';
import { users, UserRole } from '@shared/infrastructure/database/schema';
import { eq, desc } from 'drizzle-orm';

export type UserDto = {
  id: number;
  email: string;
  name: string | null;
  role: UserRole;
  avatarPath: string | null;
  createdAt: Date;
};

@Injectable()
export class UserService {
  constructor(
    @Inject(DATABASE_CONNECTION)
    private db: NodePgDatabase<typeof schema>,
  ) {}

  async list(): Promise<UserDto[]> {
    const rows = await this.db
      .select({
        id: users.id,
        email: users.email,
        name: users.name,
        role: users.role,
        avatarPath: users.avatarPath,
        createdAt: users.createdAt,
      })
      .from(users)
      .orderBy(desc(users.createdAt));
    return rows;
  }

  async findOne(id: number): Promise<UserDto | null> {
    const [row] = await this.db
      .select({
        id: users.id,
        email: users.email,
        name: users.name,
        role: users.role,
        avatarPath: users.avatarPath,
        createdAt: users.createdAt,
      })
      .from(users)
      .where(eq(users.id, id))
      .limit(1);
    return row ?? null;
  }

  async update(id: number, data: { name?: string; role?: UserRole }): Promise<UserDto | null> {
    const set: Record<string, unknown> = { updatedAt: new Date() };
    if (data.name !== undefined) set.name = data.name;
    if (data.role !== undefined) set.role = data.role;
    const [updated] = await this.db
      .update(users)
      .set(set as any)
      .where(eq(users.id, id))
      .returning({
        id: users.id,
        email: users.email,
        name: users.name,
        role: users.role,
        avatarPath: users.avatarPath,
        createdAt: users.createdAt,
      });
    return updated ?? null;
  }

  async delete(id: number): Promise<boolean> {
    const result = await this.db.delete(users).where(eq(users.id, id));
    return (result.rowCount ?? 0) > 0;
  }
}
