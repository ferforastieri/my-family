import { useNavigate } from 'react-router-dom';

const Jogos = () => {
  const navigate = useNavigate();

  return (
    <div className="w-full min-h-screen bg-gradient-to-b from-[var(--love-bg-start)] to-[var(--love-bg-end)] p-8">
      <h1 className="text-love-primary text-3xl md:text-4xl font-[Pacifico] text-center mb-8">
        Jogos do Amor
      </h1>
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-8 max-w-[1200px] mx-auto p-4">
        <button
          type="button"
          onClick={() => navigate('/quiz-do-amor')}
          className="bg-card rounded-2xl p-6 shadow-md cursor-pointer hover:-translate-y-1 hover:shadow-lg transition-all duration-300 text-left"
        >
          <h3 className="text-love-primary text-xl font-semibold mb-4 text-center">Quiz do Amor ❤️</h3>
          <p className="text-muted-foreground text-center">Teste seus conhecimentos sobre nossa história de amor!</p>
        </button>
        <button
          type="button"
          onClick={() => navigate('/caca-palavras')}
          className="bg-card rounded-2xl p-6 shadow-md cursor-pointer hover:-translate-y-1 hover:shadow-lg transition-all duration-300 text-left"
        >
          <h3 className="text-love-primary text-xl font-semibold mb-4 text-center">Caça Palavras 🔍</h3>
          <p className="text-muted-foreground text-center">Encontre palavras românticas que mudam todos os dias!</p>
        </button>
      </div>
    </div>
  );
};

export default Jogos;
