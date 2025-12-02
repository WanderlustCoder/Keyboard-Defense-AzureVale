#!/usr/bin/env node

import http from "node:http";
import fs from "node:fs/promises";
import { watch } from "node:fs";
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
const EVENT_TYPES = ["spawns", "hazards", "dynamic", "evac", "boss"];

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
        break;
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
  - Validates config against wave-config.schema.json with Ajv format support.
  - Renders a designer-friendly HTML preview with timelines, lane filters, and event toggles.
  - Live reloads the page when the config or schema changes (SSE).
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

function summarizeConfig(config = {}) {
  const lanes = new Set();
  const summary = {
    waves: 0,
    spawns: 0,
    hazards: 0,
    dynamic: 0,
    evac: 0,
    boss: 0,
    maxDuration: 0,
    featureToggles: config.featureToggles ?? {}
  };

  for (const wave of config.waves ?? []) {
    summary.waves += 1;
    summary.spawns += wave.spawns?.length ?? 0;
    summary.hazards += wave.hazards?.length ?? 0;
    summary.dynamic += wave.dynamicEvents?.length ?? 0;
    summary.evac += wave.evacuation ? 1 : 0;
    summary.boss += wave.boss ? 1 : 0;
    summary.maxDuration = Math.max(summary.maxDuration, Number(wave.duration) || 0);

    for (const spawn of wave.spawns ?? []) {
      if (Number.isFinite(spawn.lane)) lanes.add(String(spawn.lane));
    }
    for (const hazard of wave.hazards ?? []) {
      if (Number.isFinite(hazard.lane)) lanes.add(String(hazard.lane));
    }
    for (const dyn of wave.dynamicEvents ?? []) {
      if (Number.isFinite(dyn.lane)) lanes.add(String(dyn.lane));
    }
    if (Number.isFinite(wave.evacuation?.lane)) lanes.add(String(wave.evacuation.lane));
  }

  return { ...summary, lanes: [...lanes].sort((a, b) => Number(a) - Number(b)) };
}

function waveSearchTokens(wave) {
  const tokens = [wave.id ?? ""];
  for (const spawn of wave.spawns ?? []) {
    tokens.push(spawn.tierId ?? "", String(spawn.lane ?? ""));
    for (const affix of spawn.affixes ?? []) tokens.push(affix);
  }
  for (const hazard of wave.hazards ?? []) tokens.push(hazard.kind ?? "", String(hazard.lane ?? ""));
  for (const dyn of wave.dynamicEvents ?? []) tokens.push(dyn.kind ?? "", String(dyn.lane ?? ""));
  if (wave.evacuation) {
    tokens.push("evac", String(wave.evacuation.lane ?? ""), wave.evacuation.word ?? "");
  }
  if (wave.boss) tokens.push("boss");
  return tokens
    .filter(Boolean)
    .map((t) => String(t).toLowerCase())
    .join(" ");
}

function renderTimeline(wave) {
  const duration = Number(wave.duration) || 0;
  const events = [];
  const timelineWidth = duration > 0 ? duration : 1;

  for (const spawn of wave.spawns ?? []) {
    events.push({
      type: "spawns",
      at: Number(spawn.at) || 0,
      duration: spawn.cadence ? Number(spawn.cadence) : 0,
      label: `${spawn.tierId ?? "enemy"} x${spawn.count ?? 1} (lane ${spawn.lane ?? "?"})`
    });
  }
  for (const hazard of wave.hazards ?? []) {
    events.push({
      type: "hazards",
      at: Number(hazard.time) || 0,
      duration: Number(hazard.duration) || 0,
      label: `${hazard.kind ?? "hazard"} lane ${hazard.lane ?? "?"}`
    });
  }
  for (const dyn of wave.dynamicEvents ?? []) {
    events.push({
      type: "dynamic",
      at: Number(dyn.time) || 0,
      duration: 3,
      label: `${dyn.kind ?? "dynamic"} lane ${dyn.lane ?? "?"}`
    });
  }
  if (wave.evacuation) {
    events.push({
      type: "evac",
      at: Number(wave.evacuation.time) || 0,
      duration: Number(wave.evacuation.duration) || 0,
      label: `Evac lane ${wave.evacuation.lane ?? "?"}`
    });
  }
  if (wave.boss) {
    events.push({ type: "boss", at: 0, duration: duration || 1, label: "Boss lane" });
  }

  if (events.length === 0) {
    return '<div class="timeline empty">No timeline events</div>';
  }

  const chips = events
    .map((event) => {
      const startPct = Math.max(0, Math.min(100, (event.at / timelineWidth) * 100));
      const widthPct = Math.max(2, Math.min(100, (event.duration / timelineWidth) * 100 || 4));
      return `<div class="event ${event.type}" data-type="${event.type}" style="left:${startPct}%;width:${widthPct}%;" title="${event.label.replace(/"/g, "'")}"></div>`;
    })
    .join("");

  return `<div class="timeline">${chips}</div>`;
}

