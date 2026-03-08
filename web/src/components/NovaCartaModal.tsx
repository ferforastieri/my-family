import { useState } from 'react';

const inputClass = "w-full p-4 border-2 border-[var(--love-primary-light)] rounded-xl font-[Dancing_Script] text-lg transition-all bg-background focus:outline-none focus:border-[var(--love-primary)] focus:ring-2 focus:ring-[var(--love-primary)]/20 placeholder:text-muted-foreground";

interface NovaCartaModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (carta: { titulo: string; conteudo: string }) => Promise<void>;
}

export const NovaCartaModal = ({ isOpen, onClose, onSave }: NovaCartaModalProps) => {
  const [titulo, setTitulo] = useState('');
  const [conteudo, setConteudo] = useState('');

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    await onSave({ titulo, conteudo });
    setTitulo('');
    setConteudo('');
    onClose();
  };

  return (
    <div className="fixed inset-0 bg-black/60 flex justify-center items-center z-[1000] p-4 backdrop-blur-sm" onClick={onClose}>
      <div className="bg-gradient-to-b from-[var(--love-bg-start)] to-card dark:to-card p-8 rounded-2xl w-[90%] max-w-[600px] shadow-xl animate-slide-in" onClick={e => e.stopPropagation()}>
        <h2 className="text-love-primary font-[Pacifico] text-2xl text-center mb-6">Nova Carta de Amor</h2>
        <form onSubmit={handleSubmit} className="flex flex-col gap-6">
          <input type="text" placeholder="Dê um título especial para sua carta..." value={titulo} onChange={e => setTitulo(e.target.value)} required className={inputClass} />
          <textarea placeholder="Escreva aqui sua declaração de amor..." value={conteudo} onChange={e => setConteudo(e.target.value)} required className={`${inputClass} min-h-[250px] resize-y`} />
          <div className="flex gap-4 justify-end mt-4">
            <button type="button" onClick={onClose} className="px-8 py-3 rounded-[25px] font-[Dancing_Script] text-lg cursor-pointer transition-all hover:-translate-y-0.5 bg-transparent text-love-primary border-2 border-[var(--love-primary)] hover:bg-[var(--love-primary-light)]">
              Cancelar
            </button>
            <button type="submit" className="px-8 py-3 rounded-[25px] font-[Dancing_Script] text-lg cursor-pointer transition-all hover:-translate-y-0.5 bg-[var(--love-primary)] text-white border-0 shadow-md hover:bg-[var(--love-primary-dark)]">
              Guardar no Coração
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}; 