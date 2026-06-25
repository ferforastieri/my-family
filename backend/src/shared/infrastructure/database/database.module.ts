import { Global, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { Environment } from '@shared/infrastructure/environment/environment.module';
import { EnvironmentModule } from '@shared/infrastructure/environment/environment.module';
import { TenantIndexesMigration } from './tenant-indexes.migration';

export const DATABASE_CONNECTION = 'DATABASE_CONNECTION';

export const MongoDatabaseModule = MongooseModule.forRootAsync({
  imports: [EnvironmentModule],
  inject: [Environment],
  useFactory: (env: Environment) => ({
    uri: env.database.mongo.uri,
  }),
});

@Global()
@Module({
  imports: [MongoDatabaseModule],
  providers: [TenantIndexesMigration],
  exports: [MongoDatabaseModule],
})
export class DatabaseModule {}
