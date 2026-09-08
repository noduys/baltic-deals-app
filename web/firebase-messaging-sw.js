importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBT0I0mNsqKxl4k8fB5qVjfLVHYQX16nKk',
  appId: '1:1034232946967:web:f6d2f6ece68f8a46999752',
  messagingSenderId: '1034232946967',
  projectId: 'baltic-deals-app',
  authDomain: 'baltic-deals-app.firebaseapp.com',
  storageBucket: 'baltic-deals-app.firebasestorage.app',
  measurementId: 'G-G6PWB0XW97',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log(
    '[firebase-messaging-sw.js] Background message received:',
    payload
  );

  const title = payload.notification?.title || 'Baltic Deals';
  const options = {
    body: payload.notification?.body || '',
  };

  return self.registration.showNotification(title, options);
});

self.addEventListener('push', (event) => {
  event.waitUntil(
    self.registration.showNotification('Baltic Deals SW test', {
      body: 'Service Worker received push event',
    })
  );
});