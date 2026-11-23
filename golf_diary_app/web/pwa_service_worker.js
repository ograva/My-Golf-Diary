// Release PWA worker for My Golf Diary.
//
// Install precaches the app shell (local CanvasKit, SQLite wasm, and the
// GitHub Pages start URL, which is the scope and not index.html). Later
// opens are served from that cache with no network. app_build.json stays
// network-only and is aborted if the radio hangs. APPLY_UPDATE reloads onto
// the precached shell; it does not drop the cache the next open needs.

const CACHE_NAME = 'golf-diary-shell-v2';
const MANIFEST = 'precache_manifest.json';
const BUILD_TIMEOUT_MS = 4000;

const CRITICAL_SUFFIXES = [
  '/index.html',
  '/flutter_bootstrap.js',
  '/flutter.js',
  '/main.dart.js',
  '/manifest.json',
  '/sqlite3.wasm',
  '/sqflite_sw.js',
  '/canvaskit.js',
  '/canvaskit.wasm',
];

self.addEventListener('install', (event) => {
  event.waitUntil(installShell());
});

self.addEventListener('activate', (event) => {
  event.waitUntil(activateShell());
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;

  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;

  if (isBuildManifest(url)) {
    event.respondWith(networkOnlyBounded(request));
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

function isNavigation(request) {
  return request.mode === 'navigate' || request.destination === 'document';
}

function isCriticalPath(pathname) {
  return CRITICAL_SUFFIXES.some((suffix) => pathname.endsWith(suffix));
}

async function installShell() {
  await precacheShell();
  await self.skipWaiting();
}

async function activateShell() {
  const keys = await caches.keys();
  await Promise.all(
    keys.filter((key) => key !== CACHE_NAME).map((key) => caches.delete(key)),
  );
  await self.clients.claim();
}

async function precacheShell() {
  const cache = await caches.open(CACHE_NAME);
  const manifestUrl = new URL(MANIFEST, self.registration.scope);
  const manifestResponse = await fetch(manifestUrl, { cache: 'reload' });
  if (!manifestResponse.ok) {
    throw new Error('precache manifest ' + manifestResponse.status);
  }
  const body = await manifestResponse.json();
  const urls = Array.isArray(body.urls) ? body.urls : [];
  if (!urls.length) throw new Error('precache manifest was empty');

  let next = 0;
  async function worker() {
    while (next < urls.length) {
      const path = urls[next];
      next += 1;
      await cacheOne(cache, path);
    }
  }
  const workers = [];
  const pool = Math.min(6, urls.length);
  for (let i = 0; i < pool; i += 1) workers.push(worker());
  await Promise.all(workers);

  await aliasAppShell(cache);
  await assertCritical(cache);
}

async function cacheOne(cache, path) {
  if (typeof path !== 'string' || !path || path.indexOf('..') !== -1) return;
  const url = new URL(path, self.registration.scope);
  if (url.origin !== self.location.origin) return;
  const critical = isCriticalPath(url.pathname);
  try {
    const response = await fetch(url, { cache: 'reload' });
    if (!response.ok) {
      if (critical) throw new Error('precache ' + path + ' ' + response.status);
      return;
    }
    await putStored(cache, url.toString(), response);
  } catch (error) {
    if (critical) throw error;
  }
}

async function putStored(cache, url, response) {
  const headers = new Headers(response.headers);
  // fetch() already decoded the body. Leaving these on the stored response
  // makes the browser decode it a second time, which breaks the shell.
  headers.delete('content-encoding');
  headers.delete('content-length');
  const stored = new Response(await response.blob(), {
    status: response.status,
    statusText: response.statusText,
    headers: headers,
  });
  await cache.put(url, stored);
}

async function aliasAppShell(cache) {
  const indexUrl = new URL('index.html', self.registration.scope).toString();
  const index = await cache.match(indexUrl);
  if (!index) throw new Error('index.html was not precached');
  const scopeUrl = new URL(self.registration.scope);
  await putStored(cache, scopeUrl.toString(), index.clone());
  if (scopeUrl.pathname.length > 1 && scopeUrl.pathname.endsWith('/')) {
    const bare = new URL(scopeUrl.toString());
    bare.pathname = scopeUrl.pathname.replace(/\/$/, '');
    await putStored(cache, bare.toString(), index.clone());
  }
}

async function assertCritical(cache) {
  const keys = await cache.keys();
  const paths = keys.map((request) => new URL(request.url).pathname);
  for (const suffix of CRITICAL_SUFFIXES) {
    if (!paths.some((path) => path.endsWith(suffix))) {
      throw new Error('missing precache ' + suffix);
    }
  }
}

function cacheUrlFor(request) {
  const url = new URL(request.url);
  url.search = '';
  url.hash = '';
  return url.toString();
}

async function matchCached(cache, request) {
  const direct = await cache.match(cacheUrlFor(request));
  if (direct) return direct;
  if (!isNavigation(request)) return null;

  const path = new URL(request.url).pathname;
  const scopePath = new URL(self.registration.scope).pathname;
  const bare = scopePath.replace(/\/$/, '');
  const shellNavigation =
    path === scopePath ||
    path === bare ||
    path.endsWith('/') ||
    path.endsWith('/index.html');
  if (!shellNavigation) return null;
  return cache.match(new URL('index.html', self.registration.scope).toString());
}

async function cacheFirst(request) {
  const cache = await caches.open(CACHE_NAME);
  const cached = await matchCached(cache, request);
  if (cached) return cached;

  try {
    const response = await fetch(request);
    if (response && response.ok && response.type === 'basic') {
      // Store a GET key. cache.put rejects a navigation request (mode
      // "navigate"), which used to leave the document out of the cache.
      await putStored(cache, cacheUrlFor(request), response.clone());
    }
    return response;
  } catch (error) {
    if (isNavigation(request)) {
      const shell = await cache.match(
        new URL('index.html', self.registration.scope).toString(),
      );
      if (shell) return shell;
    }
    throw error;
  }
}

function fetchBounded(request, ms) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), ms);
  return fetch(request, { cache: 'no-store', signal: controller.signal }).finally(
    () => clearTimeout(timer),
  );
}

async function networkOnlyBounded(request) {
  try {
    return await fetchBounded(request, BUILD_TIMEOUT_MS);
  } catch (error) {
    return new Response('{"buildId":""}', {
      status: 503,
      headers: {
        'content-type': 'application/json',
        'cache-control': 'no-store',
      },
    });
  }
}

async function applyUpdate() {
  // app_build.json is network-only; the shell (main.dart.js) was cache-first.
  // Reloading without reprecache left APP_BUILD_ID stale and re-opened the dialog.
  try {
    await precacheShell();
  } catch (error) {
    console.warn('Golf Diary apply update: shell refresh failed', error);
  }
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
