// Guarda la app para que abra rápido y se pueda instalar.
// Los archivos propios se piden primero a la red (así las actualizaciones llegan solas)
// y solo se usa la copia guardada si no hay conexión. Los datos de Supabase nunca se guardan aquí.
const CACHE = 'semana-v1';
const SHELL = ['./', 'index.html', 'config.js', 'manifest.webmanifest', 'icons/icon-192.png', 'icons/icon-512.png'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(SHELL)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  const own = url.origin === self.location.origin;
  const lib = url.hostname === 'cdn.jsdelivr.net' || url.hostname.endsWith('fonts.googleapis.com') || url.hostname.endsWith('fonts.gstatic.com');
  if (!own && !lib) return;

  e.respondWith(
    fetch(req)
      .then(res => {
        if (res.ok || res.type === 'opaque') {
          const copy = res.clone();
          caches.open(CACHE).then(c => c.put(req, copy));
        }
        return res;
      })
      .catch(() => caches.match(req).then(r => r || (req.mode === 'navigate' ? caches.match('./') : Response.error())))
  );
});
