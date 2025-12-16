import { pgTable, text, timestamp, uuid } from 'drizzle-orm/pg-core';

export const fotos = pgTable('fotos', {
  id: uuid('id').defaultRandom().primaryKey(),
  url: text('url').notNull(),
  texto: text('texto'),
  tipo: text('tipo').notNull().$type<'imagem' | 'video'>(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

export type Foto = typeof fotos.$inferSelect;
export type NewFoto = typeof fotos.$inferInsert;


