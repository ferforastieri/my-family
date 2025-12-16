import { Injectable, Inject } from '@nestjs/common';
import { DATABASE_CONNECTION } from '@shared/infrastructure/database/database.module';
import { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { cartasDeAmor, NewCartaDeAmor } from '@shared/infrastructure/database/schema';
import { eq, desc } from 'drizzle-orm';

@Injectable()
export class CartasService {
  constructor(
    @Inject(DATABASE_CONNECTION)
    private db: NodePgDatabase<typeof import('@shared/infrastructure/database/schema')>,
  ) {}

  async findAll() {
    return this.db.select().from(cartasDeAmor).orderBy(desc(cartasDeAmor.data));
  }

  async findOne(id: number) {
    return this.db.select().from(cartasDeAmor).where(eq(cartasDeAmor.id, id)).limit(1);
  }

  async create(data: NewCartaDeAmor) {
    const [carta] = await this.db.insert(cartasDeAmor).values(data).returning();
    return carta;
  }

  async update(id: number, data: Partial<NewCartaDeAmor>) {
    const [carta] = await this.db
      .update(cartasDeAmor)
      .set({ ...data, updatedAt: new Date() })
      .where(eq(cartasDeAmor.id, id))
      .returning();
    return carta;
  }

  async delete(id: number) {
    await this.db.delete(cartasDeAmor).where(eq(cartasDeAmor.id, id));
  }
}

