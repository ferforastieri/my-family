import { Global, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { Environment } from '@shared/infrastructure/environment/environment.module';
import { EnvironmentModule } from '@shared/infrastructure/environment/environment.module';
import { TenantContextService } from './tenant-context';

const MongoDatabaseModule = MongooseModule.forRootAsync({
  imports: [EnvironmentModule],
  inject: [Environment],
  useFactory: (env: Environment) => ({
    uri: env.database.mongo.uri,
    dbName: env.database.mongo.dbName,
  }),
});

@Global()
@Module({
  imports: [MongoDatabaseModule],
  providers: [TenantContextService],
  exports: [MongoDatabaseModule, TenantContextService],
})
export class DatabaseModule {}