function renderList(title, items, type) {
  const list = items.length
    ? items
        .map((item) => `<li class="item ${type}" data-section-type="${type}">${item}</li>`)
        .join("")
    : `<li class="muted ${type}" data-section-type="${type}">None</li>`;
  return `<div class="list" data-section-type="${type}"><h4>${title}</h4><ul>${list}</ul></div>`;
}

function renderWaveCard(wave, index) {
  const hazardBadge = wave.hazards?.length
    ? `<span class="pill hazard">${wave.hazards.length} hazards</span>`
    : "";
  const dynamicBadge = wave.dynamicEvents?.length
    ? `<span class="pill dynamic">${wave.dynamicEvents.length} dynamic</span>`
    : "";
  const evacBadge = wave.evacuation ? `<span class="pill evac">evac</span>` : "";
  const bossBadge = wave.boss ? `<span class="pill boss">boss</span>` : "";

  const spawnList = (wave.spawns ?? []).map((spawn) => {
    const affixText = spawn.affixes?.length ? ` [${spawn.affixes.join(", ")}]` : "";
    const shieldText = spawn.shield ? ` (shield ${spawn.shield})` : "";
    const cadenceText = spawn.cadence ? `, ${spawn.cadence}s cadence` : "";
    return `<strong>@${(spawn.at ?? 0).toFixed(1)}s</strong> lane ${spawn.lane ?? "?"} x${spawn.count ?? 1} ${spawn.tierId ?? "enemy"}${shieldText}${cadenceText}${affixText}`;
  });

  const hazardList = (wave.hazards ?? []).map((h) => {
    const rate = h.fireRateMultiplier ? `, fire ${h.fireRateMultiplier}x` : "";
    return `${h.kind ?? "hazard"} lane ${h.lane ?? "?"} @${(h.time ?? 0).toFixed(1)}s for ${(h.duration ?? 0).toFixed(1)}s${rate}`;
  });
  const dynamicList = (wave.dynamicEvents ?? []).map(
    (d) => `${d.kind ?? "dynamic"} lane ${d.lane ?? "?"} @${(d.time ?? 0).toFixed(1)}s`
  );
  const evacList = wave.evacuation
    ? [
        `Lane ${wave.evacuation.lane ?? "?"} @${(wave.evacuation.time ?? 0).toFixed(1)}s word ${
          wave.evacuation.word ?? "(auto)"
        } for ${wave.evacuation.duration ?? 0}s`
      ]
    : [];

  const lanes = new Set();
  for (const spawn of wave.spawns ?? []) lanes.add(String(spawn.lane));
  for (const hazard of wave.hazards ?? []) lanes.add(String(hazard.lane));
  for (const dyn of wave.dynamicEvents ?? []) lanes.add(String(dyn.lane));
  if (Number.isFinite(wave.evacuation?.lane)) lanes.add(String(wave.evacuation.lane));
  const laneAttr = [...lanes].filter(Boolean).join(",");
  const tags = EVENT_TYPES.filter((type) => {
    switch (type) {
      case "spawns":
        return (wave.spawns ?? []).length > 0;
      case "hazards":
        return (wave.hazards ?? []).length > 0;
      case "dynamic":
        return (wave.dynamicEvents ?? []).length > 0;
      case "evac":
        return Boolean(wave.evacuation);
      case "boss":
        return Boolean(wave.boss);
      default:
        return false;
    }
  }).join(",");

  return `<section class="card" data-wave data-wave-id="${wave.id ?? `wave-${index + 1}`}" data-lanes="${laneAttr}" data-tags="${tags}" data-search="${waveSearchTokens(wave)}">
    <header>
      <div>
        <div class="title">Wave ${index + 1}: ${wave.id}</div>
        <div class="meta">Duration ${wave.duration}s | Bonus ${wave.rewardBonus ?? 0}g</div>
      </div>
      <div class="pills">${hazardBadge}${dynamicBadge}${evacBadge}${bossBadge}</div>
    </header>
    ${renderTimeline(wave)}
    <div class="grid">
      ${renderList("Spawns", spawnList, "spawns")}
      ${renderList("Hazards", hazardList, "hazards")}
      ${renderList("Dynamic", dynamicList, "dynamic")}
      ${renderList("Evacuation", evacList, "evac")}
    </div>
  </section>`;
}

