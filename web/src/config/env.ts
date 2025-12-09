import { z } from 'zod';

const envSchema = z.object({
  VITE_API_URL: z.string().url(),
  VITE_BETTER_AUTH_URL: z.string().url(),
});

const env = envSchema.parse({
  VITE_API_URL: import.meta.env.VITE_API_URL || 'http://localhost:3000/api',
  VITE_BETTER_AUTH_URL: import.meta.env.VITE_BETTER_AUTH_URL || 'http://localhost:3000/api/auth',
});

export const config = {
  apiUrl: env.VITE_API_URL,
  betterAuthUrl: env.VITE_BETTER_AUTH_URL,
};
