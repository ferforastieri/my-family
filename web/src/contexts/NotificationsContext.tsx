import { createContext, useContext, useState, useCallback, useEffect, ReactNode } from 'react';
import { apiUrl } from '../config/env';

export interface AppNotification {
  id: number;
  title: string;
  body: string;
  url: string;
  icon?: string | null;
  at: number;
}

interface NotificationsContextType {
  notifications: AppNotification[];
  fetchNotifications: () => Promise<void>;
  clearAll: () => Promise<void>;
}

const NotificationsContext = createContext<NotificationsContextType | undefined>(undefined);

export function NotificationsProvider({ children }: { children: ReactNode }) {
  const [notifications, setNotifications] = useState<AppNotification[]>([]);

  const fetchNotifications = useCallback(async () => {
    try {
      const res = await fetch(`${apiUrl}/notifications`);
      if (res.ok) {
        const data = await res.json();
        setNotifications(Array.isArray(data) ? data : []);
      }
    } catch {
      setNotifications([]);
    }
  }, []);

  const clearAll = useCallback(async () => {
    try {
      await fetch(`${apiUrl}/notifications`, { method: 'DELETE' });
      setNotifications([]);
    } catch {
      //
    }
  }, []);

  useEffect(() => {
    fetchNotifications();
  }, [fetchNotifications]);

  useEffect(() => {
    const handler = () => fetchNotifications();
    if (typeof navigator !== 'undefined' && navigator.serviceWorker) {
      navigator.serviceWorker.addEventListener('message', handler);
      return () => navigator.serviceWorker.removeEventListener('message', handler);
    }
  }, [fetchNotifications]);

  return (
    <NotificationsContext.Provider value={{ notifications, fetchNotifications, clearAll }}>
      {children}
    </NotificationsContext.Provider>
  );
}

export function useNotifications() {
  const ctx = useContext(NotificationsContext);
  if (!ctx) throw new Error('useNotifications must be used within NotificationsProvider');
  return ctx;
}
