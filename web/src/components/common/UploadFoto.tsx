import { useState } from 'react';
import { apiUrl } from '../../config/env';
import { getToken } from '../../contexts/AuthContext';
import { useToast } from '../ui/feedback';

interface UploadFotoProps {
  onUploadComplete: (url: string) => void;
}

const UploadFoto = ({ onUploadComplete }: UploadFotoProps) => {
  const [uploading, setUploading] = useState(false);
  const [progress, setProgress] = useState(0);
  const { showToast } = useToast();

  const handleUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    if (!file.type.startsWith('image/') && !file.type.startsWith('video/')) {
      showToast({ title: 'Selecione apenas imagem ou vídeo.', variant: 'error' });
      return;
    }

    const isVideo = file.type.startsWith('video/');
    const maxSize = isVideo ? 50 * 1024 * 1024 : 5 * 1024 * 1024;
    if (file.size > maxSize) {
      showToast({
        title: `Tamanho máximo: ${isVideo ? '50MB' : '5MB'}.`,
        variant: 'error',
      });
      return;
    }

    const token = getToken();
    if (!token) {
      showToast({ title: 'Faça login para adicionar fotos.', variant: 'error' });
      return;
    }

    setUploading(true);
    setProgress(20);

    try {
      const form = new FormData();
      form.append('file', file);
      const res = await fetch(`${apiUrl}/fotos/upload`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}` },
        body: form,
      });
      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.message || 'Falha no upload');
      }
      const data = await res.json();
      setProgress(100);
      const url = `${apiUrl}/fotos/file?path=${encodeURIComponent(data.relativePath)}`;
      onUploadComplete(url);
      showToast({ title: 'Upload concluído!', variant: 'success' });
    } catch (error) {
      console.error('Erro no upload:', error);
      showToast({
        title: 'Erro ao enviar o arquivo',
        description: 'Tente novamente.',
        variant: 'error',
      });
    } finally {
      setUploading(false);
      setTimeout(() => setProgress(0), 1000);
    }
    event.target.value = '';
  };

  return (
    <div className="my-4 flex flex-col items-center gap-4">
      <input
        type="file"
        id="foto-upload"
        accept="image/*,video/*"
        onChange={handleUpload}
        disabled={uploading}
        className="hidden"
      />
      <label
        htmlFor="foto-upload"
        className={`cursor-pointer px-6 py-3 rounded-lg text-white text-lg font-[Dancing_Script] transition-all shadow-md ${
          uploading
            ? 'opacity-70 cursor-not-allowed'
            : 'bg-[var(--love-primary)] hover:bg-[var(--love-primary-dark)] hover:-translate-y-0.5 hover:shadow-lg'
        }`}
      >
        {uploading ? 'Enviando...' : 'Adicionar Foto ou Vídeo'}
      </label>

      {uploading && (
        <>
          <div className="w-[200px] h-1.5 rounded-full overflow-hidden bg-[var(--love-primary-light)]">
            <div
              className="h-full rounded-full bg-[var(--love-primary)] transition-all duration-300"
              style={{ width: `${progress}%` }}
            />
          </div>
          <p className="text-[var(--love-primary)] font-[Dancing_Script] text-base m-0">
            {progress < 100 ? 'Enviando arquivo...' : 'Upload concluído!'}
          </p>
        </>
      )}
    </div>
  );
};

export default UploadFoto;
