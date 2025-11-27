#!/usr/bin/env node

import { promises as fs } from "node:fs";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const appRoot = path.resolve(scriptDir, "..", "..");
const repoRoot = path.resolve(appRoot, "..", "..");
const DEFAULT_INPUT_DIR = path.resolve(appRoot, "artifacts", "screenshots");
const DEFAULT_OUTPUT_FILE = path.resolve(repoRoot, "docs", "hud_gallery.md");
const DEFAULT_JSON_FILE = path.resolve(appRoot, "artifacts", "summaries", "ui-snapshot-gallery.json");
const DEFAULT_REQUIRED_SHOTS = [
  "hud-main",
  "diagnostics-overlay",
  "options-overlay",
  "shortcut-overlay",
  "tutorial-summary",
  "wave-scorecard"
];
const DEFAULT_FIXTURE_META_DIR = path.resolve(
  repoRoot,
  "docs",
  "codex_pack",
  "fixtures",
  "ui-snapshot"
);

function parseArgs(argv) {
  const opts = {
    inputDir: DEFAULT_INPUT_DIR,
    outputFile: DEFAULT_OUTPUT_FILE,
    jsonFile: DEFAULT_JSON_FILE,
    metaPaths: [DEFAULT_FIXTURE_META_DIR],
    verify: false,
    requiredShots: [],
    help: false
  };

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    switch (token) {
      case "--input":
      case "--dir": {
        const value = argv[++i];
        if (!value) throw new Error(`Missing value for ${token}`);
        opts.inputDir = path.resolve(value);
        break;
      }
      case "--output":
      case "--out": {
        const value = argv[++i];
        if (!value) throw new Error(`Missing value for ${token}`);
        opts.outputFile = path.resolve(value);
        break;
      }
      case "--json": {
        const value = argv[++i];
        if (!value) throw new Error("Missing value after --json");
        opts.jsonFile = path.resolve(value);
        break;
      }
      case "--meta": {
        const value = argv[++i];
        if (!value) throw new Error("Missing value after --meta");
        opts.metaPaths.push(path.resolve(value));
        break;
      }
      case "--verify":
        opts.verify = true;
        break;
      case "--required": {
        const value = argv[++i];
        if (!value) throw new Error("Missing value after --required");
        opts.requiredShots = value
          .split(",")
          .map((part) => part.trim())
          .filter(Boolean);
        break;
      }
      case "--help":
      case "-h":
        opts.help = true;
        break;
      default:
        if (token.startsWith("-")) {
          throw new Error(`Unknown option "${token}". Use --help for usage.`);
        }
    }
  }

  return opts;
}

async function listFilesSafe(dir, predicate) {
  try {
    const entries = await fs.readdir(dir, { withFileTypes: true });
    return entries
      .filter((entry) => entry.isFile() && predicate(entry.name))
      .map((entry) => path.join(dir, entry.name));
  } catch {
    return [];
  }
}

async function discoverMetaFiles(inputDir, extraMeta) {
  const files = new Set(await listFilesSafe(inputDir, (name) => name.endsWith(".meta.json")));
  for (const target of extraMeta) {
    try {
      const stat = await fs.stat(target);
      if (stat.isDirectory()) {
        const dirFiles = await listFilesSafe(target, (name) => name.endsWith(".meta.json"));
        dirFiles.forEach((file) => files.add(file));
      } else if (stat.isFile()) {
        files.add(target);
      }
    } catch {
      // Ignore unreadable paths; they might be glob patterns that the shell already resolved.
    }
  }
  return Array.from(files);
}

function formatRelative(p) {
  if (!p) return "";
  return path.relative(repoRoot, p).replace(/\\/g, "/");
}

function describeSnapshot(snapshot) {
  if (!snapshot || typeof snapshot !== "object") {
    return "Snapshot metadata unavailable.";
  }
  const parts = [];
  if (snapshot.compactHeight) parts.push("Compact viewport");
  if (snapshot.tutorialBanner?.condensed) parts.push("Tutorial banner condensed");
  if (snapshot.hud?.passivesCollapsed === true) parts.push("HUD passives collapsed");
  if (snapshot.hud?.goldEventsCollapsed === true) parts.push("HUD gold events collapsed");
  if (snapshot.diagnostics?.condensed === true) parts.push("Diagnostics condensed");
  const diagnosticsSectionsState = snapshot.diagnostics?.sectionsCollapsed;
  if (diagnosticsSectionsState === true) {
    parts.push("Diagnostics sections collapsed");
  } else if (diagnosticsSectionsState === false) {
    parts.push("Diagnostics sections expanded");
  }
  const diagSections = snapshot.diagnostics?.collapsedSections ?? {};
  const diagEntries = Object.entries(diagSections).filter(
    ([, value]) => typeof value === "boolean"
  );
  if (diagEntries.length > 0) {
    const detail = diagEntries
      .map(([section, collapsed]) => `${section}:${collapsed ? "collapsed" : "expanded"}`)
      .join(", ");
    parts.push(`Diagnostics sections — ${detail}`);
  }
  if (snapshot.options?.passivesCollapsed === true) parts.push("Options passives collapsed");
  if (snapshot.hud?.prefersCondensedLists) parts.push("HUD prefers condensed lists");
  return parts.length > 0 ? parts.join("; ") : "UI snapshot recorded.";
}

