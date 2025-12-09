import styled, { keyframes } from 'styled-components';
import { useEffect, useState } from 'react';
import { supabase } from '../services/supabase';
import { NovaCartaModal } from '../components/NovaCartaModal';

const floatAnimation = keyframes`
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-10px); }
`;

const glowAnimation = keyframes`
  0%, 100% { text-shadow: 2px 2px 4px rgba(255, 105, 180, 0.3); }
  50% { text-shadow: 2px 2px 12px rgba(255, 105, 180, 0.6); }
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

const LetterContainer = styled.div`
  min-height: 100vh;
  padding: 80px 2rem 2rem;
  background: linear-gradient(180deg, #fff8fa 0%, #fff0f5 100%);
`;

const LettersGrid = styled.div`
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 2rem;
  max-width: 1200px;
  margin: 0 auto;
`;

const Letter = styled.div`
  background: white;
  border-radius: 15px;
  padding: 2rem;
  box-shadow: 0 4px 20px rgba(255, 105, 180, 0.2);
  width: 90%;
  max-width: 800px;
  position: relative;
  margin: 0 auto;
`;

const ModalOverlay = styled.div`
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
  padding: 2rem;
  
  ${Letter} {
    margin: 0;
    max-height: 90vh;
    overflow-y: auto;
  }
`;

const LetterCard = styled.div`
  background: rgba(255, 255, 255, 0.95);
  padding: 2rem;
  border-radius: 15px;
  box-shadow: 0 2px 10px rgba(255, 105, 180, 0.15);
  cursor: pointer;
  transition: transform 0.2s;
  
  &:hover {
    transform: translateY(-5px);
  }
  
  .date {
    color: #ff69b4;
    font-size: 0.9rem;
    margin-bottom: 1rem;
  }
  
  .preview {
    font-family: 'Dancing Script', cursive;
    font-size: 1.1rem;
    color: #666;
    display: -webkit-box;
    -webkit-line-clamp: 3;
    -webkit-box-orient: vertical;
    overflow: hidden;
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

  span {
    font-size: 1.4rem;
    line-height: 1;
  }
`;

const Content = styled.div`
  font-family: 'Dancing Script', cursive;
  font-size: 1.2rem;
  line-height: 1.6;
  color: #333;

  p {
    margin-bottom: 1rem;
  }
`;

const CartaDetalhada = styled(Content)`
  h2 {
    color: #ff69b4;
    margin-bottom: 1rem;
    font-size: 2rem;
  }

  .date {
    color: #ff69b4;
    font-size: 0.9rem;
    margin-bottom: 2rem;
  }

  .content {
    white-space: pre-wrap;
  }
`;

interface CartaDeAmor {
  id: number;
  conteudo: string;
  data: string;
  titulo: string;
}

const LoveLetter = () => {
  const [cartas, setCartas] = useState<CartaDeAmor[]>([]);
  const [modalAberto, setModalAberto] = useState(false);
  const [cartaSelecionada, setCartaSelecionada] = useState<CartaDeAmor | null>(null);

  useEffect(() => {
    carregarCartas();
  }, []);

  const carregarCartas = async () => {
    try {
      const { data, error } = await supabase
        .from('cartas_de_amor')
        .select('*')
        .order('data', { ascending: false });

      if (error) throw error;
      setCartas(data || []);
    } catch (error) {
      console.error('Erro ao carregar cartas:', error);
    }
  };

  const salvarNovaCarta = async (carta: { titulo: string; conteudo: string }) => {
    try {
      const { error } = await supabase
        .from('cartas_de_amor')
        .insert([
          {
            titulo: carta.titulo,
            conteudo: carta.conteudo,
            data: new Date().toISOString(),
          }
        ]);

      if (error) throw error;
      
      await carregarCartas(); // Recarrega todas as cartas
    } catch (error) {
      console.error('Erro ao salvar carta:', error);
    }
  };

  return (
    <LetterContainer>
      <HeaderSection>
        <Title>
          {'Cartas de Amor'.split('').map((letter, index) => (
            <span key={index} style={{ animationDelay: `${index * 0.1}s` }}>
              {letter === ' ' ? '\u00A0' : letter}
            </span>
          ))}
        </Title>
        <Subtitle>
          Um espaço especial onde guardo todas as minhas declarações de amor para você.
          Cada carta é um pedacinho do meu coração transformado em palavras.
        </Subtitle>
        <AddButton onClick={() => setModalAberto(true)}>
          <span>+</span> Escrever Nova Carta
        </AddButton>
      </HeaderSection>

      <LettersGrid>
        {cartas.map((carta) => (
          <LetterCard 
            key={carta.id}
            onClick={() => setCartaSelecionada(carta)}
          >
            <div className="date">
              {new Date(carta.data).toLocaleDateString('pt-BR')}
            </div>
            <h3>{carta.titulo}</h3>
            <div className="preview">{carta.conteudo}</div>
          </LetterCard>
        ))}
      </LettersGrid>

      <NovaCartaModal
        isOpen={modalAberto}
        onClose={() => setModalAberto(false)}
        onSave={salvarNovaCarta}
      />

      {cartaSelecionada && (
        <ModalOverlay onClick={() => setCartaSelecionada(null)}>
          <Letter onClick={e => e.stopPropagation()}>
            <CartaDetalhada>
              <h2>{cartaSelecionada.titulo}</h2>
              <div className="date">
                {new Date(cartaSelecionada.data).toLocaleDateString('pt-BR')}
              </div>
              <div className="content">
                {cartaSelecionada.conteudo.split('\n').map((paragraph, i) => (
                  <p key={i}>{paragraph}</p>
                ))}
              </div>
            </CartaDetalhada>
          </Letter>
        </ModalOverlay>
      )}
    </LetterContainer>
  );
};

export default LoveLetter; 