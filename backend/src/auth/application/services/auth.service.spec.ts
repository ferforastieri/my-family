import { BadRequestException } from '@nestjs/common';
import { Environment } from '@shared/infrastructure/environment/environment.module';
import { createHmac } from 'node:crypto';
import { AuthService } from './auth.service';

describe('AuthService phone authentication', () => {
  const challenges = {
    replace: jest.fn().mockResolvedValue(null),
  };
  const messaging = {
    isConfigured: jest.fn().mockReturnValue(false),
    sendOtp: jest.fn(),
  };
  const environment = new Environment({
    type: 'development',
    jwt: { secret: 'jwt-test-secret', expiresIn: '15m' },
    phoneAuth: {
      hashSecret: 'test-secret',
      defaultCountryCode: '55',
    },
  });
  const service = new AuthService(
    {} as never,
    challenges as never,
    {} as never,
    environment,
    messaging as never,
    {} as never,
    {} as never,
  );

  beforeEach(() => jest.clearAllMocks());

  it('normalizes a Brazilian mobile number to E.164', () => {
    expect(service.normalizePhoneNumber('(11) 99999-9999')).toBe(
      '+5511999999999',
    );
  });

  it('keeps an international E.164 number', () => {
    expect(service.normalizePhoneNumber('+351 912 345 678')).toBe(
      '+351912345678',
    );
  });

  it('rejects an invalid phone number', () => {
    expect(() => service.normalizePhoneNumber('123')).toThrow(
      BadRequestException,
    );
  });

  it('returns a development code without leaking it in production flows', async () => {
    const result = await service.requestCode('(11) 99999-9999', 'whatsapp');
    expect(result.devCode).toMatch(/^\d{6}$/);
    expect(result.expiresIn).toBe(300);
    expect(challenges.replace).toHaveBeenCalledWith(
      expect.objectContaining({
        phoneNumber: '+5511999999999',
        channel: 'whatsapp',
      }),
    );
  });

  it('creates the account and a default family using only phone and code', async () => {
    const phoneNumber = '+5511999999999';
    const code = '123456';
    const users = {
      findByPhoneNumber: jest.fn().mockResolvedValue(null),
      create: jest.fn().mockResolvedValue({
        id: 'user-1',
        phoneNumber,
        role: 'friends',
        access: [],
      }),
      delete: jest.fn(),
    };
    const challengeRepository = {
      findActive: jest.fn().mockResolvedValue({
        _id: 'challenge-1',
        codeHash: createHmac('sha256', 'test-secret')
          .update(`${phoneNumber}:${code}`)
          .digest('hex'),
      }),
      consume: jest.fn().mockResolvedValue({ modifiedCount: 1 }),
      registerFailure: jest.fn(),
    };
    const tenancy = {
      createFamily: jest.fn().mockResolvedValue({
        id: 'tenant-1',
        name: 'Minha Família',
        slug: 'familia-generated',
      }),
      membershipsForUser: jest.fn().mockResolvedValue([{ id: 'tenant-1' }]),
      principal: jest.fn().mockResolvedValue({
        id: 'user-1',
        phoneNumber,
        tenant: { id: 'tenant-1', slug: 'familia-generated' },
      }),
    };
    const tenancyRepository = { createSession: jest.fn() };
    const auth = new AuthService(
      users as never,
      challengeRepository as never,
      { sign: jest.fn().mockReturnValue('access-token') } as never,
      environment,
      messaging as never,
      tenancy as never,
      tenancyRepository as never,
    );

    const response = await auth.authenticateWithCode({
      phone: phoneNumber,
      code,
    });

    expect(users.create).toHaveBeenCalledWith(
      expect.objectContaining({ phoneNumber }),
    );
    expect(tenancy.createFamily).toHaveBeenCalledWith(
      'user-1',
      'Minha Família',
      expect.stringMatching(/^familia-[a-f0-9]{10}$/),
    );
    expect(response).toEqual(
      expect.objectContaining({ accessToken: 'access-token' }),
    );
  });
});
