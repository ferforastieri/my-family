import { Injectable, Inject } from '@nestjs/common';
import { DATABASE_CONNECTION } from '@shared/infrastructure/database/database.module';
import { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { musicasEspeciais, NewMusicaEspecial } from '@shared/infrastructure/database/schema';
import { eq, desc } from 'drizzle-orm';

@Injectable()
export class MusicasService {
  constructor(
    @Inject(DATABASE_CONNECTION)
    private db: NodePgDatabase<typeof import('@shared/infrastructure/database/schema')>,
  ) {}

  async findAll() {
    return this.db.select().from(musicasEspeciais).orderBy(desc(musicasEspeciais.data));
  }

  async findOne(id: number) {
    return this.db.select().from(musicasEspeciais).where(eq(musicasEspeciais.id, id)).limit(1);
  }

  async create(data: NewMusicaEspecial) {
    const [musica] = await this.db.insert(musicasEspeciais).values(data).returning();
    return musica;
  }

  async update(id: number, data: Partial<NewMusicaEspecial>) {
    const [musica] = await this.db
      .update(musicasEspeciais)
      .set({ ...data, updatedAt: new Date() })
      .where(eq(musicasEspeciais.id, id))
      .returning();
    return musica;
  }

  async delete(id: number) {
    await this.db.delete(musicasEspeciais).where(eq(musicasEspeciais.id, id));
  }
}

