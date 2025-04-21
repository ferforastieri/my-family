import styled, { keyframes } from 'styled-components';
import { useEffect, useState } from 'react';
import { supabase } from '../services/supabase';
import { NovaMusicaModal } from '../components/NovaMusicaModal';
import { SpotifyPlayer } from '../components/SpotifyPlayer';
import { YouTubePlayer } from '../components/YouTubePlayer';

const floatAnimation = keyframes`
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-10px); }
`;

const glowAnimation = keyframes`
  0%, 100% { text-shadow: 2px 2px 4px rgba(255, 105, 180, 0.3); }
  50% { text-shadow: 2px 2px 12px rgba(255, 105, 180, 0.6); }
`;

const PlaylistContainer = styled.div`
  min-height: 100vh;
  padding: 80px 2rem 2rem;
  background: linear-gradient(180deg, #fff8fa 0%, #fff0f5 100%);
`;

const HeaderSection = styled.header`
  padding: 1rem;
  text-align: center;
  position: relative;
  border-radius: 20px;
  margin: 1rem auto 2rem;
  max-width: 1000px;
`;

const Title = styled.h1`
  color: #ff69b4;
  font-size: 3.5rem;
  font-family: 'Pacifico', cursive;
  margin: 0.5rem 0 1rem;
  padding-top: 0.5rem;
  animation: ${floatAnimation} 3s ease-in-out infinite,
             ${glowAnimation} 2s ease-in-out infinite;
  
  span {
    display: inline-block;
    
    &:hover {
      transform: scale(1.1);
      transition: transform 0.3s ease;
    }
  }

  @media (max-width: 768px) {
    font-size: 2.5rem;
  }
`;

const Subtitle = styled.p`
  color: #d4488e;
  font-size: 1.4rem;
  max-width: 800px;
  margin: 0 auto 2rem;
  line-height: 1.6;
  font-family: 'Dancing Script', cursive;

  @media (max-width: 768px) {
    font-size: 1.2rem;
    padding: 0 1rem;
  }
`;

const AddButton = styled.button`
  background: #ff69b4;
  color: white;
  border: none;
  padding: 0.8rem 2rem;
  border-radius: 25px;
  font-size: 1.1rem;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin: 0 auto 2rem;
  transition: all 0.3s ease;
  box-shadow: 0 2px 10px rgba(255, 105, 180, 0.3);
  font-family: 'Dancing Script', cursive;
  
  &:hover {
    background: #ff1493;
    transform: translateY(-2px);
    box-shadow: 0 4px 15px rgba(255, 105, 180, 0.4);
  }
`;

const MusicGrid = styled.div`
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 2rem;
  max-width: 1200px;
  margin: 0 auto;
`;

const MusicCard = styled.div`
  background: white;
  border-radius: 15px;
  padding: 2rem;
  box-shadow: 0 4px 15px rgba(255, 105, 180, 0.1);
  transition: transform 0.3s ease;
  
  &:hover {
    transform: translateY(-5px);
  }

  h3 {
    color: #ff69b4;
    font-size: 1.4rem;
    margin-bottom: 0.5rem;
    font-family: 'Dancing Script', cursive;
  }

  .artista {
    color: #666;
    font-size: 1rem;
    margin-bottom: 1rem;
  }

  .momento {
    color: #ff69b4;
    font-size: 0.9rem;
    margin-bottom: 1rem;
    font-style: italic;
  }

  .descricao {
    color: #444;
    font-size: 1rem;
    line-height: 1.6;
    margin-bottom: 1rem;
  }

  .player-container {
    margin-top: 1rem;
    border-top: 1px solid #f0f0f0;
    padding-top: 1rem;
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }
`;

const FilterSection = styled.div`
  margin: 0 auto 2rem;
  max-width: 1200px;
  display: flex;
  justify-content: center;
  gap: 1rem;
  flex-wrap: wrap;
`;

