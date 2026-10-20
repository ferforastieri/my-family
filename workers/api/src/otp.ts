import { constantTimeEqual } from './auth';

const encoder = new TextEncoder();

export async function hmacHex(secret: string, value: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = await crypto.subtle.sign('HMAC', key, encoder.encode(value));
  return [...new Uint8Array(signature)]
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');
}

export function hashOtp(secret: string, phoneNumber: string, code: string): Promise<string> {
  return hmacHex(secret, `${phoneNumber}:${code}`);
}

export function verifyOtpHash(expected: string, received: string): boolean {
  return constantTimeEqual(expected, received);
}

export function randomOtp(): string {
  const value = crypto.getRandomValues(new Uint32Array(1))[0] % 900000;
  return String(100000 + value);
}

export function isOtp(value: string): boolean {
  return /^\d{6}$/.test(value);
}
