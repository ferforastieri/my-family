import type { Factory } from '@shared/application/mapper';
import type { MusicaWrite } from '../infrastructure/repositories/musicas.repository';
import { MusicaWriteDto } from '../interfaces/dto/musica.dto';

export class MusicaFactory implements Factory<
  Partial<MusicaWriteDto>,
  Partial<MusicaWrite>
> {
  create(input: Partial<MusicaWriteDto>): Partial<MusicaWrite> {
    return {
      titulo: input.titulo?.trim(),
      artista: input.artista?.trim(),
      linkSpotify: input.linkSpotify?.trim(),
      momento: input.momento?.trim(),
      descricao: input.descricao?.trim(),
      data: input.data ? new Date(input.data) : undefined,
    };
  }
}

export const musicaFactory = new MusicaFactory();
