import 'reflect-metadata';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { CartaUpdateMessageDto } from './carta.dto';

describe('CartaUpdateMessageDto', () => {
  it('validates nested update data at runtime', async () => {
    const dto = plainToInstance(CartaUpdateMessageDto, {
      id: 'carta-id',
      data: { titulo: 42, unknown: true },
    });
    const errors = await validate(dto, {
      whitelist: true,
      forbidNonWhitelisted: true,
    });

    expect(errors).toHaveLength(1);
    expect(errors[0].property).toBe('data');
    expect(errors[0].children).not.toHaveLength(0);
  });
});
