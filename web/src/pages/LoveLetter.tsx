import { useEffect, useState } from 'react';
import { NovaCartaModal } from '../components/NovaCartaModal';

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
      await carregarCartas();
    } catch (error) {
      console.error('Erro ao salvar carta:', error);
    }
  };

  return (
    <div className="min-h-screen pt-20 px-6 pb-8 bg-gradient-to-b from-[var(--love-bg-start)] to-[var(--love-bg-end)]">
      <header className="p-4 text-center relative rounded-2xl my-4 mx-auto max-w-[1000px] bg-transparent">
        <h1 className="text-primary text-4xl md:text-5xl font-[Pacifico] my-2 pt-2">
          {'Cartas de Amor'.split('').map((letter, index) => (
            <span key={index} className="inline-block hover:scale-110 transition-transform duration-300" style={{ animationDelay: `${index * 0.1}s` }}>
              {letter === ' ' ? '\u00A0' : letter}
            </span>
          ))}
        </h1>
        <p className="text-muted-foreground text-xl md:text-2xl max-w-[800px] mx-auto mb-8 leading-relaxed font-[Dancing_Script] md:px-4">
          Um espaço especial onde guardo todas as minhas declarações de amor para você.
          Cada carta é um pedacinho do meu coração transformado em palavras.
        </p>
        <button
          type="button"
          onClick={() => setModalAberto(true)}
          className="flex items-center gap-2 mx-auto mb-8 px-8 py-3 rounded-[25px] text-lg text-primary-foreground border-0 cursor-pointer transition-all duration-300 shadow-md bg-primary hover:opacity-90 hover:-translate-y-0.5 hover:shadow-lg font-[Dancing_Script]"
        >
          <span className="text-2xl leading-none">+</span> Escrever Nova Carta
        </button>
      </header>

      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-8 max-w-[1200px] mx-auto">
        {cartas.map((carta) => (
          <div
            key={carta.id}
            onClick={() => setCartaSelecionada(carta)}
            className="bg-card/95 dark:bg-card p-8 rounded-2xl shadow-md cursor-pointer hover:-translate-y-1 transition-all duration-200"
          >
            <div className="text-primary text-sm mb-4">
              {new Date(carta.data).toLocaleDateString('pt-BR')}
            </div>
            <h3 className="text-lg font-semibold text-foreground mb-2">{carta.titulo}</h3>
            <div className="text-muted-foreground font-[Dancing_Script] text-lg line-clamp-3">
              {carta.conteudo}
            </div>
          </div>
        ))}
      </div>

      <NovaCartaModal
        isOpen={modalAberto}
        onClose={() => setModalAberto(false)}
        onSave={salvarNovaCarta}
      />

      {cartaSelecionada && (
        <div
          className="fixed inset-0 bg-black/50 flex justify-center items-center z-[1000] p-8"
          onClick={() => setCartaSelecionada(null)}
        >
          <div
            className="bg-card rounded-2xl p-8 shadow-xl max-w-[800px] w-full max-h-[90vh] overflow-y-auto"
            onClick={(e) => e.stopPropagation()}
          >
            <h2 className="text-primary text-2xl font-[Dancing_Script] mb-4">{cartaSelecionada.titulo}</h2>
            <div className="text-primary text-sm mb-6">
              {new Date(cartaSelecionada.data).toLocaleDateString('pt-BR')}
            </div>
            <div className="font-[Dancing_Script] text-xl leading-relaxed text-foreground whitespace-pre-wrap">
              {cartaSelecionada.conteudo.split('\n').map((paragraph, i) => (
                <p key={i} className="mb-4">{paragraph}</p>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default LoveLetter;
