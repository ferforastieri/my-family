import type { Factory } from '@shared/application/mapper';
import type { FotoWrite } from '../infrastructure/repositories/fotos.repository';
import { FotoWriteDto } from '../interfaces/dto/foto.dto';

export class FotoFactory implements Factory<
  Partial<FotoWriteDto>,
  Partial<FotoWrite>
> {
  create(input: Partial<FotoWriteDto>): Partial<FotoWrite> {
    return {
      url: input.url?.trim(),
      tipo: input.tipo,
      texto: input.texto?.trim(),
      album: input.album?.trim(),
      data: input.data ? new Date(input.data) : undefined,
    };
  }
}

export const fotoFactory = new FotoFactory();