const FilterButton = styled.button<{ active: boolean }>`
  padding: 0.6rem 1.2rem;
  border-radius: 20px;
  border: 2px solid #ff69b4;
  background: ${props => props.active ? '#ff69b4' : 'transparent'};
  color: ${props => props.active ? 'white' : '#ff69b4'};
  font-family: 'Dancing Script', cursive;
  font-size: 1rem;
  cursor: pointer;
  transition: all 0.3s ease;
  
  &:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 10px rgba(255, 105, 180, 0.2);
  }
`;

interface Musica {
  id: number;
  titulo: string;
  artista: string;
  link_spotify: string;
  descricao: string;
  momento: string;
  data: string;
}

const momentos = [
  'Todos',
  'Primeiro Encontro',
  'Primeiro Beijo',
  'Pedido de Namoro',
  'Noivado',
  'Casamento',
  'Lua de Mel',
  'Momentos Especiais',
  'Outros'
];

const Playlist = () => {
  const [musicas, setMusicas] = useState<Musica[]>([]);
  const [modalAberto, setModalAberto] = useState(false);
  const [filtroMomento, setFiltroMomento] = useState('Todos');

  useEffect(() => {
    carregarMusicas();
  }, []);

  const carregarMusicas = async () => {
    try {
      const { data, error } = await supabase
        .from('musicas_especiais')
        .select('*')
        .order('data', { ascending: false });

      if (error) throw error;
      console.log('Dados carregados do Supabase:', data);
      setMusicas(data || []);
    } catch (error) {
      console.error('Erro ao carregar músicas:', error);
    }
  };

  const salvarMusica = async (musica: {
    titulo: string;
    artista: string;
    link_spotify: string;
    descricao: string;
    momento: string;
  }) => {
    try {
      const { error } = await supabase
        .from('musicas_especiais')
        .insert([
          {
            ...musica,
            data: new Date().toISOString(),
          }
        ]);

      if (error) throw error;
      
      await carregarMusicas();
    } catch (error) {
      console.error('Erro ao salvar música:', error);
    }
  };

  const musicasFiltradas = musicas.filter(musica => 
    filtroMomento === 'Todos' || musica.momento === filtroMomento
  );
  console.log('Músicas filtradas:', musicasFiltradas);

  return (
    <PlaylistContainer>
      <HeaderSection>
        <Title>
          {'Playlist do Nosso Amor'.split('').map((letter, index) => (
            <span key={index} style={{ animationDelay: `${index * 0.1}s` }}>
              {letter === ' ' ? '\u00A0' : letter}
            </span>
          ))}
        </Title>
        <Subtitle>
          Cada música conta uma história nossa. Uma melodia que nos faz sorrir, 
          dançar e reviver momentos especiais do nosso amor.
        </Subtitle>
        <AddButton onClick={() => setModalAberto(true)}>
          <span>+</span> Adicionar Nova Música
        </AddButton>
      </HeaderSection>

      <FilterSection>
        {momentos.map(momento => (
          <FilterButton
            key={momento}
            active={filtroMomento === momento}
            onClick={() => setFiltroMomento(momento)}
          >
            {momento}
          </FilterButton>
        ))}
      </FilterSection>

      <MusicGrid>
        {musicasFiltradas.map((musica) => (
          <MusicCard key={musica.id}>
            <h3>{musica.titulo}</h3>
            <div className="artista">{musica.artista}</div>
            <div className="momento">{musica.momento}</div>
            <div className="descricao">{musica.descricao}</div>
            <div className="player-container">
              {musica.link_spotify && (
                musica.link_spotify.includes('youtube.com') || musica.link_spotify.includes('youtu.be') ? (
                  <YouTubePlayer youtubeUrl={musica.link_spotify} />
                ) : musica.link_spotify.includes('spotify.com') ? (
                  <SpotifyPlayer spotifyUrl={musica.link_spotify} />
                ) : null
              )}
            </div>
          </MusicCard>
        ))}
      </MusicGrid>

      <NovaMusicaModal
        isOpen={modalAberto}
        onClose={() => setModalAberto(false)}
        onSave={salvarMusica}
      />
    </PlaylistContainer>
  );
};

export default Playlist; 