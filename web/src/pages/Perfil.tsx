import { useRef, useState } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { apiUrl } from '../config/env';
import { useToast } from '../components/ui/feedback';
import { usePushNotifications } from '../hooks/usePushNotifications';
import { CameraIcon, BellIcon, BellSlashIcon } from '@heroicons/react/24/outline';

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
  const push = usePushNotifications();
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

        {push.supported && (
          <div className="mt-8 pt-6 border-t border-gray-200">
            <h2 className="text-lg font-semibold text-gray-800 mb-2 flex items-center gap-2">
              <BellIcon className="h-5 w-5 text-pink-500" />
              Notificações no celular
            </h2>
            <p className="text-sm text-gray-600 mb-3">
              Receba avisos como no app, mesmo com o navegador fechado (PWA).
            </p>
            {push.error && (
              <p className="text-sm text-red-600 mb-2" role="alert">{push.error}</p>
            )}
            {push.subscribed ? (
              <button
                type="button"
                onClick={push.disable}
                disabled={push.loading}
                className="flex items-center gap-2 px-4 py-2 rounded-xl bg-gray-100 text-gray-700 hover:bg-gray-200 transition-colors text-sm font-medium"
              >
                <BellSlashIcon className="h-4 w-4" />
                {push.loading ? 'Desativando...' : 'Desativar notificações'}
              </button>
            ) : (
              <button
                type="button"
                onClick={push.enable}
                disabled={push.loading || push.permission === 'denied'}
                className="flex items-center gap-2 px-4 py-2 rounded-xl bg-pink-500 text-white hover:bg-pink-600 transition-colors text-sm font-medium disabled:opacity-50"
              >
                <BellIcon className="h-4 w-4" />
                {push.loading ? 'Ativando...' : 'Ativar notificações'}
              </button>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
