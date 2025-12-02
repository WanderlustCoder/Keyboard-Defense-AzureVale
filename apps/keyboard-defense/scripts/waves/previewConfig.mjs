#!/usr/bin/env node

import http from "node:http";
import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { createServer as createViteServer } from "vite";
import Ajv from "ajv";
import addFormats from "ajv-formats";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const APP_ROOT = path.resolve(__dirname, "../..");
const DEFAULT_CONFIG = path.join(APP_ROOT, "config", "waves.designer.json");
const DEFAULT_SCHEMA = path.join(APP_ROOT, "schemas", "wave-config.schema.json");
const DEFAULT_PORT = 4179;

function parseArgs(argv) {
  const opts = {
    config: DEFAULT_CONFIG,
    schema: DEFAULT_SCHEMA,
    port: DEFAULT_PORT,
    open: false
  };
  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    switch (token) {
      case "--config":
        opts.config = argv[++i] ?? opts.config;
        break;
      case "--schema":
        opts.schema = argv[++i] ?? opts.schema;
        break;
      case "--port":
        opts.port = Number(argv[++i] ?? opts.port);
        break;
      case "--open":
        opts.open = true;
        break;
      case "--help":
        printHelp();
        process.exit(0);
      default:
        if (token.startsWith("-")) {
          throw new Error(`Unknown option ${token}`);
        }
    }
  }
  return opts;
}

function printHelp() {
  console.log(`Wave Config Preview

Usage:
  node scripts/waves/previewConfig.mjs [--config path] [--schema path] [--port 4179] [--open]

Features:
  - Validates config against wave-config.schema.json.
  - Serves a lightweight HTML view that lists waves, hazards, dynamic events, evacuations, and boss flags.
  - Auto-reloads on file save using Vite dev server.
`);
}

async function loadJson(file) {
  const raw = await fs.readFile(file, "utf8");
  return JSON.parse(raw);
}

async function validateConfig(configPath, schemaPath) {
  const ajv = new Ajv({ allErrors: true, strict: false });
  addFormats(ajv);
  const schema = await loadJson(schemaPath);
  const validate = ajv.compile(schema);
  const config = await loadJson(configPath);
  const valid = validate(config);
  if (!valid) {
    const errors = (validate.errors ?? []).map(
      (err) => `${err.instancePath || "/"} ${err.message || "invalid"}`
    );
    throw new Error(`Config failed validation:\n${errors.join("\n")}`);
  }
  return config;
}

