(function () {
  function urlBase64ToUint8Array(base64String) {
    var padding = '='.repeat((4 - (base64String.length % 4)) % 4);
    var base64 = (base64String + padding).replace(/-/g, '+').replace(/_/g, '/');
    var raw = atob(base64);
    var output = new Uint8Array(raw.length);
    for (var i = 0; i < raw.length; i += 1) output[i] = raw.charCodeAt(i);
    return output;
  }

  window.enableWebPush = async function (publicKey) {
    try {
      if (
        !publicKey ||
        !('serviceWorker' in navigator) ||
        !('PushManager' in window) ||
        !('Notification' in window)
      ) {
        return null;
      }
      var permission = await Notification.requestPermission();
      if (permission !== 'granted') return null;
      var registration = await navigator.serviceWorker.register('/web-push-sw.js');
      await navigator.serviceWorker.ready;
      var existing = await registration.pushManager.getSubscription();
      var subscription =
        existing ||
        (await registration.pushManager.subscribe({
          userVisibleOnly: true,
          applicationServerKey: urlBase64ToUint8Array(publicKey),
        }));
      return subscription.toJSON();
    } catch (error) {
      console.warn('Web push indisponível', error);
      return null;
    }
  };
})();
