import { Test, TestingModule } from '@nestjs/testing';
import { HealthController } from './interfaces/controllers/health.controller';
import { getConnectionToken } from '@nestjs/mongoose';
import { Environment } from '@shared/infrastructure/environment/environment.module';

describe('HealthController', () => {
  let controller: HealthController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [HealthController],
      providers: [
        {
          provide: getConnectionToken(),
          useValue: {
            db: { admin: () => ({ ping: async () => ({ ok: 1 }) }) },
          },
        },
        { provide: Environment, useValue: { redis: undefined } },
      ],
    }).compile();

    controller = module.get<HealthController>(HealthController);
  });

  it('returns ok status', () => {
    expect(controller.check()).toEqual({ ok: true });
  });
});