function extractStarfieldScene(data) {
  const fromPayload =
    typeof data.starfieldScene === "string" && data.starfieldScene.trim().length > 0
      ? data.starfieldScene.trim().toLowerCase()
      : null;
  if (fromPayload) {
    return fromPayload;
  }
  const fromParameters =
    typeof data.parameters?.starfieldScene === "string" &&
    data.parameters.starfieldScene.trim().length > 0
      ? data.parameters.starfieldScene.trim().toLowerCase()
      : null;
  if (fromParameters) {
    return fromParameters;
  }
  const badges = Array.isArray(data.badges) ? data.badges : [];
  const starfieldBadge = badges.find(
    (badge) => typeof badge === "string" && badge.startsWith("starfield:")
  );
  if (starfieldBadge) {
    const value = starfieldBadge.slice("starfield:".length).trim().toLowerCase();
    return value.length > 0 ? value : null;
  }
  return null;
}

async function loadMetadata(metaFiles) {
  const entries = [];
  for (const file of metaFiles) {
    try {
      const content = await fs.readFile(file, "utf8");
      const data = JSON.parse(content);
      const uiDetails = describeSnapshot(data.uiSnapshot);
      const snapshotSummary = data.summary ?? uiDetails;
      const starfieldScene = extractStarfieldScene(data);
      const imagePath = (() => {
        if (!data.file) return "";
        const absolute = path.isAbsolute(data.file)
          ? data.file
          : path.resolve(appRoot, data.file);
        return formatRelative(absolute);
      })();
      entries.push({
        id: data.id ?? path.basename(file, ".meta.json"),
        description: data.description ?? "",
        image: imagePath,
        badges: Array.isArray(data.badges) ? data.badges : [],
        summary: snapshotSummary,
        uiDetails,
        starfieldScene,
        metaFile: formatRelative(file),
        metaFiles: [formatRelative(file)],
        sourceAbsolute: file
      });
    } catch (error) {
      console.warn(`renderHudGallery: unable to parse ${file} (${error?.message ?? error})`);
    }
  }
  return entries.sort((a, b) => a.id.localeCompare(b.id));
}

function isArtifactSource(entry) {
  const target = entry.sourceAbsolute ?? "";
  return target.includes(path.join(appRoot, "artifacts", "screenshots"));
}

function pickPreferredEntry(current, next) {
  const score = (entry) => {
    let s = 0;
    if (entry.image) s += 1;
    if (isArtifactSource(entry)) s += 2;
    return s;
  };
  return score(next) > score(current) ? next : current;
}

function dedupeEntries(entries) {
  const byId = new Map();
  for (const entry of entries) {
    const existing = byId.get(entry.id);
    if (!existing) {
      byId.set(entry.id, {
        ...entry,
        metaFiles: Array.from(new Set(entry.metaFiles ?? []))
      });
      continue;
    }
    const mergedMetaFiles = Array.from(
      new Set([...(existing.metaFiles ?? []), ...(entry.metaFiles ?? [])])
    );
    const preferred = pickPreferredEntry(existing, entry);
    byId.set(entry.id, {
      ...preferred,
      metaFiles: mergedMetaFiles
    });
  }
  return Array.from(byId.values()).map((entry) => ({
    ...entry,
    metaFile: entry.metaFiles?.[0] ?? entry.metaFile ?? null
  }));
}

function formatBadges(badges) {
  if (!badges || badges.length === 0) return "_none_";
  return badges.map((badge) => `\`${badge}\``).join("<br />");
}

function buildJsonPayload(entries, outputFile = DEFAULT_OUTPUT_FILE) {
  return {
    generatedAt: new Date().toISOString(),
    sourceDoc: formatRelative(outputFile),
    shots: entries.map((entry) => ({
      id: entry.id,
      description: entry.description,
      image: entry.image,
      badges: entry.badges,
      summary: entry.summary,
      uiDetails: entry.uiDetails,
      starfieldScene: entry.starfieldScene ?? null,
      metaFile: entry.metaFile,
      metaFiles: entry.metaFiles ?? (entry.metaFile ? [entry.metaFile] : [])
    }))
  };
}

function verifyEntries(entries, requiredShots = DEFAULT_REQUIRED_SHOTS) {
  const messages = [];
  const map = new Map(entries.map((entry) => [entry.id, entry]));
  const shotIds =
    Array.isArray(requiredShots) && requiredShots.length > 0
      ? requiredShots
      : DEFAULT_REQUIRED_SHOTS;
  for (const shotId of shotIds) {
    if (!map.has(shotId)) {
      messages.push(`Missing required screenshot "${shotId}"`);
    }
  }
  for (const entry of entries) {
    if (!entry.badges || entry.badges.length === 0) {
      messages.push(`Screenshot "${entry.id}" missing badges.`);
    }
    if (!entry.summary || entry.summary.trim().length === 0) {
      messages.push(`Screenshot "${entry.id}" missing summary text.`);
    }
  }
  return { ok: messages.length === 0, messages };
}

