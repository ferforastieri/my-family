import { useState, useEffect, useCallback } from 'react';
import { apiUrl } from '../config/env';

function urlBase64ToUint8Array(base64String: string): Uint8Array {
  const padding = '='.repeat((4 - (base64String.length % 4)) % 4);
  const base64 = (base64String + padding).replace(/-/g, '+').replace(/_/g, '/');
  const rawData = atob(base64);
  const outputArray = new Uint8Array(rawData.length);
  for (let i = 0; i < rawData.length; ++i) outputArray[i] = rawData.charCodeAt(i);
  return outputArray;
}

export function usePushNotifications() {
  const [supported, setSupported] = useState(false);
  const [permission, setPermission] = useState<NotificationPermission>('default');
  const [subscribed, setSubscribed] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const ok =
      typeof window !== 'undefined' &&
      'serviceWorker' in navigator &&
      'PushManager' in window &&
      'Notification' in window;
    setSupported(ok);
    if (ok && 'Notification' in window) setPermission(Notification.permission);
  }, []);

  const enable = useCallback(async () => {
    if (!supported) return;
    setLoading(true);
    setError(null);
    try {
      const permissionResult = await Notification.requestPermission();
      setPermission(permissionResult);
      if (permissionResult !== 'granted') {
        setError('Permissão de notificação negada.');
        return;
      }
      const reg = await navigator.serviceWorker.ready;
      const vapidRes = await fetch(`${apiUrl}/notifications/vapid-public`);
      if (!vapidRes.ok) {
        setError('Push não disponível no servidor.');
        return;
      }
      const { publicKey } = await vapidRes.json();
      const sub = await reg.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: urlBase64ToUint8Array(publicKey),
      });
      await fetch(`${apiUrl}/notifications/subscribe`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          subscription: sub.toJSON(),
          userAgent: navigator.userAgent,
        }),
      });
      setSubscribed(true);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Erro ao ativar notificações.');
    } finally {
      setLoading(false);
    }
  }, [supported]);

  const disable = useCallback(async () => {
    if (!supported) return;
    setLoading(true);
    setError(null);
    try {
      const reg = await navigator.serviceWorker.ready;
      const sub = await reg.pushManager.getSubscription();
      if (sub) {
        await fetch(`${apiUrl}/notifications/unsubscribe`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ endpoint: sub.endpoint }),
        });
        await sub.unsubscribe();
      }
      setSubscribed(false);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Erro ao desativar.');
    } finally {
      setLoading(false);
    }
  }, [supported]);

  useEffect(() => {
    if (!supported) return;
    let cancelled = false;
    navigator.serviceWorker.ready.then((reg) => {
      if (cancelled) return;
      reg.pushManager.getSubscription().then((sub) => setSubscribed(!!sub));
    });
    return () => { cancelled = true; };
  }, [supported]);

  return { supported, permission, subscribed, loading, error, enable, disable };
}
