self.addEventListener('push', function (event) {
  var payload = {};
  try {
    payload = event.data ? event.data.json() : {};
  } catch (_) {
    payload = {};
  }
  var data = payload.data || payload;
  var title = data.title || 'Sião';
  var options = {
    body: data.body || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: Object.assign({ url: data.url || '/' }, data),
  };
  event.waitUntil(self.registration.showNotification(title, options));
});

self.addEventListener('notificationclick', function (event) {
  event.notification.close();
  var url =
    (event.notification.data && event.notification.data.url) || '/';
  event.waitUntil(
    (async function () {
      var windows = await clients.matchAll({
        type: 'window',
        includeUncontrolled: true,
      });
      for (var i = 0; i < windows.length; i += 1) {
        var client = windows[i];
        if ('focus' in client) {
          try {
            await client.navigate(url);
          } catch (_) {}
          return client.focus();
        }
      }
      return clients.openWindow(url);
    })(),
  );
});
