import { describe, expect, test } from "vitest";
import { existsSync, readFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { parseHTML } from "linkedom";

import { buildPwaCacheManifest } from "../scripts/pwaCacheManifest.mjs";

const readJson = (url) => JSON.parse(readFileSync(url, "utf8"));

describe("offline / PWA cache verification", () => {
  test("static assets required for offline mode exist", () => {
    expect(existsSync(new URL("../public/sw.js", import.meta.url))).toBe(true);
    expect(existsSync(new URL("../public/manifest.webmanifest", import.meta.url))).toBe(true);
    expect(existsSync(new URL("../public/pwa-cache-manifest.json", import.meta.url))).toBe(true);
  });

  test("index.html registers service worker and references manifest", () => {
    const html = readFileSync(new URL("../public/index.html", import.meta.url), "utf8");
    const { document } = parseHTML(html).window;

    const manifestLink = document.querySelector('link[rel="manifest"]');
    expect(manifestLink?.getAttribute("href")).toMatch(/manifest\.webmanifest$/);
    expect(html).toContain("navigator.serviceWorker.register");
    expect(html).toContain("sw.js");
  });

  test("manifest.webmanifest contains core PWA fields", () => {
    const manifest = readJson(new URL("../public/manifest.webmanifest", import.meta.url));
    expect(manifest.name).toBeTruthy();
    expect(manifest.short_name).toBeTruthy();
    expect(manifest.start_url).toBeTruthy();
    expect(manifest.display).toBeTruthy();
  });

  test("service worker precaches the generated manifest entries", async () => {
    const swSource = readFileSync(new URL("../public/sw.js", import.meta.url), "utf8");
    expect(swSource).toContain("pwa-cache-manifest.json");
    expect(swSource).toContain("caches.open");
    expect(swSource).toContain('addEventListener("fetch"');

    const computed = await buildPwaCacheManifest();
    expect(computed.urls.length).toBeGreaterThan(0);

    const cached = readJson(new URL("../public/pwa-cache-manifest.json", import.meta.url));
    expect(Array.isArray(cached.urls)).toBe(true);

    expect(cached.urls).toContain("index.html");
    expect(cached.urls).toContain("styles.css");
    expect(cached.urls).toContain("dist/src/index.js");

    expect(cached).toEqual(computed);

    const publicDir = fileURLToPath(new URL("../public/", import.meta.url));
    const missing = cached.urls
      .filter((entry) => typeof entry === "string")
      .filter((entry) => !existsSync(path.join(publicDir, entry.split("/").join(path.sep))));
    expect(missing).toEqual([]);
  });
});
