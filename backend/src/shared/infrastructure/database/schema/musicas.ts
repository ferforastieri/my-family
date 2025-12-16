import { pgTable, text, timestamp, serial } from 'drizzle-orm/pg-core';

export const musicasEspeciais = pgTable('musicas_especiais', {
  id: serial('id').primaryKey(),
  titulo: text('titulo').notNull(),
  artista: text('artista').notNull(),
  linkSpotify: text('link_spotify').notNull(),
  descricao: text('descricao'),
  momento: text('momento').notNull(),
  data: timestamp('data').defaultNow().notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

export type MusicaEspecial = typeof musicasEspeciais.$inferSelect;
export type NewMusicaEspecial = typeof musicasEspeciais.$inferInsert;

