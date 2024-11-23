import { useState, useEffect } from 'react';
import styled from 'styled-components';
import UploadFoto from '../components/common/UploadFoto';
import { supabase } from '../services/supabase';

interface Foto {
  id: string;
  url: string;
  texto: string;
  tipo: 'imagem' | 'video';
  created_at: string;
}

const GaleriaContainer = styled.div`
  padding: 2rem;
  background: linear-gradient(180deg, #fff8fa 0%, #fff0f5 100%);
  min-height: 100vh;
`;

const FotosGrid = styled.div`
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
  gap: 1.5rem;
  margin-top: 2rem;
`;

const FotoCard = styled.div`
  background: white;
  border-radius: 10px;
  overflow: hidden;
  box-shadow: 0 4px 15px rgba(255, 105, 180, 0.1);
  transition: transform 0.2s ease;

  &:hover {
    transform: translateY(-5px);
  }

  img, video {
    width: 100%;
    height: 200px;
    object-fit: cover;
  }

  .texto {
    padding: 1rem;
    color: #666;
  }
`;

const TextArea = styled.textarea`
  width: 100%;
  padding: 0.5rem;
  border: 1px solid #ffb6c1;
  border-radius: 4px;
  margin-top: 0.5rem;
  resize: vertical;
  min-height: 60px;
  font-family: inherit;

  &:focus {
    outline: none;
    border-color: #ff69b4;
  }
`;

const Galeria = () => {
  const [fotos, setFotos] = useState<Foto[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    carregarFotos();
  }, []);

  const carregarFotos = async () => {
    try {
      const { data, error } = await supabase
        .from('fotos')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      setFotos(data || []);
    } catch (error) {
      console.error('Erro ao carregar fotos:', error);
      alert('Erro ao carregar as fotos');
    } finally {
      setLoading(false);
    }
  };

  const handleNovaFoto = async (url: string) => {
    try {
      const novaFoto = {
        url,
        texto: '',
        tipo: url.includes('video') ? 'video' : 'imagem'
      };

      const { error } = await supabase
        .from('fotos')
        .insert([novaFoto]);

      if (error) throw error;
      carregarFotos();
    } catch (error) {
      console.error('Erro ao salvar foto:', error);
      alert('Erro ao salvar a foto');
    }
  };

  const handleTextoChange = async (id: string, novoTexto: string) => {
    try {
      const { error } = await supabase
        .from('fotos')
        .update({ texto: novoTexto })
        .eq('id', id);

      if (error) throw error;
      setFotos(fotos.map(foto => 
        foto.id === id ? { ...foto, texto: novoTexto } : foto
      ));
    } catch (error) {
      console.error('Erro ao atualizar texto:', error);
      alert('Erro ao salvar o texto');
    }
  };

  return (
    <GaleriaContainer>
      <h1>Nossa Galeria de Memórias</h1>
      <UploadFoto onUploadComplete={handleNovaFoto} />
      
      {loading ? (
        <p>Carregando...</p>
      ) : (
        <FotosGrid>
          {fotos.map(foto => (
            <FotoCard key={foto.id}>
              {foto.tipo === 'video' ? (
                <video controls>
                  <source src={foto.url} type="video/mp4" />
                  Seu navegador não suporta vídeos.
                </video>
              ) : (
                <img src={foto.url} alt="" />
              )}
              <div className="texto">
                <TextArea
                  value={foto.texto || ''}
                  onChange={(e) => handleTextoChange(foto.id, e.target.value)}
                  placeholder="Adicione uma descrição..."
                />
              </div>
            </FotoCard>
          ))}
        </FotosGrid>
      )}
    </GaleriaContainer>
  );
};

export default Galeria; 