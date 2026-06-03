export interface MusicaEntity {
  id: string;
  titulo: string;
  artista: string;
  linkSpotify: string;
  descricao?: string | null;
  momento: string;
  data: Date;
  createdAt: Date;
  updatedAt: Date;
}
