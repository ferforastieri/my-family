/// <reference lib="webworker" />

declare const self: ServiceWorkerGlobalScope;

// Gera um hash baseado no timestamp atual
const BUILD_TIME = new Date().getTime();
const CACHE_NAME = `love-page-${BUILD_TIME}`;

const urlsToCache = [
  '/',
  '/index.html',
  '/manifest.json',
  '/styles/flower.css',
  '/assets/styles/global.css'
];

// Instalação
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(urlsToCache))
      .then(() => self.skipWaiting())
  );
});

// Ativação e limpeza de caches antigos
self.addEventListener('activate', (event) => {
  event.waitUntil(
    Promise.all([
      self.clients.claim(),
      // Limpa caches antigos
      caches.keys().then(cacheNames => {
        return Promise.all(
          cacheNames
            .filter(cacheName => {
              // Mantém apenas o cache mais recente
              return cacheName.startsWith('love-page-') && cacheName !== CACHE_NAME;
            })
            .map(cacheName => {
              console.log('Removendo cache antigo:', cacheName);
              return caches.delete(cacheName);
            })
        );
      })
    ])
  );
});

// Fetch com estratégia Network First
self.addEventListener('fetch', (event) => {
  event.respondWith(
    fetch(event.request)
      .then(response => {
        // Se a resposta for válida, armazena no cache
        if (response && response.status === 200 && response.type === 'basic') {
          const responseToCache = response.clone();
          caches.open(CACHE_NAME).then(cache => {
            cache.put(event.request, responseToCache);
          });
        }
        return response;
      })
      .catch(() => {
        // Se falhar, tenta buscar do cache
        return caches.match(event.request).then(response => {
          return response || new Response('Offline');
        });
      })
  );
});

// Mensagens
self.addEventListener('message', (event) => {
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
  }
}); 