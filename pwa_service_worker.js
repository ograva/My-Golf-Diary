// Release PWA worker for My Golf Diary.
//
// App shells are served from Cache Storage so a published round still opens
// offline. app_build.json is always read from the network. The page compares
// that id with the id compiled into the running build and, after the golfer
// agrees, posts APPLY_UPDATE. This worker then drops the cache and opens the
// new build. It does not reload a page on its own.

const CACHE_NAME = 'golf-diary-shell-v1';

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;

  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;
  if (isBuildManifest(url)) {
    event.respondWith(fetch(request, { cache: 'no-store' }));
    return;
  }

  event.respondWith(cacheFirst(request));
});

self.addEventListener('message', (event) => {
  const data = event.data;
  if (!data || data.type !== 'APPLY_UPDATE') return;
  event.waitUntil(applyUpdate());
});

function isBuildManifest(url) {
  return url.pathname.endsWith('/app_build.json');
}

async function cacheFirst(request) {
  const cache = await caches.open(CACHE_NAME);
  const cached = await cache.match(request);
  if (cached) return cached;

  const response = await fetch(request);
  if (response && response.ok && response.type === 'basic') {
    try {
      await cache.put(request, response.clone());
    } catch (error) {
      // Navigation and opaque responses are not always cacheable.
    }
  }
  return response;
}

async function applyUpdate() {
  const keys = await caches.keys();
  await Promise.all(keys.map((key) => caches.delete(key)));

  const clients = await self.clients.matchAll({
    type: 'window',
    includeUncontrolled: true,
  });
  await Promise.all(clients.map((client) => openFresh(client)));
}

async function openFresh(client) {
  const url = new URL(client.url);
  url.searchParams.set('updated', String(Date.now()));
  if (typeof client.navigate === 'function') {
    try {
      await client.navigate(url.toString());
      return;
    } catch (error) {
      // Fall through and ask the page to reload itself.
    }
  }
  client.postMessage({ type: 'RELOAD', url: url.toString() });
}
