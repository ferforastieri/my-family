import styled, { keyframes } from 'styled-components';
import FlowerGarden from '../components/common/FlowerGarden';
import { useNavigate } from 'react-router-dom';
import { useState, useEffect } from 'react';

const floatAnimation = keyframes`
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-10px); }
`;

const glowAnimation = keyframes`
  0%, 100% { text-shadow: 2px 2px 4px rgba(255, 105, 180, 0.3); }
  50% { text-shadow: 2px 2px 12px rgba(255, 105, 180, 0.6); }
`;

const HomeContainer = styled.div.attrs(() => ({
  style: {
    width: '100%',
    minHeight: '100vh',
    position: 'relative',
    display: 'flex',
    flexDirection: 'column',
    background: 'linear-gradient(180deg, #fff8fa 0%, #fff0f5 100%)'
  },
}))``;

const ContentSection = styled.section`
  padding: 10px 2rem 0;
  text-align: center;
  position: relative;
  width: 100%;
  margin: 0 auto;
  
  @media (max-width: 768px) {
    padding: 10px 16px 0;
  }
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

  @media (max-width: 768px) {
    font-size: 1.2rem;
    padding: 0 1rem;
  }
`;

const CardGrid = styled.div.attrs(() => ({
  style: {
    display: 'flex',
    flexDirection: 'row',
    flexWrap: 'wrap',
    width: '100%',
    position: 'relative',
    justifyContent: 'center',
    alignItems: 'center',
    gap: '1rem',
    padding: '1rem',
    maxWidth: '1400px',
    margin: '0 auto',
  },
}))`
  @media (max-width: 768px) {
    gap: 0.8rem;
    padding: 0.8rem;
  }
`;

const Card = styled.div.attrs(() => ({
  style: {
    display: 'flex',
    flexDirection: 'column',
    justifyContent: 'center',
    alignItems: 'center',
    position: 'relative',
    background: 'rgba(255, 255, 255, 0.9)',
    padding: '1.5rem',
    borderRadius: '15px',
    boxShadow: '0 4px 15px rgba(0, 0, 0, 0.1)',
    backdropFilter: 'blur(5px)',
    cursor: 'pointer',
    height: '180px',
    width: '250px',
    flex: '0 0 250px',
  },
}))`
  transition: transform 0.3s ease;

  @media (max-width: 768px) {
    width: 100%;
    flex: 0 0 100%;
    height: 150px;
    padding: 1rem;
  }
  
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
  
  @media (max-width: 768px) {
    height: 40vh;
    margin-top: 1rem;
  }
`;

const CountdownCard = styled.div`
  background: linear-gradient(135deg, #ff69b4 0%, #d4488e 100%);
  border-radius: 20px;
  padding: 2rem;
  box-shadow: 0 8px 20px rgba(212, 72, 142, 0.3);
  margin: 2rem auto;
  max-width: 800px;
  text-align: center;
  transform: translateY(0);
  transition: transform 0.3s ease;
  
  &:hover {
    transform: translateY(-5px);
  }

  @media (max-width: 768px) {
    margin: 1.5rem 1rem;
    padding: 1.5rem;
  }
`;

const CountdownTitle = styled.h3`
  color: white;
  font-size: 1.8rem;
  margin-bottom: 1rem;
  font-family: 'Pacifico', cursive;
  text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.2);

  @media (max-width: 768px) {
    font-size: 1.5rem;
  }
`;

const CountdownGrid = styled.div`
  display: grid;
  grid-template-columns: repeat(6, 1fr);
  gap: 1rem;
  margin-top: 1rem;

  @media (max-width: 768px) {
    grid-template-columns: repeat(3, 1fr);
    gap: 0.8rem;
  }
`;

const TimeUnit = styled.div`
  background: rgba(255, 255, 255, 0.9);
  border-radius: 12px;
  padding: 0.8rem;
  
  .number {
    font-size: 1.8rem;
    font-weight: bold;
    color: #ff69b4;
    margin-bottom: 0.3rem;
  }
  
  .label {
    font-size: 0.9rem;
    color: #d4488e;
    font-family: 'Dancing Script', cursive;
  }

  @media (max-width: 768px) {
    padding: 0.6rem;
    
    .number {
      font-size: 1.4rem;
    }
    
    .label {
      font-size: 0.8rem;
    }
  }
`;

const Home = () => {
  const navigate = useNavigate();
  const [timeElapsed, setTimeElapsed] = useState({
    years: 0,
    months: 0,
    days: 0,
    hours: 0,
    minutes: 0,
    seconds: 0
  });

  useEffect(() => {
    const startDate = new Date('2024-10-15'); // Substitua pela data do início do namoro
    
    const updateCounter = () => {
      const now = new Date();
      const diff = now.getTime() - startDate.getTime();
      
      const seconds = Math.floor(diff / 1000);
      const minutes = Math.floor(seconds / 60);
      const hours = Math.floor(minutes / 60);
      const totalDays = Math.floor(hours / 24);
      const years = Math.floor(totalDays / 365);
      const months = Math.floor((totalDays % 365) / 30.44);
      const days = Math.floor(totalDays % 30.44); // Dias restantes após meses completos

      setTimeElapsed({
        years,
        months,
        days,
        hours: hours % 24,
        minutes: minutes % 60,
        seconds: seconds % 60
      });
    };

    const timer = setInterval(updateCounter, 1000);
    return () => clearInterval(timer);
  }, []);

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
          <CountdownCard>
            <CountdownTitle>Nosso Amor em Números</CountdownTitle>
            <CountdownGrid>
              <TimeUnit>
                <div className="number">{timeElapsed.years}</div>
                <div className="label">Anos</div>
              </TimeUnit>
              <TimeUnit>
                <div className="number">{timeElapsed.months}</div>
                <div className="label">Meses</div>
              </TimeUnit>
              <TimeUnit>
                <div className="number">{timeElapsed.days}</div>
                <div className="label">Dias</div>
              </TimeUnit>
              <TimeUnit>
                <div className="number">{timeElapsed.hours}</div>
                <div className="label">Horas</div>
              </TimeUnit>
              <TimeUnit>
                <div className="number">{timeElapsed.minutes}</div>
                <div className="label">Minutos</div>
              </TimeUnit>
              <TimeUnit>
                <div className="number">{timeElapsed.seconds}</div>
                <div className="label">Segundos</div>
              </TimeUnit>
            </CountdownGrid>
          </CountdownCard>
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