function renderFeatureToggles(featureToggles) {
  const entries = Object.entries(featureToggles ?? {});
  if (!entries.length) return `<div class="muted">No feature toggles defined.</div>`;
  const rows = entries
    .map(
      ([key, value]) =>
        `<div class="toggle"><span class="toggle-key">${key}</span><span class="toggle-value ${
          value ? "on" : "off"
        }">${value ? "on" : "off"}</span></div>`
    )
    .join("");
  return `<div class="toggles">${rows}</div>`;
}

function renderFilters(summary) {
  const lanes = summary.lanes?.length
    ? summary.lanes
        .map(
          (lane) =>
            `<label class="chip"><input type="checkbox" data-filter-lane="${lane}" />Lane ${lane}</label>`
        )
        .join("")
    : `<span class="muted">No lanes found</span>`;

  const typeFilters = EVENT_TYPES.map(
    (type) =>
      `<label class="chip"><input type="checkbox" data-type-toggle="${type}" checked />${type}</label>`
  ).join("");

  return `<div class="filters">
    <div class="filter-row">
      <input type="search" data-search placeholder="Search wave id, lane, tier, affix, word" />
      <span class="hint">Live reloads when ${path.basename(summary.configPath || "") || "config"} changes.</span>
    </div>
    <div class="filter-row">
      <div class="filter-block"><div class="filter-title">Lanes</div><div class="filter-chips">${lanes}</div></div>
      <div class="filter-block"><div class="filter-title">Event types</div><div class="filter-chips">${typeFilters}</div></div>
    </div>
  </div>`;
}

function renderSummary(summary) {
  const items = [
    { label: "Waves", value: summary.waves },
    { label: "Spawns", value: summary.spawns },
    { label: "Hazards", value: summary.hazards },
    { label: "Dynamic", value: summary.dynamic },
    { label: "Evac", value: summary.evac },
    { label: "Boss", value: summary.boss }
  ]
    .map(
      (item) =>
        `<div class="stat"><div class="stat-label">${item.label}</div><div class="stat-value">${item.value}</div></div>`
    )
    .join("");

  return `<div class="stats">${items}</div>`;
}

