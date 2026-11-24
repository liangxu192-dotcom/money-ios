/* Money · 离线缓存
   页面（导航）走 network-first，避免更新后还看到旧版；
   图片/图标走 cache-first。
   改版本号可以让老缓存整体失效。 */
const CACHE = 'money-v2';
const ASSETS = [
  './manifest.webmanifest',
  './icons/icon-180.png',
  './icons/icon-192.png',
  './icons/icon-512.png',
  './icons/icon-1024.png',
  './img/char-spongebob.jpg',
  './img/char-patrick.jpg',
  './img/char-squidward.jpg',
  './img/char-sandy.jpg',
  './img/char-krabs.jpg',
  './img/char-plankton.jpg',
  './img/crew.jpg'
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE)
      .then(cache => cache.addAll(ASSETS))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(key => key !== CACHE).map(key => caches.delete(key))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', event => {
  const request = event.request;
  if (request.method !== 'GET' || !request.url.startsWith(self.location.origin)) return;

  // 页面和 JSON：先网络，失败再读缓存（离线也能打开）
  if (request.mode === 'navigate' || request.destination === 'document') {
    event.respondWith(
      fetch(request).then(response => {
        const copy = response.clone();
        caches.open(CACHE).then(cache => cache.put('./index.html', copy)).catch(() => {});
        return response;
      }).catch(() => caches.match('./index.html'))
    );
    return;
  }

  event.respondWith(
    caches.match(request).then(hit => {
      if (hit) return hit;
      return fetch(request).then(response => {
        const copy = response.clone();
        caches.open(CACHE).then(cache => cache.put(request, copy)).catch(() => {});
        return response;
      });
    })
  );
});
