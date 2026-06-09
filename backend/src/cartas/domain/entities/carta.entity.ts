export interface CartaEntity {
  id: string;
  tipo: 'letter' | 'journey';
  titulo: string;
  conteudo: string;
  data: Date;
  createdAt: Date;
  updatedAt: Date;
}
