import { z } from 'zod';

const envSchema = z.object({
  VITE_API_URL: z.union([z.string().url(), z.string().regex(/^\/.*/)]),
});

const raw = import.meta.env.VITE_API_URL ?? 'http://localhost:3000/api';
const env = envSchema.parse({ VITE_API_URL: raw });

export const apiUrl = env.VITE_API_URL.startsWith('/')
  ? (typeof window !== 'undefined' ? window.location.origin + env.VITE_API_URL : env.VITE_API_URL)
  : env.VITE_API_URL;
