import { pgTable, text, timestamp, serial } from 'drizzle-orm/pg-core';

export const cartasDeAmor = pgTable('cartas_de_amor', {
  id: serial('id').primaryKey(),
  titulo: text('titulo').notNull(),
  conteudo: text('conteudo').notNull(),
  data: timestamp('data').defaultNow().notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

export type CartaDeAmor = typeof cartasDeAmor.$inferSelect;
export type NewCartaDeAmor = typeof cartasDeAmor.$inferInsert;


