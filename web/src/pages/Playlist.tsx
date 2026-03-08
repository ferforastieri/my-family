import { useEffect, useState } from 'react';
import { NovaMusicaModal } from '../components/NovaMusicaModal';
import { SpotifyPlayer } from '../components/SpotifyPlayer';
import { YouTubePlayer } from '../components/YouTubePlayer';

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

  return (
    <div className="min-h-screen pt-20 px-6 pb-8 bg-gradient-to-b from-[var(--love-bg-start)] to-[var(--love-bg-end)]">
      <header className="p-4 text-center relative rounded-2xl my-4 mx-auto max-w-[1000px] bg-transparent">
        <h1 className="text-primary text-4xl md:text-5xl font-[Pacifico] my-2 pt-2">
          {'Playlist do Nosso Amor'.split('').map((letter, index) => (
            <span key={index} className="inline-block hover:scale-110 transition-transform duration-300" style={{ animationDelay: `${index * 0.1}s` }}>
              {letter === ' ' ? '\u00A0' : letter}
            </span>
          ))}
        </h1>
        <p className="text-muted-foreground text-xl md:text-2xl max-w-[800px] mx-auto mb-8 leading-relaxed font-[Dancing_Script] md:px-4">
          Cada música conta uma história nossa. Uma melodia que nos faz sorrir,
          dançar e reviver momentos especiais do nosso amor.
        </p>
        <button
          type="button"
          onClick={() => setModalAberto(true)}
          className="flex items-center gap-2 mx-auto mb-8 px-8 py-3 rounded-[25px] text-lg text-primary-foreground border-0 cursor-pointer transition-all duration-300 shadow-md bg-primary hover:opacity-90 hover:-translate-y-0.5 hover:shadow-lg font-[Dancing_Script]"
        >
          <span>+</span> Adicionar Nova Música
        </button>
      </header>

      <div className="flex flex-wrap justify-center gap-4 mb-8 max-w-[1200px] mx-auto">
        {momentos.map((momento) => (
          <button
            key={momento}
            type="button"
            onClick={() => setFiltroMomento(momento)}
            className={`px-5 py-2.5 rounded-xl border-2 border-primary font-[Dancing_Script] text-base cursor-pointer transition-all duration-300 hover:-translate-y-0.5 hover:shadow-md ${
              filtroMomento === momento
                ? 'bg-primary text-primary-foreground'
                : 'bg-transparent text-primary'
            }`}
          >
            {momento}
          </button>
        ))}
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-8 max-w-[1200px] mx-auto">
        {musicasFiltradas.map((musica) => (
          <div
            key={musica.id}
            className="bg-card rounded-2xl p-8 shadow-md hover:shadow-lg hover:-translate-y-1 transition-all duration-300"
          >
            <h3 className="text-primary text-xl font-[Dancing_Script] mb-2">{musica.titulo}</h3>
            <div className="text-muted-foreground text-base mb-4">{musica.artista}</div>
            <div className="text-primary text-sm mb-4 italic">{musica.momento}</div>
            <div className="text-foreground/80 text-base leading-relaxed mb-4">{musica.descricao}</div>
            <div className="mt-4 pt-4 border-t border-border flex flex-col gap-4">
              {musica.link_spotify && (
                musica.link_spotify.includes('youtube.com') || musica.link_spotify.includes('youtu.be') ? (
                  <YouTubePlayer youtubeUrl={musica.link_spotify} />
                ) : musica.link_spotify.includes('spotify.com') ? (
                  <SpotifyPlayer spotifyUrl={musica.link_spotify} />
                ) : null
              )}
            </div>
          </div>
        ))}
      </div>

      <NovaMusicaModal
        isOpen={modalAberto}
        onClose={() => setModalAberto(false)}
        onSave={salvarMusica}
      />
    </div>
  );
};

export default Playlist;