function renderHtml({ config, summary, paths, error }) {
  const bodyContent =
    error && !config
      ? `<div class="error">
          <div class="error-title">Validation failed</div>
          <pre>${String(error.message ?? error)}</pre>
          <p>Fix the config or schema file and the page will auto-refresh.</p>
        </div>`
      : (config.waves ?? []).map(renderWaveCard).join("") || "<p data-empty>No waves found.</p>";

  const cards = config?.waves?.length
    ? '<p data-empty class="muted" style="display:none;">No waves match your filters.</p>'
    : "";

  return `<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <title>Wave Preview</title>
  <style>
    :root { color-scheme: dark; }
    body { font-family: 'Segoe UI', Arial, sans-serif; margin: 0; background: #0b1220; color: #e2e8f0; padding: 24px; }
    h1 { margin: 0 0 8px; }
    p { margin: 0 0 12px; }
    code { background: #0f172a; padding: 2px 6px; border-radius: 6px; color: #cbd5e1; }
    .card { background: #111827; border: 1px solid #1f2937; border-radius: 12px; padding: 16px; margin-bottom: 16px; box-shadow: 0 10px 25px rgba(0,0,0,0.35); }
    header.card-header { display: flex; justify-content: space-between; align-items: center; gap: 8px; flex-wrap: wrap; margin-bottom: 12px; }
    section.card header { display: flex; justify-content: space-between; align-items: center; gap: 8px; flex-wrap: wrap; }
    .title { font-size: 18px; font-weight: 700; }
    .meta { font-size: 13px; color: #94a3b8; }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 12px; margin-top: 12px; }
    ul { margin: 4px 0 0; padding-left: 18px; color: #cbd5e1; }
    h4 { margin: 0 0 4px; }
    .pill { display: inline-block; padding: 4px 8px; border-radius: 999px; font-size: 12px; margin-left: 4px; text-transform: capitalize; }
    .pill.hazard { background: #0ea5e9; color: #0b1220; }
    .pill.dynamic { background: #f59e0b; color: #0b1220; }
    .pill.evac { background: #22c55e; color: #0b1220; }
    .pill.boss { background: #ec4899; color: #0b1220; }
    .pill.spawns { background: #22d3ee; color: #0b1220; }
    .timeline { position: relative; margin-top: 12px; height: 14px; background: #0f172a; border-radius: 8px; overflow: hidden; border: 1px solid #1f2937; }
    .timeline.empty { height: auto; padding: 12px; color: #94a3b8; border-style: dashed; }
    .event { position: absolute; top: 0; bottom: 0; border-radius: 8px; opacity: 0.9; }
    .event.spawns { background: #22d3ee; }
    .event.hazards { background: #0ea5e9; }
    .event.dynamic { background: #f59e0b; }
    .event.evac { background: #22c55e; }
    .event.boss { background: #ec4899; }
    .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(120px, 1fr)); gap: 12px; margin: 12px 0 8px; }
    .stat { background: #0f172a; border: 1px solid #1f2937; border-radius: 10px; padding: 10px; }
    .stat-label { font-size: 12px; color: #94a3b8; }
    .stat-value { font-size: 20px; font-weight: 700; }
    .filters { background: #0f172a; border: 1px solid #1f2937; border-radius: 12px; padding: 12px; margin-bottom: 14px; }
    .filter-row { display: flex; gap: 12px; flex-wrap: wrap; align-items: center; margin-bottom: 10px; }
    .filter-row:last-child { margin-bottom: 0; }
    .filter-block { display: flex; flex-direction: column; gap: 4px; }
    .filter-title { font-weight: 600; color: #cbd5e1; }
    .filter-chips { display: flex; flex-wrap: wrap; gap: 8px; }
    .chip { background: #111827; border: 1px solid #1f2937; padding: 6px 10px; border-radius: 999px; display: inline-flex; gap: 6px; align-items: center; }
    .chip input { accent-color: #22c55e; }
    input[type="search"] { background: #0b1220; color: #e2e8f0; border: 1px solid #1f2937; border-radius: 8px; padding: 8px 10px; width: min(420px, 100%); }
    .hint { color: #94a3b8; font-size: 12px; }
    .muted { color: #94a3b8; }
    .toggle { display: flex; justify-content: space-between; padding: 6px 10px; border-radius: 8px; background: #0f172a; border: 1px solid #1f2937; }
    .toggle + .toggle { margin-top: 6px; }
    .toggle-key { color: #cbd5e1; }
    .toggle-value { text-transform: uppercase; font-weight: 700; }
    .toggle-value.on { color: #22c55e; }
    .toggle-value.off { color: #f43f5e; }
    .error { background: #1f2937; border: 1px solid #ef4444; padding: 16px; border-radius: 12px; color: #fecaca; }
    .error-title { font-weight: 700; margin-bottom: 8px; }
    pre { white-space: pre-wrap; background: #0b1220; padding: 12px; border-radius: 10px; border: 1px solid #1f2937; color: #e2e8f0; }
  </style>
</head>
<body>
  <header class="card-header">
    <div>
      <h1>Wave Preview</h1>
      <p>Config: <code>${path.relative(APP_ROOT, paths.configPath)}</code> | Schema: <code>${path.relative(
        APP_ROOT,
        paths.schemaPath
      )}</code></p>
    </div>
    ${renderSummary(summary)}
  </header>
  ${renderFilters({ ...summary, configPath: paths.configPath })}
  <section class="card">
    <h3>Feature toggles</h3>
    ${renderFeatureToggles(summary.featureToggles)}
  </section>
  ${bodyContent}
  ${cards}
  <script type="module">
    (() => {
      const state = {
        search: "",
        lanes: new Set(),
        types: new Set(${JSON.stringify(EVENT_TYPES)})
      };

      const cards = Array.from(document.querySelectorAll("[data-wave]"));
      const search = document.querySelector("[data-search]");
      const laneFilters = Array.from(document.querySelectorAll("[data-filter-lane]"));
      const typeToggles = Array.from(document.querySelectorAll("[data-type-toggle]"));
      const empty = document.querySelector("[data-empty]");

      function applyFilters() {
        const query = state.search.trim().toLowerCase();
        let visibleCount = 0;
        for (const card of cards) {
          const searchText = card.dataset.search || "";
          const lanes = (card.dataset.lanes || "").split(",").filter(Boolean);
          const tags = (card.dataset.tags || "").split(",").filter(Boolean);
          const matchesSearch = !query || searchText.includes(query);
          const matchesLane = state.lanes.size === 0 || lanes.some((lane) => state.lanes.has(lane));
          const matchesType = state.types.size === 0 || tags.some((tag) => state.types.has(tag));
          const show = matchesSearch && matchesLane && matchesType;
          card.style.display = show ? "" : "none";
          if (show) visibleCount += 1;

          card.querySelectorAll("[data-section-type]").forEach((section) => {
            const type = section.dataset.sectionType;
            if (type && type !== "spawns" && !state.types.has(type)) {
              section.setAttribute("hidden", "true");
            } else {
              section.removeAttribute("hidden");
            }
          });
          card.querySelectorAll(".event").forEach((eventEl) => {
            const type = eventEl.dataset.type;
            eventEl.style.display = state.types.has(type) ? "" : "none";
          });
        }
        if (empty) empty.style.display = visibleCount === 0 ? "" : "none";
      }

      search?.addEventListener("input", (ev) => {
        state.search = ev.target.value || "";
        applyFilters();
      });
      laneFilters.forEach((input) =>
        input.addEventListener("change", () => {
          const lane = input.dataset.filterLane;
          if (!lane) return;
          if (input.checked) state.lanes.add(lane);
          else state.lanes.delete(lane);
          applyFilters();
        })
      );
      typeToggles.forEach((input) =>
        input.addEventListener("change", () => {
          const type = input.dataset.typeToggle;
          if (!type) return;
          if (input.checked) state.types.add(type);
          else state.types.delete(type);
          applyFilters();
        })
      );

      applyFilters();

      try {
        const source = new EventSource("/events");
        source.onmessage = () => window.location.reload();
      } catch (err) {
        console.warn("SSE reload unavailable", err);
      }
    })();
  </script>
</body>
</html>`;
}

