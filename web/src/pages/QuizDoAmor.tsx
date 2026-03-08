import { useState } from 'react';

const questions = [
  { question: "Qual é a minha comida favorita?", options: ["Strogonoff", "Lasanha", "Churrasco", "Pizza"], correct: 0 },
  { question: "Qual é o meu maior sonho?", options: ["Viajar o mundo", "Ter uma família linda", "Ficar rico", "Ser famoso"], correct: 1 },
  { question: "O que eu mais gosto em você?", options: ["Seu sorriso", "Sua inteligência", "Seu jeito carinhoso", "Tudo em você"], correct: 3 },
  { question: "Onde foi nosso primeiro encontro?", options: ["No cinema", "Na praia", "No parque", "Na internet"], correct: 3 },
  { question: "Qual é meu estilo de musica favorita?", options: ["Rock", "Sertanejo", "Pop", "Pagode"], correct: 0 },
  { question: "O que eu mais gosto de fazer com você?", options: ["Assistir filmes", "Ligação", "Passear no parque", "Ficar abraçadinhos"], correct: 1 },
  { question: "Qual é minha cor favorita?", options: ["Azul", "Verde", "Preto", "Vermelho"], correct: 3 },
  { question: "O que eu sempre digo quando acordo?", options: ["Bom dia amor", "Te amo", "Quero café", "Mais 5 minutinhos"], correct: 0 },
  { question: "Qual é meu maior medo?", options: ["Altura", "Te perder", "Barata", "Escuro"], correct: 1 },
  { question: "O que eu mais gosto de fazer nos fins de semana?", options: ["Dormir até tarde", "Jogar videogame", "Sair com você", "Ficar em casa"], correct: 1 }
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
    <div className="min-h-screen bg-gradient-to-b from-[var(--love-bg-start)] to-[var(--love-bg-end)] p-8">
      <h1 className="text-love-primary text-3xl font-[Pacifico] text-center mb-8">Quiz do Amor ❤️</h1>
      {!showResult ? (
        <div className="bg-card/90 dark:bg-card p-8 rounded-2xl max-w-[600px] mx-auto shadow-md">
          <h2 className="text-love-primary-dark text-xl mb-6">{questions[currentQuestion].question}</h2>
          <div className="flex flex-col gap-2">
            {questions[currentQuestion].options.map((option, index) => (
              <button
                key={index}
                type="button"
                onClick={() => handleAnswer(index)}
                className="w-full py-4 px-4 rounded-lg border-2 border-[var(--love-primary)] bg-background text-love-primary cursor-pointer transition-all hover:bg-[var(--love-primary)] hover:text-white"
              >
                {option}
              </button>
            ))}
          </div>
        </div>
      ) : (
        <div className="text-center py-8 text-love-primary-dark text-2xl font-[Dancing_Script]">
          {score === questions.length ? (
            <>
              <h2 className="text-2xl font-bold mb-4">Parabéns meu amor! ❤️</h2>
              <p>Você acertou todas as {questions.length} perguntas!</p>
              <p>Você me conhece perfeitamente! Te amo muito!</p>
            </>
          ) : score >= questions.length / 2 ? (
            <>
              <h2 className="text-2xl font-bold mb-4">Muito bem amor! 💕</h2>
              <p>Você acertou {score} de {questions.length} perguntas!</p>
            </>
          ) : (
            <>
              <h2 className="text-2xl font-bold mb-4">Oops! 💝</h2>
              <p>Você acertou {score} de {questions.length} perguntas!</p>
              <p>Vamos precisar passar mais tempo juntos!</p>
            </>
          )}
        </div>
      )}
    </div>
  );
};

export default QuizDoAmor;
