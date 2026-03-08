import { useState } from 'react';
import { Sheet } from '../ui/layout/sheet';
import { useNotifications } from '../../contexts/NotificationsContext';
import { usePushNotifications } from '../../hooks/usePushNotifications';
import { BellIcon, BellSlashIcon, TrashIcon } from '@heroicons/react/24/outline';
import { useNavigate } from 'react-router-dom';

interface NotificationPanelProps {
  isOpen: boolean;
  onClose: () => void;
}

function formatAt(at: number) {
  const d = new Date(at);
  const now = new Date();
  const diff = now.getTime() - at;
  if (diff < 60000) return 'Agora';
  if (diff < 3600000) return `${Math.floor(diff / 60000)} min`;
  if (diff < 86400000) return d.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });
  return d.toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' });
}

export default function NotificationPanel({ isOpen, onClose }: NotificationPanelProps) {
  const { notifications, clearAll } = useNotifications();
  const push = usePushNotifications();
  const navigate = useNavigate();
  const [clearing, setClearing] = useState(false);

  const handleClear = async () => {
    setClearing(true);
    await clearAll();
    setClearing(false);
  };

  return (
    <Sheet isOpen={isOpen} onClose={onClose} side="right" size="md">
      <div className="pt-14 pb-6 px-6 flex flex-col h-full bg-card text-card-foreground">
        <h2 className="text-lg font-semibold mb-4 flex items-center gap-2 text-foreground">
          <BellIcon className="h-5 w-5 text-primary" />
          Notificações
        </h2>
        {push.supported && (
          <div className="mb-4 p-3 rounded-lg bg-muted border border-border">
            <p className="text-sm text-muted-foreground mb-2">Push no celular</p>
            {push.error && <p className="text-sm text-destructive mb-2">{push.error}</p>}
            {push.subscribed ? (
              <button
                type="button"
                onClick={push.disable}
                disabled={push.loading}
                className="flex items-center gap-2 w-full justify-center px-3 py-2 rounded-lg bg-muted hover:bg-accent text-foreground text-sm font-medium"
              >
                <BellSlashIcon className="h-4 w-4" />
                {push.loading ? 'Desativando...' : 'Desativar'}
              </button>
            ) : (
              <button
                type="button"
                onClick={push.enable}
                disabled={push.loading || push.permission === 'denied'}
                className="flex items-center gap-2 w-full justify-center px-3 py-2 rounded-lg bg-primary text-primary-foreground text-sm font-medium disabled:opacity-50"
              >
                <BellIcon className="h-4 w-4" />
                {push.loading ? 'Ativando...' : 'Ativar'}
              </button>
            )}
          </div>
        )}
        <div className="flex items-center justify-between mb-2">
          <span className="text-sm text-muted-foreground">Lista</span>
          {notifications.length > 0 && (
            <button type="button" onClick={handleClear} disabled={clearing} className="flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground">
              <TrashIcon className="h-4 w-4" />
              {clearing ? 'Limpando...' : 'Limpar'}
            </button>
          )}
        </div>
        <ul className="flex-1 overflow-y-auto space-y-2 min-h-0">
          {notifications.length === 0 ? (
            <li className="text-sm text-muted-foreground py-4">Nenhuma notificação.</li>
          ) : (
            notifications.map((n) => (
              <li key={n.id}>
                <button
                  type="button"
                  onClick={() => { onClose(); navigate(n.url); }}
                  className="w-full text-left p-3 rounded-lg bg-muted/50 hover:bg-accent border border-border"
                >
                  <p className="text-sm font-medium text-foreground truncate">{n.title}</p>
                  {n.body && <p className="text-xs text-muted-foreground mt-0.5 line-clamp-2">{n.body}</p>}
                  <p className="text-xs text-muted-foreground mt-1">{formatAt(n.at)}</p>
                </button>
              </li>
            ))
          )}
        </ul>
      </div>
    </Sheet>
  );
}