function watchFiles(paths, onChange) {
  const watchers = [];
  for (const target of paths) {
    try {
      const watcher = watch(target, { persistent: false }, () => onChange());
      watchers.push(watcher);
    } catch (error) {
      console.warn(`[wave:preview] Could not watch ${target}: ${error?.message ?? error}`);
    }
  }
  return () => watchers.forEach((w) => w.close());
}

async function startServer(configPath, schemaPath, port, open) {
  const resolvedConfig = path.resolve(configPath);
  const resolvedSchema = path.resolve(schemaPath);
  const vite = await createViteServer({ server: { middlewareMode: true } });
  const clients = new Set();
  const broadcast = () => {
    for (const res of clients) {
      res.write("data: reload\n\n");
    }
  };
  const closeWatchers = watchFiles([resolvedConfig, resolvedSchema], broadcast);

  const handler = async (req, res) => {
    if (!req.url || req.url === "/") {
      try {
        const config = await validateConfig(resolvedConfig, resolvedSchema);
        const summary = summarizeConfig(config);
        const html = renderHtml({
          config,
          summary,
          paths: { configPath: resolvedConfig, schemaPath: resolvedSchema }
        });
        res.writeHead(200, { "Content-Type": "text/html" });
        res.end(await vite.transformIndexHtml(req.url, html));
      } catch (error) {
        const html = renderHtml({
          config: null,
          summary: summarizeConfig(),
          paths: { configPath: resolvedConfig, schemaPath: resolvedSchema },
          error
        });
        res.writeHead(200, { "Content-Type": "text/html" });
        res.end(await vite.transformIndexHtml(req.url, html));
      }
      return;
    }

    if (req.url === "/events") {
      res.writeHead(200, {
        "Content-Type": "text/event-stream",
        "Cache-Control": "no-cache",
        Connection: "keep-alive"
      });
      res.write("retry: 2000\n\n");
      clients.add(res);
      req.on("close", () => clients.delete(res));
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

  const close = () => {
    closeWatchers();
    server.close();
  };
  process.once("SIGINT", close);
  process.once("SIGTERM", close);
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

export { startServer, renderHtml, validateConfig, summarizeConfig, waveSearchTokens };
