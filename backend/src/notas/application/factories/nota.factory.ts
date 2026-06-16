import type { Factory } from '@shared/application/mapper';
import type { NotaWrite } from '../../infrastructure/repositories/notas.repository';
import { NotaWriteDto } from '../../interfaces/dto/nota.dto';

export class NotaFactory implements Factory<
  Partial<NotaWriteDto>,
  Partial<NotaWrite>
> {
  create(input: Partial<NotaWriteDto>): Partial<NotaWrite> {
    return {
      titulo: input.titulo?.trim(),
      conteudo: input.conteudo?.trim(),
      data: input.data ? new Date(input.data) : undefined,
    };
  }
}

export const notaFactory = new NotaFactory();