function renderHtml(config) {
  const waveRows = (config.waves ?? [])
    .map((wave, idx) => {
      const hazardBadge = wave.hazards?.length ? `<span class="pill hazard">${wave.hazards.length} hazards</span>` : "";
      const dynamicBadge = wave.dynamicEvents?.length
        ? `<span class="pill dynamic">${wave.dynamicEvents.length} dynamic</span>`
        : "";
      const evacBadge = wave.evacuation ? `<span class="pill evac">evac</span>` : "";
      const bossBadge = wave.boss ? `<span class="pill boss">boss</span>` : "";
      const spawns = (wave.spawns ?? [])
        .map(
          (spawn) =>
            `<li><strong>@${spawn.at.toFixed(1)}s</strong> lane ${spawn.lane} x${spawn.count} ${spawn.tierId}${
              spawn.shield ? ` (shield ${spawn.shield})` : ""
            }${spawn.affixes?.length ? ` [${spawn.affixes.join(", ")}]` : ""}</li>`
        )
        .join("");
      const hazards = (wave.hazards ?? [])
        .map(
          (h) =>
            `<li>${h.kind} lane ${h.lane} @${h.time.toFixed(1)}s for ${h.duration.toFixed(
              1
            )}s ${h.fireRateMultiplier ? `(fire ${h.fireRateMultiplier}x)` : ""}</li>`
        )
        .join("");
      const dynamic = (wave.dynamicEvents ?? [])
        .map((d) => `<li>${d.kind} lane ${d.lane} @${d.time.toFixed(1)}s</li>`)
        .join("");
      const evac = wave.evacuation
        ? `<li>Evac lane ${wave.evacuation.lane} @${wave.evacuation.time.toFixed(
            1
          )}s word ${wave.evacuation.word ?? "(auto)"} for ${wave.evacuation.duration}s</li>`
        : "";
      return `<section class="card">
        <header>
          <div>
            <div class="title">Wave ${idx + 1}: ${wave.id}</div>
            <div class="meta">Duration ${wave.duration}s · Bonus ${wave.rewardBonus ?? 0}g</div>
          </div>
          <div class="pills">${hazardBadge}${dynamicBadge}${evacBadge}${bossBadge}</div>
        </header>
        <div class="grid">
          <div><h4>Spawns</h4><ul>${spawns || "<li>None</li>"}</ul></div>
          <div><h4>Hazards</h4><ul>${hazards || "<li>None</li>"}</ul></div>
          <div><h4>Dynamic</h4><ul>${dynamic || "<li>None</li>"}</ul></div>
          <div><h4>Evacuation</h4><ul>${evac || "<li>None</li>"}</ul></div>
        </div>
      </section>`;
    })
    .join("");

  return `<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <title>Wave Preview</title>
  <style>
    body { font-family: 'Segoe UI', sans-serif; margin: 0; background: #0b1220; color: #e2e8f0; padding: 24px; }
    h1 { margin: 0 0 12px; }
    .card { background: #111827; border: 1px solid #1f2937; border-radius: 12px; padding: 16px; margin-bottom: 16px; box-shadow: 0 10px 25px rgba(0,0,0,0.35); }
    header { display: flex; justify-content: space-between; align-items: center; gap: 8px; flex-wrap: wrap; }
    .title { font-size: 18px; font-weight: 700; }
    .meta { font-size: 13px; color: #94a3b8; }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 12px; margin-top: 12px; }
    ul { margin: 4px 0 0; padding-left: 18px; color: #cbd5e1; }
    h4 { margin: 0 0 4px; }
    .pill { display: inline-block; padding: 4px 8px; border-radius: 999px; font-size: 12px; margin-left: 4px; }
    .pill.hazard { background: #0ea5e9; color: #0b1220; }
    .pill.dynamic { background: #f59e0b; color: #0b1220; }
    .pill.evac { background: #22c55e; color: #0b1220; }
    .pill.boss { background: #ec4899; color: #0b1220; }
  </style>
</head>
<body>
  <h1>Wave Preview</h1>
  <p>File: ${path.relative(APP_ROOT, DEFAULT_CONFIG)}</p>
  ${waveRows || "<p>No waves found.</p>"}
</body>
</html>`;
}

async function startServer(configPath, schemaPath, port, open) {
  const vite = await createViteServer({ server: { middlewareMode: true } });

  const handler = async (req, res) => {
    if (!req.url || req.url === "/") {
      try {
        const config = await validateConfig(configPath, schemaPath);
        const html = renderHtml(config);
        res.writeHead(200, { "Content-Type": "text/html" });
        res.end(await vite.transformIndexHtml(req.url, html));
      } catch (error) {
        res.writeHead(500, { "Content-Type": "text/plain" });
        res.end(String(error?.message ?? error));
      }
      return;
    }
    vite.middlewares(req, res, () => {
      res.statusCode = 404;
      res.end("Not found");
    });
  };

  const server = http.createServer(handler);
  await new Promise((resolve) => server.listen(port, resolve));
  const url = `http://localhost:${port}/`;
  console.log(`Wave preview running at ${url}`);
  if (open) {
    const { default: openBrowser } = await import("open");
    openBrowser(url);
  }
}

async function main(argv) {
  const opts = parseArgs(argv);
  await startServer(opts.config, opts.schema, opts.port, opts.open);
}

const isCli =
  typeof process.argv[1] === "string" &&
  fileURLToPath(import.meta.url) === path.resolve(process.argv[1]);

if (isCli) {
  main(process.argv.slice(2)).catch((error) => {
    console.error(error instanceof Error ? error.stack ?? error.message : error);
    process.exit(1);
  });
}

export { startServer, renderHtml, validateConfig };
