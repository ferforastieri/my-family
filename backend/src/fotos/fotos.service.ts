import { Injectable, Inject } from '@nestjs/common';
import { DATABASE_CONNECTION } from '@shared/infrastructure/database/database.module';
import { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { fotos, NewFoto } from '@shared/infrastructure/database/schema';
import { eq } from 'drizzle-orm';

@Injectable()
export class FotosService {
  constructor(
    @Inject(DATABASE_CONNECTION)
    private db: NodePgDatabase<typeof import('@shared/infrastructure/database/schema')>,
  ) {}

  async findAll() {
    return this.db.select().from(fotos).orderBy(fotos.createdAt);
  }

  async findOne(id: string) {
    return this.db.select().from(fotos).where(eq(fotos.id, id)).limit(1);
  }

  async create(data: NewFoto) {
    const [foto] = await this.db.insert(fotos).values(data).returning();
    return foto;
  }

  async update(id: string, data: Partial<NewFoto>) {
    const [foto] = await this.db
      .update(fotos)
      .set({ ...data, updatedAt: new Date() })
      .where(eq(fotos.id, id))
      .returning();
    return foto;
  }

  async delete(id: string) {
    await this.db.delete(fotos).where(eq(fotos.id, id));
  }
}

