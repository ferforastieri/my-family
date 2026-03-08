/// <reference lib="webworker" />

import { precacheAndRoute } from 'workbox-precaching';

declare const self: ServiceWorkerGlobalScope & {
  __WB_MANIFEST: Array<{ url: string; revision?: string }>;
};

precacheAndRoute(self.__WB_MANIFEST);

self.addEventListener('push', (event: PushEvent) => {
  if (!event.data) return;
  let payload: { title?: string; body?: string; url?: string; icon?: string } = {};
  try {
    payload = event.data.json();
  } catch {
    payload = { title: event.data.text() || 'Nossa Família' };
  }
  const title = payload.title ?? 'Nossa Família';
  const options: NotificationOptions = {
    body: payload.body ?? '',
    icon: payload.icon ?? '/favicon-192.png',
    badge: '/favicon-72.png',
    data: { url: payload.url ?? '/' },
    tag: 'lovepage-push',
    renotify: true,
  };
  const msg = { title, body: payload.body ?? '', url: payload.url ?? '/', icon: payload.icon, at: Date.now() };
  event.waitUntil(
    self.registration.showNotification(title, options).then(() =>
      self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clients) => {
        clients.forEach((c) => c.postMessage?.({ type: 'PUSH_NOTIFICATION', payload: msg }));
      })
    )
  );
});

self.addEventListener('notificationclick', (event: NotificationEvent) => {
  event.notification.close();
  const url = (event.notification.data?.url as string) || '/';
  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if (client.url && 'focus' in client) {
          client.navigate(url);
          return client.focus();
        }
      }
      if (self.clients.openWindow) return self.clients.openWindow(url);
    })
  );
});

self.skipWaiting();
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (e) => e.waitUntil(self.clients.claim()));
