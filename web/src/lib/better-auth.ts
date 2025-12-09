import { createAuthClient } from 'better-auth/client';
import { config } from '../config/env';

export const authClient = createAuthClient({
  baseURL: config.betterAuthUrl,
});

export const { 
  signIn, 
  signOut, 
  signUp, 
  $fetch 
} = authClient;

export type { Session } from 'better-auth/types';

