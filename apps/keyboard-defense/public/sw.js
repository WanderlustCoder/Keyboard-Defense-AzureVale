const CACHE_PREFIX = "keyboard-defense-precache";
const CACHE_VERSION = "v2";
const CACHE_NAME = `${CACHE_PREFIX}-${CACHE_VERSION}`;
const CACHE_MANIFEST_URL = "pwa-cache-manifest.json";

const CORE_URLS = ["index.html", "styles.css", "dist/src/index.js"];
const NAV_FALLBACK_URL = "index.html";

function normalizeUrl(value) {
  return String(value ?? "")
    .trim()
    .replace(/^[./]+/, "");
}

async function loadManifestUrls() {
  try {
    const response = await fetch(CACHE_MANIFEST_URL, { cache: "no-store" });
    if (!response.ok) {
      return [];
    }
    const json = await response.json();
    const urls = Array.isArray(json) ? json : json?.urls;
    if (!Array.isArray(urls)) {
      return [];
    }
    return urls
      .map((entry) => normalizeUrl(entry))
      .filter(Boolean);
  } catch {
    return [];
  }
}

async function precache() {
  const cache = await caches.open(CACHE_NAME);
  const urls = new Set(CORE_URLS);
  for (const entry of await loadManifestUrls()) {
    urls.add(entry);
  }
  await cache.addAll([...urls]);
}

self.addEventListener("install", (event) => {
  event.waitUntil(
    (async () => {
      await precache();
      await self.skipWaiting();
    })()
  );
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    (async () => {
      const keys = await caches.keys();
      await Promise.all(
        keys
          .filter((key) => key.startsWith(CACHE_PREFIX) && key !== CACHE_NAME)
          .map((key) => caches.delete(key))
      );
      await self.clients.claim();
    })()
  );
});

async function cacheFirst(request) {
  const cache = await caches.open(CACHE_NAME);
  const cached = await cache.match(request);
  if (cached) return cached;
  const response = await fetch(request);
  if (response.ok) {
    cache.put(request, response.clone());
  }
  return response;
}

async function networkFirst(request) {
  const cache = await caches.open(CACHE_NAME);
  try {
    const response = await fetch(request);
    if (response.ok) {
      cache.put(request, response.clone());
    }
    return response;
  } catch {
    const cached = await cache.match(request);
    if (cached) return cached;
    return new Response("Offline", {
      status: 503,
      headers: { "content-type": "text/plain; charset=utf-8" }
    });
  }
}

async function navigationFallback(request) {
  try {
    return await fetch(request);
  } catch {
    const cache = await caches.open(CACHE_NAME);
    const cached = await cache.match(NAV_FALLBACK_URL);
    if (cached) return cached;
    return new Response("Offline", {
      status: 503,
      headers: { "content-type": "text/plain; charset=utf-8" }
    });
  }
}

self.addEventListener("fetch", (event) => {
  const request = event.request;
  if (!request || request.method !== "GET") return;
  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;
  const path = normalizeUrl(url.pathname);

  if (request.mode === "navigate") {
    event.respondWith(navigationFallback(request));
    return;
  }

  if (
    path === NAV_FALLBACK_URL ||
    path === "styles.css" ||
    path === CACHE_MANIFEST_URL ||
    path.startsWith("dist/")
  ) {
    event.respondWith(networkFirst(request));
    return;
  }

  event.respondWith(cacheFirst(request));
});
