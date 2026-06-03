export interface FotoEntity {
  id: string;
  url: string;
  texto?: string | null;
  album?: string | null;
  tipo: 'imagem' | 'video';
  data?: Date | null;
  createdAt: Date;
  updatedAt: Date;
}
