import styled from 'styled-components';
import { useState } from 'react';

const QuizContainer = styled.div`
  min-height: 100vh;
  background: linear-gradient(180deg, #fff8fa 0%, #fff0f5 100%);
  padding: 2rem;
`;

const Title = styled.h1`
  color: #ff69b4;
  font-size: 2.5rem;
  text-align: center;
  font-family: 'Pacifico', cursive;
  margin-bottom: 2rem;
`;

const QuestionCard = styled.div`
  background: rgba(255, 255, 255, 0.9);
  padding: 2rem;
  border-radius: 15px;
  max-width: 600px;
  margin: 0 auto;
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
`;

const Question = styled.h2`
  color: #d4488e;
  font-size: 1.3rem;
  margin-bottom: 1.5rem;
`;

const OptionButton = styled.button`
  width: 100%;
  padding: 1rem;
  margin: 0.5rem 0;
  border: 2px solid #ff69b4;
  border-radius: 8px;
  background: white;
  color: #ff69b4;
  cursor: pointer;
  transition: all 0.3s ease;

  &:hover {
    background: #ff69b4;
    color: white;
  }
`;

const ResultMessage = styled.div`
  text-align: center;
  padding: 2rem;
  color: #d4488e;
  font-size: 1.5rem;
  font-family: 'Dancing Script', cursive;
`;

const questions = [
  {
    question: "Qual é a minha comida favorita?",
    options: ["Strogonoff", "Lasanha", "Churrasco", "Pizza"],
    correct: 0
  },
  {
    question: "Qual é o meu maior sonho?",
    options: ["Viajar o mundo", "Ter uma família linda", "Ficar rico", "Ser famoso"],
    correct: 1
  },
  {
    question: "O que eu mais gosto em você?",
    options: ["Seu sorriso", "Sua inteligência", "Seu jeito carinhoso", "Tudo em você"],
    correct: 3
  },
  {
    question: "Onde foi nosso primeiro encontro?",
    options: ["No cinema", "Na praia", "No parque", "Na internet"],
    correct: 3
  },
  {
    question: "Qual é meu estilo de musica favorita?",
    options: ["Rock", "Sertanejo", "Pop", "Pagode"],
    correct: 0
  },
  {
    question: "O que eu mais gosto de fazer com você?",
    options: ["Assistir filmes", "Ligação", "Passear no parque", "Ficar abraçadinhos"],
    correct: 1
  },
  {
    question: "Qual é minha cor favorita?",
    options: ["Azul", "Verde", "Preto", "Vermelho"],
    correct: 3
  },
  {
    question: "O que eu sempre digo quando acordo?",
    options: ["Bom dia amor", "Te amo", "Quero café", "Mais 5 minutinhos"],
    correct: 0
  },
  {
    question: "Qual é meu maior medo?",
    options: ["Altura", "Te perder", "Barata", "Escuro"],
    correct: 1
  },
  {
    question: "O que eu mais gosto de fazer nos fins de semana?",
    options: ["Dormir até tarde", "Jogar videogame", "Sair com você", "Ficar em casa"],
    correct: 1
  }
];

const QuizDoAmor = () => {
  const [currentQuestion, setCurrentQuestion] = useState(0);
  const [score, setScore] = useState(0);
  const [showResult, setShowResult] = useState(false);

  const handleAnswer = (selectedOption: number) => {
    if (selectedOption === questions[currentQuestion].correct) {
      setScore(score + 1);
    }

    if (currentQuestion + 1 < questions.length) {
      setCurrentQuestion(currentQuestion + 1);
    } else {
      setShowResult(true);
    }
  };

  return (
    <QuizContainer>
      <Title>Quiz do Amor ❤️</Title>
      {!showResult ? (
        <QuestionCard>
          <Question>{questions[currentQuestion].question}</Question>
          {questions[currentQuestion].options.map((option, index) => (
            <OptionButton
              key={index}
              onClick={() => handleAnswer(index)}
            >
              {option}
            </OptionButton>
          ))}
        </QuestionCard>
      ) : (
        <ResultMessage>
          {score === questions.length ? (
            <>
              <h2>Parabéns meu amor! ❤️</h2>
              <p>Você acertou todas as {questions.length} perguntas!</p>
              <p>Você me conhece perfeitamente! Pode me dar o cuzinho? Te amo muito!</p>
            </>
          ) : score >= questions.length / 2 ? (
            <>
              <h2>Muito bem amor! 💕</h2>
              <p>Você acertou {score} de {questions.length} perguntas!</p>
              <p>Você me conhece bem, porem pra conhecer melhor pode me dar o cuzinho?</p>
            </>
          ) : (
            <>
              <h2>Oops! Voce nao foi muito bem, vai precisar me dar o cuzinho! 💝</h2>
              <p>Você acertou {score} de {questions.length} perguntas!</p>
              <p>Vamos precisar passar mais tempo juntos para eu te fuder melhor!</p>
            </>
          )}
        </ResultMessage>
      )}
    </QuizContainer>
  );
};

export default QuizDoAmor; 