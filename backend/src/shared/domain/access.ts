export const userAccessKeys = [
  'memorias',
  'playlist',
  'cartas',
  'jogos',
  'listas',
  'notas',
  'localizacao',
  'chat',
  'nossaHistoria',
] as const;

export type UserAccessKey = (typeof userAccessKeys)[number];
