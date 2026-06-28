importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');
importScripts('/firebase-config.js');

if (self.firebaseConfig) {
  firebase.initializeApp(self.firebaseConfig);
  const messaging = firebase.messaging();

  messaging.onBackgroundMessage((payload) => {
    const notification = payload.notification || {};
    const data = payload.data || {};
    self.registration.showNotification(
      notification.title || data.title || 'My Family',
      {
        body: notification.body || data.body || '',
        icon: '/icons/Icon-192.png',
        data,
      }
    );
  });
}
