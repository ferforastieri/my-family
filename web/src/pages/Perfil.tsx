import { useRef, useState } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { apiUrl } from '../config/env';
import { useToast } from '../components/ui/feedback';
import { CameraIcon } from '@heroicons/react/24/outline';

const roleLabels: Record<string, string> = {
  admin: 'Administrador',
  wife: 'Esposa',
  child: 'Filho(a)',
  friend: 'Amigo(a)',
};

function avatarUrl(avatarPath: string | null | undefined): string | null {
  if (!avatarPath) return null;
  return `${apiUrl}/auth/avatar?path=${encodeURIComponent(avatarPath)}`;
}

export default function Perfil() {
  const { user, uploadAvatar } = useAuth();
  const { showToast } = useToast();
  const [uploading, setUploading] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  if (!user) return null;

  const url = avatarUrl(user.avatarPath);
  const initial = user.name ? user.name.charAt(0).toUpperCase() : user.email.charAt(0).toUpperCase();

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file || !file.type.startsWith('image/')) {
      showToast({ title: 'Selecione uma imagem', variant: 'error' });
      return;
    }
    setUploading(true);
    try {
      await uploadAvatar(file);
      showToast({ title: 'Avatar atualizado!', variant: 'success' });
      if (inputRef.current) inputRef.current.value = '';
    } catch (err) {
      showToast({ title: 'Erro ao enviar avatar', description: err instanceof Error ? err.message : '', variant: 'error' });
    } finally {
      setUploading(false);
    }
  };

  return (
    <div className="min-h-screen p-6 md:p-8 bg-gradient-to-b from-[#fff8fa] to-[#fff0f5]">
      <div className="max-w-md mx-auto bg-white rounded-2xl shadow-lg shadow-pink-200/50 p-8">
        <h1 className="text-2xl font-semibold text-pink-600 mb-6">Meu perfil</h1>

        <div className="relative inline-block mb-6">
          <div className="w-24 h-24 rounded-full overflow-hidden bg-pink-200 flex items-center justify-center text-pink-600 text-3xl font-medium shrink-0">
            {url ? (
              <img src={url} alt="Avatar" className="w-full h-full object-cover" />
            ) : (
              <span>{initial}</span>
            )}
          </div>
          <label className="absolute bottom-0 right-0 w-9 h-9 rounded-full bg-pink-500 text-white flex items-center justify-center cursor-pointer hover:bg-pink-600 transition-colors shadow">
            <input
              ref={inputRef}
              type="file"
              accept="image/*"
              className="hidden"
              disabled={uploading}
              onChange={handleFileChange}
            />
            <CameraIcon className="h-5 w-5" />
          </label>
        </div>
        {uploading && <p className="text-sm text-pink-600 mb-4">Enviando...</p>}

        <dl className="space-y-3 text-sm">
          <div>
            <dt className="text-gray-500">Nome</dt>
            <dd className="font-medium text-gray-900">{user.name || '—'}</dd>
          </div>
          <div>
            <dt className="text-gray-500">E-mail</dt>
            <dd className="font-medium text-gray-900">{user.email}</dd>
          </div>
          <div>
            <dt className="text-gray-500">Perfil</dt>
            <dd className="font-medium text-gray-900">{roleLabels[user.role] ?? user.role}</dd>
          </div>
        </dl>
      </div>
    </div>
  );
}