function formatStarfieldCell(entry) {
  const scene = entry.starfieldScene ?? null;
  return scene ? `\`${scene}\`` : "_auto_";
}

function buildDoc(entries) {
  const lines = [];
  lines.push("# HUD Screenshot Gallery");
  lines.push("");
  lines.push(
    "Generated via `npm run docs:gallery` (wraps `node scripts/docs/renderHudGallery.mjs --input artifacts/screenshots --meta artifacts/screenshots --meta ../../docs/codex_pack/fixtures/ui-snapshot --json artifacts/summaries/ui-snapshot-gallery.json --verify`). Use `node scripts/docs/renderHudGallery.mjs --help` for additional options."
  );
  lines.push("");
  if (entries.length === 0) {
    lines.push("_No screenshot metadata was found. Run the HUD screenshot CLI first._");
    return lines.join("\n");
  }
  lines.push("| Shot | Screenshot | Starfield | Badges | Summary | UI Snapshot |");
  lines.push("| --- | --- | --- | --- | --- | --- |");
  for (const entry of entries) {
    const label = entry.description ? `${entry.id} (${entry.description})` : entry.id;
    const screenshotCell = entry.image
      ? `[${entry.image}](${entry.image})`
      : "_not captured_";
    lines.push(
      `| ${label} | ${screenshotCell} | ${formatStarfieldCell(entry)} | ${formatBadges(entry.badges)} | ${entry.summary} | ${entry.uiDetails ?? "_n/a_"} |`
    );
  }
  lines.push("");
  lines.push("_Starfield column reflects the `--starfield-scene` override recorded in each `.meta.json`; `_auto_` means the capture relied on the live gameplay-driven parallax._");
  lines.push("");
  lines.push("## Metadata Sources");
  lines.push("");
  for (const entry of entries) {
    const sources = Array.isArray(entry.metaFiles) ? entry.metaFiles : [entry.metaFile].filter(Boolean);
    if (!sources || sources.length === 0) continue;
    lines.push(`- \`${entry.id}\`: ${sources.join("; ")}`);
  }
  lines.push("");
  lines.push("## Regeneration");
  lines.push("");
  lines.push("```bash");
  lines.push("npm run docs:gallery");
  lines.push("```");
  lines.push("");
  lines.push(
    "This command scans `artifacts/screenshots/*.meta.json` (plus fixture metadata) and refreshes both `docs/hud_gallery.md` and `artifacts/summaries/ui-snapshot-gallery*.json`, failing if required screenshots or badges are missing."
  );
  return lines.join("\n");
}

async function main() {
  let opts;
  try {
    opts = parseArgs(process.argv.slice(2));
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
    return;
  }

  if (opts.help) {
    console.log("Usage: node scripts/docs/renderHudGallery.mjs [options]");
    console.log("Options:");
    console.log("  --input <dir>       Directory containing screenshot PNGs + .meta.json files");
    console.log("  --output <file>     Markdown output file (default docs/hud_gallery.md)");
    console.log("  --json <file>       JSON output file (default artifacts/summaries/ui-snapshot-gallery.json)");
    console.log("  --meta <path>       Additional directory/file glob to scan for metadata (repeatable)");
    console.log("  --verify            Fail when required shots or badges/summaries are missing");
    console.log("  --required a,b,c    Override required shot ids evaluated during --verify");
    console.log("  --help              Show this message");
    return;
  }

  const metaFiles = await discoverMetaFiles(opts.inputDir, opts.metaPaths);
  const entries = dedupeEntries(await loadMetadata(metaFiles));
  const doc = buildDoc(entries);
  await fs.mkdir(path.dirname(opts.outputFile), { recursive: true });
  await fs.writeFile(opts.outputFile, doc, "utf8");
  if (opts.jsonFile) {
    const jsonPayload = buildJsonPayload(entries, opts.outputFile);
    await fs.mkdir(path.dirname(path.resolve(opts.jsonFile)), { recursive: true });
    await fs.writeFile(opts.jsonFile, JSON.stringify(jsonPayload, null, 2), "utf8");
  }

  if (opts.verify) {
    const result = verifyEntries(entries, opts.requiredShots);
    if (!result.ok) {
      for (const message of result.messages) {
        console.error(`renderHudGallery verify: ${message}`);
      }
      process.exit(1);
      return;
    }
  }

  console.log(`HUD gallery updated: ${formatRelative(opts.outputFile)}`);
  if (opts.jsonFile) {
    console.log(`HUD gallery JSON: ${formatRelative(opts.jsonFile)}`);
  }
}

if (
  fileURLToPath(import.meta.url) === path.resolve(process.argv[1] ?? "") ||
  process.argv[1]?.endsWith("renderHudGallery.mjs")
) {
  await main();
}

export {
  discoverMetaFiles,
  loadMetadata,
  buildDoc,
  buildJsonPayload,
  verifyEntries,
  dedupeEntries
};
