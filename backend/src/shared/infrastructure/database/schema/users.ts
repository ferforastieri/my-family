import { pgTable, text, timestamp, serial } from 'drizzle-orm/pg-core';

export const userRoles = ['admin', 'wife', 'child', 'friend'] as const;
export type UserRole = (typeof userRoles)[number];

export const users = pgTable('users', {
  id: serial('id').primaryKey(),
  email: text('email').notNull().unique(),
  passwordHash: text('password_hash'),
  name: text('name'),
  role: text('role').notNull().default('friend').$type<UserRole>(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

export type User = typeof users.$inferSelect;
export type NewUser = typeof users.$inferInsert;
