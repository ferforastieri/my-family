import { badRequest } from './http';

export function normalizeEmail(value: string): string {
  const email = value?.trim().toLowerCase() ?? '';
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || email.length > 200) {
    throw badRequest('Informe um email válido.');
  }
  return email;
}
