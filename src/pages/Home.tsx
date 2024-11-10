import styled, { keyframes } from 'styled-components';
import FlowerGarden from '../components/common/FlowerGarden';
import { useNavigate } from 'react-router-dom';

const floatAnimation = keyframes`
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-10px); }
`;

const glowAnimation = keyframes`
  0%, 100% { text-shadow: 2px 2px 4px rgba(255, 105, 180, 0.3); }
  50% { text-shadow: 2px 2px 12px rgba(255, 105, 180, 0.6); }
`;

const HomeContainer = styled.div`
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  position: relative;
  background: linear-gradient(180deg, #fff8fa 0%, #fff0f5 100%);
  width: 100%;
  overflow-x: hidden;
`;

const ContentSection = styled.section`
  padding: 10px 2rem 0;
  text-align: center;
  position: relative;
  width: 100%;
  margin: 0 auto;
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
`;

const Heart = styled.span`
  color: #ff1493;
  display: inline-block;
  margin: 0 0.5rem;
  animation: ${floatAnimation} 2s ease-in-out infinite;
`;

const Subtitle = styled.p`
  color: #d4488e;
  font-size: 1.4rem;
  max-width: 800px;
  margin: 0 auto 2rem;
  line-height: 1.6;
  font-family: 'Dancing Script', cursive;
`;

const CardGrid = styled.div`
  display: flex;
  flex-direction: row;
  flex-wrap: wrap;
  gap: 1rem;
  padding: 1.5rem;
  width: 100%;
  max-width: 1400px;
  margin: 0 auto;
  position: relative;
  justify-content: center;
  align-items: center;
`;

const Card = styled.div`
  background: rgba(255, 255, 255, 0.9);
  padding: 1.5rem;
  border-radius: 15px;
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
  transition: transform 0.3s ease;
  backdrop-filter: blur(5px);
  cursor: pointer;
  height: 180px;
  width: 250px;
  flex: 0 0 250px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  
  &:hover {
    transform: translateY(-5px);
    background: rgba(255, 255, 255, 0.95);
  }
  
  h3 {
    color: #ff69b4;
    margin-bottom: 0.8rem;
    position: relative;
    z-index: 2;
    font-size: 1.2rem;
    text-align: center;
  }
  
  p {
    color: #666;
    position: relative;
    z-index: 2;
    font-size: 0.9rem;
    text-align: center;
    max-width: 90%;
    margin: 0 auto;
    line-height: 1.4;
  }
`;

const FlowerSection = styled.div`
  position: relative;
  height: 60vh;
  margin-top: -2rem;
`;

const Home = () => {
  const navigate = useNavigate();

  const handleCardClick = (path: string) => {
    navigate(path);
  };

  return (
    <HomeContainer>
      <ContentSection>
        <HeaderSection>
          <Title>
            {'Para Meu Amor'.split('').map((letter, index) => (
              <span key={index} style={{ animationDelay: `${index * 0.1}s` }}>
                {letter === ' ' ? '\u00A0' : letter}
              </span>
            ))}
            <Heart>❤️</Heart>
          </Title>
          <Subtitle>
            Um jardim digital de memórias e amor, onde cada flor representa 
            um momento especial da nossa história juntos.
          </Subtitle>
        </HeaderSection>
        
        <CardGrid>
          <Card>
            <h3>Nossa História</h3>
            <p>Descubra como tudo começou e os momentos que nos trouxeram até aqui.</p>
          </Card>
          <Card onClick={() => handleCardClick('/quiz-do-amor')}>
            <h3>Quiz do Amor ❤️</h3>
            <p>Teste seus conhecimentos sobre nossa história de amor em um jogo divertido!</p>
          </Card>
          <Card onClick={() => handleCardClick('/mensagens')}>
            <h3>Mensagens do Coração</h3>
            <p>Palavras de amor e carinho que compartilhamos.</p>
          </Card>
          <Card onClick={() => handleCardClick('/carta-de-amor')}>
            <h3>Carta de Amor</h3>
            <p>Uma declaração especial do meu coração para você.</p>
          </Card>
          <Card onClick={() => handleCardClick('/flor-para-esposa')}>
            <h3>Uma Flor para Minha Esposa</h3>
            <p>Um jardim especial dedicado à mulher da minha vida 🌹</p>
          </Card>
        </CardGrid>
      </ContentSection>
      <FlowerSection>
        <FlowerGarden />
      </FlowerSection>
    </HomeContainer>
  );
};

export default Home;