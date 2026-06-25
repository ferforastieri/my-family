import { Injectable, Logger, OnApplicationBootstrap } from '@nestjs/common';
import { InjectConnection } from '@nestjs/mongoose';
import type { Connection } from 'mongoose';

type IndexMigration = {
  collection: string;
  obsoleteName: string;
  keys: Record<string, 1 | -1>;
  name: string;
};

const migrations: IndexMigration[] = [
  {
    collection: 'game_words',
    obsoleteName: 'word_1',
    keys: { tenantId: 1, word: 1 },
    name: 'tenantId_1_word_1',
  },
  {
    collection: 'mini_game_configs',
    obsoleteName: 'type_1',
    keys: { tenantId: 1, type: 1 },
    name: 'tenantId_1_type_1',
  },
];

@Injectable()
export class TenantIndexesMigration implements OnApplicationBootstrap {
  private readonly logger = new Logger(TenantIndexesMigration.name);

  constructor(@InjectConnection() private readonly connection: Connection) {}

  async onApplicationBootstrap(): Promise<void> {
    const existingCollections = new Set(
      (await this.connection.db.listCollections().toArray()).map(
        (collection) => collection.name,
      ),
    );

    for (const migration of migrations) {
      if (!existingCollections.has(migration.collection)) continue;
      const collection = this.connection.db.collection(migration.collection);
      const indexes = await collection.indexes();
      if (indexes.some((index) => index.name === migration.obsoleteName)) {
        await collection.dropIndex(migration.obsoleteName);
        this.logger.log(
          `Índice global removido: ${migration.collection}.${migration.obsoleteName}`,
        );
      }
      await collection.createIndex(migration.keys, {
        name: migration.name,
        unique: true,
      });
    }
  }
}
