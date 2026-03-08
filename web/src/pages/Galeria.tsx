import { useState, useEffect } from 'react';
import UploadFoto from '../components/common/UploadFoto';
import { apiUrl } from '../config/env';
import { getToken } from '../contexts/AuthContext';
import { useToast } from '../components/ui/feedback';

interface Foto {
  id: string;
  url: string;
  texto: string;
  tipo: 'imagem' | 'video';
  created_at: string;
}

function mapFromApi(item: { id: string; url: string; texto: string | null; tipo: 'imagem' | 'video'; createdAt: string }) {
  return {
    id: item.id,
    url: item.url,
    texto: item.texto ?? '',
    tipo: item.tipo,
    created_at: item.createdAt,
  };
}

const Galeria = () => {
  const [fotos, setFotos] = useState<Foto[]>([]);
  const [loading, setLoading] = useState(true);
  const [confirmDeleteId, setConfirmDeleteId] = useState<string | null>(null);
  const { showToast } = useToast();

  useEffect(() => {
    carregarFotos();
  }, []);

  const carregarFotos = async () => {
    try {
      const res = await fetch(`${apiUrl}/fotos`);
      if (!res.ok) throw new Error('Falha ao carregar');
      const data = await res.json();
      setFotos((data as any[]).map(mapFromApi));
    } catch (error) {
      console.error('Erro ao carregar fotos:', error);
      showToast({ title: 'Erro ao carregar as fotos', variant: 'error' });
    } finally {
      setLoading(false);
    }
  };

  const handleNovaFoto = async (url: string) => {
    const token = getToken();
    if (!token) {
      showToast({ title: 'Faça login para adicionar fotos', variant: 'error' });
      return;
    }
    try {
      const tipo = url.includes('video') ? 'video' : 'imagem';
      const res = await fetch(`${apiUrl}/fotos`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ url, texto: '', tipo }),
      });
      if (!res.ok) throw new Error('Falha ao salvar');
      showToast({ title: 'Foto adicionada!', variant: 'success' });
      carregarFotos();
    } catch (error) {
      console.error('Erro ao salvar foto:', error);
      showToast({ title: 'Erro ao salvar a foto', variant: 'error' });
    }
  };

  const handleTextoChange = async (id: string, novoTexto: string) => {
    try {
      const res = await fetch(`${apiUrl}/fotos/${id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ texto: novoTexto }),
      });
      if (!res.ok) throw new Error('Falha ao atualizar');
      setFotos((prev) =>
        prev.map((f) => (f.id === id ? { ...f, texto: novoTexto } : f))
      );
    } catch (error) {
      console.error('Erro ao atualizar texto:', error);
      showToast({ title: 'Erro ao salvar o texto', variant: 'error' });
    }
  };

  const handleExcluirFoto = (id: string) => setConfirmDeleteId(id);

  const confirmExcluir = async () => {
    if (!confirmDeleteId) return;
    try {
      const res = await fetch(`${apiUrl}/fotos/${confirmDeleteId}`, {
        method: 'DELETE',
      });
      if (!res.ok) throw new Error('Falha ao excluir');
      setFotos((prev) => prev.filter((f) => f.id !== confirmDeleteId));
      showToast({ title: 'Memória excluída', variant: 'success' });
    } catch (error) {
      console.error('Erro ao excluir foto:', error);
      showToast({ title: 'Erro ao excluir a foto', variant: 'error' });
    } finally {
      setConfirmDeleteId(null);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-[var(--love-bg-start)] to-[var(--love-bg-end)] p-6 sm:p-8">
      <h1 className="text-2xl sm:text-3xl font-bold text-primary mb-6">
        Nossa Galeria de Memórias
      </h1>
      <UploadFoto onUploadComplete={handleNovaFoto} />

      {confirmDeleteId && (
        <div className="flex flex-wrap items-center gap-2 p-3 mb-4 rounded-lg bg-card shadow-md">
          <span className="text-sm text-foreground">Excluir esta memória?</span>
          <button
            type="button"
            className="px-3 py-1.5 rounded-md bg-red-500 text-white text-sm hover:bg-red-600 transition-colors"
            onClick={confirmExcluir}
          >
            Sim
          </button>
          <button
            type="button"
            className="px-3 py-1.5 rounded-md bg-muted text-muted-foreground text-sm hover:bg-muted/80 transition-colors"
            onClick={() => setConfirmDeleteId(null)}
          >
            Cancelar
          </button>
        </div>
      )}

      {loading ? (
        <p className="text-primary-dark">Carregando...</p>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6 mt-8">
          {fotos.map((foto) => (
            <div
              key={foto.id}
              className="group relative rounded-xl overflow-hidden bg-card shadow-md hover:shadow-lg hover:-translate-y-1 transition-all duration-200"
            >
              <button
                type="button"
                className="absolute top-2.5 right-2.5 z-10 opacity-0 group-hover:opacity-100 transition-opacity bg-red-500 hover:bg-red-600 text-white border-0 rounded py-2 px-3 text-sm cursor-pointer"
                onClick={() => handleExcluirFoto(foto.id)}
              >
                Excluir
              </button>
              {foto.tipo === 'video' ? (
                <video controls className="w-full h-[200px] object-cover block [&::-webkit-media-controls]:z-[2] pointer-events-none">
                  <source src={foto.url} type="video/mp4" />
                  Seu navegador não suporta vídeos.
                </video>
              ) : (
                <img src={foto.url} alt="" className="w-full h-[200px] object-cover block" />
              )}
              <div className="p-4 text-muted-foreground">
                <textarea
                  value={foto.texto || ''}
                  onChange={(e) => handleTextoChange(foto.id, e.target.value)}
                  placeholder="Adicione uma descrição..."
                  className="w-full p-2 mt-2 min-h-[60px] resize-y rounded border border-input bg-background text-foreground font-inherit focus:outline-none focus:border-primary transition-colors"
                />
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default Galeria;
