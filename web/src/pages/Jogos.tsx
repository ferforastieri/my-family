import styled from 'styled-components';
import { useNavigate } from 'react-router-dom';

const JogosContainer = styled.div`
  width: 100%;
  min-height: 100vh;
  background: linear-gradient(180deg, #fff8fa 0%, #fff0f5 100%);
  padding: 2rem;
`;

const Title = styled.h1`
  color: #ff69b4;
  font-size: 2.5rem;
  font-family: 'Pacifico', cursive;
  text-align: center;
  margin-bottom: 2rem;
`;

const GamesGrid = styled.div`
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 2rem;
  max-width: 1200px;
  margin: 0 auto;
  padding: 1rem;
`;

const GameCard = styled.div`
  background: white;
  border-radius: 15px;
  padding: 1.5rem;
  box-shadow: 0 4px 15px rgba(255, 105, 180, 0.2);
  cursor: pointer;
  transition: transform 0.3s ease;

  &:hover {
    transform: translateY(-5px);
  }

  h3 {
    color: #ff69b4;
    font-size: 1.5rem;
    margin-bottom: 1rem;
    text-align: center;
  }

  p {
    color: #666;
    text-align: center;
  }
`;

const Jogos = () => {
  const navigate = useNavigate();

  return (
    <JogosContainer>
      <Title>Jogos do Amor</Title>
      <GamesGrid>
        <GameCard onClick={() => navigate('/quiz-do-amor')}>
          <h3>Quiz do Amor ❤️</h3>
          <p>Teste seus conhecimentos sobre nossa história de amor!</p>
        </GameCard>
        <GameCard onClick={() => navigate('/caca-palavras')}>
          <h3>Caça Palavras 🔍</h3>
          <p>Encontre palavras românticas que mudam todos os dias!</p>
        </GameCard>
      </GamesGrid>
    </JogosContainer>
  );
};

export default Jogos; 