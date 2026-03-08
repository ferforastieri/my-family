import { useState, useEffect, useCallback } from 'react';
import { apiUrl } from '../config/env';
import { getToken } from '../contexts/AuthContext';
import { useAuth } from '../contexts/AuthContext';
import type { UserRole } from '../contexts/AuthContext';
import {
  UserPlusIcon,
  PencilIcon,
  TrashIcon,
  PaperAirplaneIcon,
  CalendarDaysIcon,
  BellIcon,
} from '@heroicons/react/24/outline';

const authHeaders = () => ({
  Authorization: `Bearer ${getToken()}`,
  'Content-Type': 'application/json',
});

interface UserRow {
  id: number;
  email: string;
  name: string | null;
  role: UserRole;
  avatarPath: string | null;
  createdAt: string;
}

interface NotificationRow {
  id: number;
  title: string;
  body: string;
  url: string;
  icon: string | null;
  at: number;
}

export default function Admin() {
  const { user } = useAuth();
  const [users, setUsers] = useState<UserRow[]>([]);
  const [notifications, setNotifications] = useState<NotificationRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [tab, setTab] = useState<'users' | 'notifications'>('users');
  const [editUser, setEditUser] = useState<UserRow | null>(null);
  const [editNotif, setEditNotif] = useState<NotificationRow | null>(null);
  const [formNotif, setFormNotif] = useState<{ title: string; body: string; url: string; scheduledAt: string }>({
    title: '',
    body: '',
    url: '/',
    scheduledAt: '',
  });
  const [sending, setSending] = useState(false);

  const loadUsers = useCallback(async () => {
    const res = await fetch(`${apiUrl}/users`, { headers: authHeaders() });
    if (res.ok) setUsers(await res.json());
  }, []);

  const loadNotifications = useCallback(async () => {
    const res = await fetch(`${apiUrl}/notifications`, { headers: authHeaders() });
    if (res.ok) setNotifications(await res.json());
  }, []);

  useEffect(() => {
    if (user?.role !== 'admin') return;
    Promise.all([loadUsers(), loadNotifications()]).finally(() => setLoading(false));
  }, [user?.role, loadUsers, loadNotifications]);

  const handleUpdateUser = async (id: number, data: { name?: string; role?: UserRole }) => {
    const res = await fetch(`${apiUrl}/users/${id}`, {
      method: 'PATCH',
      headers: authHeaders(),
      body: JSON.stringify(data),
    });
    if (res.ok) {
      setEditUser(null);
      loadUsers();
    } else {
      const err = await res.json();
      alert(err.message || 'Erro ao atualizar');
    }
  };

  const handleDeleteUser = async (id: number) => {
    if (!confirm('Excluir este usuário?')) return;
    const res = await fetch(`${apiUrl}/users/${id}`, { method: 'DELETE', headers: authHeaders() });
    if (res.ok) {
      setEditUser(null);
      loadUsers();
    } else alert('Erro ao excluir');
  };

  const handleCreateNotification = async () => {
    if (!formNotif.title.trim()) return;
    const res = await fetch(`${apiUrl}/notifications`, {
      method: 'POST',
      headers: authHeaders(),
      body: JSON.stringify({
        title: formNotif.title,
        body: formNotif.body || undefined,
        url: formNotif.url || '/',
      }),
    });
    if (res.ok) {
      setFormNotif({ title: '', body: '', url: '/', scheduledAt: '' });
      loadNotifications();
    } else alert('Erro ao criar');
  };

  const handleUpdateNotification = async (id: number, data: { title?: string; body?: string; url?: string }) => {
    const res = await fetch(`${apiUrl}/notifications/${id}`, {
      method: 'PATCH',
      headers: authHeaders(),
      body: JSON.stringify(data),
    });
    if (res.ok) {
      setEditNotif(null);
      loadNotifications();
    } else alert('Erro ao atualizar');
  };

  const handleDeleteNotification = async (id: number) => {
    if (!confirm('Excluir esta notificação?')) return;
    const res = await fetch(`${apiUrl}/notifications/${id}`, { method: 'DELETE', headers: authHeaders() });
    if (res.ok) {
      setEditNotif(null);
      loadNotifications();
    } else alert('Erro ao excluir');
  };

  const handleSendNow = async (title: string, body?: string, url?: string) => {
    setSending(true);
    try {
      const res = await fetch(`${apiUrl}/notifications/send`, {
        method: 'POST',
        headers: authHeaders(),
        body: JSON.stringify({ title, body, url }),
      });
      if (res.ok) {
        const data = await res.json();
        alert(`Enviada. ${data.sent ?? 0} dispositivo(s) notificado(s).`);
        loadNotifications();
      } else alert('Erro ao enviar');
    } finally {
      setSending(false);
    }
  };

  const handleSchedule = async () => {
    if (!formNotif.title.trim() || !formNotif.scheduledAt.trim()) {
      alert('Preencha título e data/hora.');
      return;
    }
    const scheduledAt = new Date(formNotif.scheduledAt).toISOString();
    const res = await fetch(`${apiUrl}/notifications/schedule`, {
      method: 'POST',
      headers: authHeaders(),
      body: JSON.stringify({
        title: formNotif.title,
        body: formNotif.body || undefined,
        url: formNotif.url || '/',
        scheduledAt,
      }),
    });
    if (res.ok) {
      setFormNotif((p) => ({ ...p, title: '', body: '', scheduledAt: '' }));
      alert('Notificação agendada.');
      loadNotifications();
    } else {
      const err = await res.json();
      alert(err.message || 'Erro ao agendar');
    }
  };

  if (user?.role !== 'admin') return null;
  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-b from-[var(--love-bg-start)] to-[var(--love-bg-end)]">
        <span className="text-muted-foreground">Carregando...</span>
      </div>
    );
  }

  return (
    <div className="min-h-screen pt-20 px-4 pb-8 bg-gradient-to-b from-[var(--love-bg-start)] to-[var(--love-bg-end)]">
      <div className="max-w-4xl mx-auto">
        <h1 className="text-primary font-[Pacifico] text-3xl text-center mb-6">Administração</h1>

        <div className="flex gap-2 mb-6 border-b border-border">
          <button
            type="button"
            onClick={() => setTab('users')}
            className={`px-4 py-2 rounded-t-lg font-medium ${tab === 'users' ? 'bg-card border border-border border-b-0' : 'text-muted-foreground hover:text-foreground'}`}
          >
            Usuários
          </button>
          <button
            type="button"
            onClick={() => setTab('notifications')}
            className={`px-4 py-2 rounded-t-lg font-medium ${tab === 'notifications' ? 'bg-card border border-border border-b-0' : 'text-muted-foreground hover:text-foreground'}`}
          >
            Notificações
          </button>
        </div>

        {tab === 'users' && (
          <div className="bg-card rounded-xl border border-border overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="bg-muted/50">
                  <tr>
                    <th className="text-left p-3">Email</th>
                    <th className="text-left p-3">Nome</th>
                    <th className="text-left p-3">Role</th>
                    <th className="p-3 w-24">Ações</th>
                  </tr>
                </thead>
                <tbody>
                  {users.map((u) =>
                    editUser?.id === u.id ? (
                      <tr key={u.id} className="border-t border-border">
                        <td className="p-3">{u.email}</td>
                        <td className="p-3">
                          <input
                            type="text"
                            defaultValue={editUser.name ?? ''}
                            className="w-full rounded border border-input bg-background px-2 py-1 text-foreground"
                            onBlur={(e) => setEditUser((p) => (p ? { ...p, name: e.target.value || null } : null))}
                          />
                        </td>
                        <td className="p-3">
                          <select
                            defaultValue={editUser.role}
                            className="rounded border border-input bg-background px-2 py-1 text-foreground"
                            onChange={(e) => setEditUser((p) => (p ? { ...p, role: e.target.value as UserRole } : null))}
                          >
                            {(['admin', 'wife', 'child', 'friend'] as const).map((r) => (
                              <option key={r} value={r}>{r}</option>
                            ))}
                          </select>
                        </td>
                        <td className="p-3 flex gap-1">
                          <button
                            type="button"
                            className="p-1.5 rounded bg-primary text-primary-foreground hover:opacity-90"
                            onClick={() => handleUpdateUser(u.id, { name: editUser.name ?? undefined, role: editUser.role })}
                          >
                            Salvar
                          </button>
                          <button type="button" className="p-1.5 rounded border border-border" onClick={() => setEditUser(null)}>
                            Cancelar
                          </button>
                        </td>
                      </tr>
                    ) : (
                      <tr key={u.id} className="border-t border-border">
                        <td className="p-3">{u.email}</td>
                        <td className="p-3">{u.name ?? '—'}</td>
                        <td className="p-3">{u.role}</td>
                        <td className="p-3 flex gap-1">
                          <button
                            type="button"
                            className="p-1.5 rounded border border-border hover:bg-accent"
                            onClick={() => setEditUser(u)}
                          >
                            <PencilIcon className="h-4 w-4" />
                          </button>
                          <button
                            type="button"
                            className="p-1.5 rounded border border-destructive text-destructive hover:bg-destructive/10"
                            onClick={() => handleDeleteUser(u.id)}
                          >
                            <TrashIcon className="h-4 w-4" />
                          </button>
                        </td>
                      </tr>
                    ),
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {tab === 'notifications' && (
          <div className="space-y-6">
            <div className="bg-card rounded-xl border border-border p-4">
              <h2 className="text-primary font-[Dancing_Script] text-xl mb-3">Nova notificação</h2>
              <div className="grid gap-2 mb-3">
                <input
                  type="text"
                  placeholder="Título"
                  value={formNotif.title}
                  onChange={(e) => setFormNotif((p) => ({ ...p, title: e.target.value }))}
                  className="rounded border border-input bg-background px-3 py-2 text-foreground"
                />
                <input
                  type="text"
                  placeholder="Corpo (opcional)"
                  value={formNotif.body}
                  onChange={(e) => setFormNotif((p) => ({ ...p, body: e.target.value }))}
                  className="rounded border border-input bg-background px-3 py-2 text-foreground"
                />
                <input
                  type="text"
                  placeholder="URL (opcional)"
                  value={formNotif.url}
                  onChange={(e) => setFormNotif((p) => ({ ...p, url: e.target.value }))}
                  className="rounded border border-input bg-background px-3 py-2 text-foreground"
                />
              </div>
              <div className="flex flex-wrap gap-2">
                <button
                  type="button"
                  onClick={handleCreateNotification}
                  disabled={!formNotif.title.trim()}
                  className="px-3 py-2 rounded-lg bg-primary text-primary-foreground text-sm disabled:opacity-50"
                >
                  Criar (só salvar)
                </button>
                <button
                  type="button"
                  onClick={() => formNotif.title && handleSendNow(formNotif.title, formNotif.body || undefined, formNotif.url || undefined)}
                  disabled={sending || !formNotif.title.trim()}
                  className="px-3 py-2 rounded-lg border border-primary text-primary text-sm flex items-center gap-1"
                >
                  <PaperAirplaneIcon className="h-4 w-4" />
                  Enviar agora
                </button>
                <div className="flex items-center gap-2">
                  <input
                    type="datetime-local"
                    value={formNotif.scheduledAt}
                    onChange={(e) => setFormNotif((p) => ({ ...p, scheduledAt: e.target.value }))}
                    className="rounded border border-input bg-background px-3 py-2 text-foreground text-sm"
                  />
                  <button
                    type="button"
                    onClick={handleSchedule}
                    disabled={!formNotif.title.trim() || !formNotif.scheduledAt}
                    className="px-3 py-2 rounded-lg border border-border text-sm flex items-center gap-1"
                  >
                    <CalendarDaysIcon className="h-4 w-4" />
                    Agendar
                  </button>
                </div>
              </div>
            </div>

            <div className="bg-card rounded-xl border border-border overflow-hidden">
              <h2 className="text-primary font-[Dancing_Script] text-xl p-4 border-b border-border flex items-center gap-2">
                <BellIcon className="h-5 w-5" />
                Lista de notificações
              </h2>
              <ul className="divide-y divide-border max-h-[400px] overflow-y-auto">
                {notifications.length === 0 ? (
                  <li className="p-4 text-muted-foreground text-sm">Nenhuma notificação.</li>
                ) : (
                  notifications.map((n) =>
                    editNotif?.id === n.id ? (
                      <li key={n.id} className="p-4 flex flex-col gap-2">
                        <input
                          type="text"
                          defaultValue={editNotif.title}
                          className="rounded border border-input bg-background px-2 py-1"
                          onBlur={(e) => setEditNotif((p) => (p ? { ...p, title: e.target.value } : null))}
                        />
                        <input
                          type="text"
                          defaultValue={editNotif.body}
                          className="rounded border border-input bg-background px-2 py-1"
                          onBlur={(e) => setEditNotif((p) => (p ? { ...p, body: e.target.value } : null))}
                        />
                        <input
                          type="text"
                          defaultValue={editNotif.url}
                          className="rounded border border-input bg-background px-2 py-1"
                          onBlur={(e) => setEditNotif((p) => (p ? { ...p, url: e.target.value } : null))}
                        />
                        <div className="flex gap-2">
                          <button
                            type="button"
                            className="px-2 py-1 rounded bg-primary text-primary-foreground text-sm"
                            onClick={() => editNotif && handleUpdateNotification(n.id, { title: editNotif.title, body: editNotif.body, url: editNotif.url })}
                          >
                            Salvar
                          </button>
                          <button type="button" className="px-2 py-1 rounded border text-sm" onClick={() => setEditNotif(null)}>
                            Cancelar
                          </button>
                        </div>
                      </li>
                    ) : (
                      <li key={n.id} className="p-4 flex justify-between items-start gap-2">
                        <div className="min-w-0">
                          <p className="font-medium text-foreground truncate">{n.title}</p>
                          {n.body && <p className="text-sm text-muted-foreground line-clamp-1">{n.body}</p>}
                          <p className="text-xs text-muted-foreground mt-1">{new Date(n.at).toLocaleString('pt-BR')}</p>
                        </div>
                        <div className="flex gap-1 flex-shrink-0">
                          <button
                            type="button"
                            className="p-1.5 rounded border border-border hover:bg-accent"
                            onClick={() => setEditNotif(n)}
                          >
                            <PencilIcon className="h-4 w-4" />
                          </button>
                          <button
                            type="button"
                            className="p-1.5 rounded border border-primary text-primary hover:bg-primary/10"
                            onClick={() => handleSendNow(n.title, n.body, n.url)}
                            disabled={sending}
                          >
                            <PaperAirplaneIcon className="h-4 w-4" />
                          </button>
                          <button
                            type="button"
                            className="p-1.5 rounded border border-destructive text-destructive hover:bg-destructive/10"
                            onClick={() => handleDeleteNotification(n.id)}
                          >
                            <TrashIcon className="h-4 w-4" />
                          </button>
                        </div>
                      </li>
                    ),
                  )
                )}
              </ul>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
