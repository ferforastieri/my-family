import { pgTable, text, timestamp, serial } from 'drizzle-orm/pg-core';

export const notifications = pgTable('notifications', {
  id: serial('id').primaryKey(),
  title: text('title').notNull(),
  body: text('body').notNull().default(''),
  url: text('url').notNull().default('/'),
  icon: text('icon'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

export type NotificationRow = typeof notifications.$inferSelect;
export type NewNotificationRow = typeof notifications.$inferInsert;
