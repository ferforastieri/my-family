import { useState } from 'react';

const inputClass = "w-full p-4 border-2 border-[var(--love-primary-light)] rounded-xl font-[Dancing_Script] text-lg transition-all bg-background focus:outline-none focus:border-[var(--love-primary)] focus:ring-2 focus:ring-[var(--love-primary)]/20 placeholder:text-muted-foreground";
const momentos = [
  'Primeiro Encontro',
  'Primeiro Beijo',
  'Pedido de Namoro',
  'Noivado',
  'Casamento',
  'Lua de Mel',
  'Momentos Especiais',
  'Outros'
];

interface NovaMusicaModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (musica: {
    titulo: string;
    artista: string;
    link_spotify: string;
    descricao: string;
    momento: string;
  }) => Promise<void>;
}

export const NovaMusicaModal = ({ isOpen, onClose, onSave }: NovaMusicaModalProps) => {
  const [titulo, setTitulo] = useState('');
  const [artista, setArtista] = useState('');
  const [linkSpotify, setLinkSpotify] = useState('');
  const [descricao, setDescricao] = useState('');
  const [momento, setMomento] = useState('');

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    await onSave({
      titulo,
      artista,
      link_spotify: linkSpotify,
      descricao,
      momento
    });
    setTitulo('');
    setArtista('');
    setLinkSpotify('');
    setDescricao('');
    setMomento('');
    
    onClose();
  };

  return (
    <div className="fixed inset-0 bg-black/60 flex justify-center items-center z-[1000] p-4 backdrop-blur-sm" onClick={onClose}>
      <div className="bg-gradient-to-b from-[var(--love-bg-start)] to-card dark:to-card p-8 rounded-2xl w-[90%] max-w-[600px] shadow-xl animate-slide-in" onClick={e => e.stopPropagation()}>
        <h2 className="text-love-primary font-[Pacifico] text-2xl text-center mb-6">Adicionar Nova Música</h2>
        <form onSubmit={handleSubmit} className="flex flex-col gap-6">
          <input type="text" placeholder="Nome da música" value={titulo} onChange={e => setTitulo(e.target.value)} required className={inputClass} />
          <input type="text" placeholder="Artista" value={artista} onChange={e => setArtista(e.target.value)} required className={inputClass} />
          <input type="url" placeholder="Link do Spotify ou YouTube" value={linkSpotify} onChange={e => setLinkSpotify(e.target.value)} className={inputClass} />
          <select value={momento} onChange={e => setMomento(e.target.value)} required className={inputClass}>
            <option value="">Selecione o momento...</option>
            {momentos.map(m => (<option key={m} value={m}>{m}</option>))}
          </select>
          <textarea placeholder="Por que essa música é especial?" value={descricao} onChange={e => setDescricao(e.target.value)} required className={`${inputClass} min-h-[150px] resize-y`} />
          <div className="flex gap-4 justify-end mt-4">
            <button type="button" onClick={onClose} className="px-8 py-3 rounded-[25px] font-[Dancing_Script] text-lg cursor-pointer transition-all hover:-translate-y-0.5 bg-transparent text-love-primary border-2 border-[var(--love-primary)] hover:bg-[var(--love-primary-light)]">
              Cancelar
            </button>
            <button type="submit" className="px-8 py-3 rounded-[25px] font-[Dancing_Script] text-lg cursor-pointer transition-all hover:-translate-y-0.5 bg-[var(--love-primary)] text-white border-0 shadow-md hover:bg-[var(--love-primary-dark)]">
              Adicionar Música
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}; 