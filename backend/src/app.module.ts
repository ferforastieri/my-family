import { Module } from '@nestjs/common';
import { EnvironmentModule } from '@shared/infrastructure/environment/environment.module';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { AuthModule } from '@auth/auth.module';
import { FotosModule } from '@fotos/fotos.module';
import { MusicasModule } from '@musicas/musicas.module';
import { CartasModule } from '@cartas/cartas.module';

@Module({
  imports: [
    EnvironmentModule.forRoot(),
    DatabaseModule,
    AuthModule,
    FotosModule,
    MusicasModule,
    CartasModule,
  ],
})
export class AppModule {}
