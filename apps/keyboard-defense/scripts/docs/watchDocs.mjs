#!/usr/bin/env node

import fs from "node:fs";
import fsp from "node:fs/promises";
import path from "node:path";
import { spawn } from "node:child_process";
import process from "node:process";
import { pathToFileURL } from "node:url";

const DEFAULT_DEBOUNCE_MS = 350;
const DEFAULT_COMMANDS = [
  {
    cmd: "npm",
    args: ["run", "codex:dashboard"],
    label: "codex:dashboard"
  }
];
const IGNORED_DIRS = new Set([".git", "node_modules", ".devserver", ".github", "artifacts"]);

function log(message) {
  console.log(`[docs:watch] ${message}`);
}

function warn(message) {
  console.warn(`[docs:watch] ${message}`);
}

function dedupe(list = []) {
  return Array.from(new Set(list));
}

export function defaultWatchPaths(cwd = process.cwd()) {
  const defaults = [
    path.resolve(cwd, "docs"),
    path.resolve(cwd, "..", "..", "docs")
  ];
  return dedupe(defaults.filter((entry) => fs.existsSync(entry)));
}

export function parseArgs(argv = process.argv.slice(2), cwd = process.cwd()) {
  const options = {
    debounceMs: DEFAULT_DEBOUNCE_MS,
    watchPaths: defaultWatchPaths(cwd),
    initialRun: true,
    help: false
  };

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    switch (token) {
      case "--watch": {
        const value = argv[++i];
        if (!value) throw new Error("Expected path after --watch");
        options.watchPaths.push(path.resolve(cwd, value));
        break;
      }
      case "--debounce": {
        const raw = Number(argv[++i]);
        if (!Number.isFinite(raw) || raw < 0) {
          throw new Error("Expected non-negative number after --debounce");
        }
        options.debounceMs = raw;
        break;
      }
      case "--no-initial":
        options.initialRun = false;
        break;
      case "--help":
      case "-h":
        options.help = true;
        break;
      default:
        if (token.startsWith("-")) throw new Error(`Unknown option: ${token}`);
    }
  }

  options.watchPaths = dedupe(options.watchPaths).filter((entry) => fs.existsSync(entry));
  return options;
}

export function createRebuildTrigger(runFn, debounceMs = DEFAULT_DEBOUNCE_MS) {
  let timer = null;
  let running = false;
  let queuedReason = null;

  const trigger = (reason) => {
    if (timer) clearTimeout(timer);
    timer = setTimeout(async () => {
      timer = null;
      if (running) {
        queuedReason = reason;
        return;
      }
      running = true;
      try {
        await runFn(reason);
      } finally {
        running = false;
        if (queuedReason) {
          const nextReason = queuedReason;
          queuedReason = null;
          trigger(nextReason);
        }
      }
    }, debounceMs);
  };

  return trigger;
}

export async function runCommands(commands = DEFAULT_COMMANDS) {
  for (const command of commands) {
    // eslint-disable-next-line no-await-in-loop
    await runCommand(command);
  }
}

function runCommand(command) {
  const { cmd, args = [], cwd = process.cwd(), env = process.env, label } = command;
  return new Promise((resolve, reject) => {
    log(`Running ${label ?? `${cmd} ${args.join(" ")}`}...`);
    const child = spawn(cmd, args, {
      cwd,
      env,
      stdio: "inherit",
      shell: false
    });
    child.on("error", (error) => reject(error));
    child.on("exit", (code) => {
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`${cmd} ${args.join(" ")} exited with code ${code}`));
      }
    });
  });
}

function shouldIgnore(entryName) {
  return IGNORED_DIRS.has(entryName) || entryName.startsWith(".");
}

async function safeStat(target) {
  try {
    return await fsp.stat(target);
  } catch {
    return null;
  }
}

async function walkDirectories(root, visit) {
  const entries = await fsp.readdir(root, { withFileTypes: true }).catch(() => []);
  for (const entry of entries) {
    if (!entry.isDirectory() || shouldIgnore(entry.name)) continue;
    const next = path.join(root, entry.name);
    await visit(next);
    // eslint-disable-next-line no-await-in-loop
    await walkDirectories(next, visit);
  }
}

function fallbackWatch(target, onChange) {
  const watchers = new Map();

  const register = async (dir) => {
    if (watchers.has(dir)) return;
    const watcher = fs.watch(dir, (eventType, fileName) => {
      const resolved = fileName ? path.join(dir, fileName) : dir;
      onChange(resolved, eventType);
      if (eventType === "rename") {
        safeStat(resolved).then((stat) => {
          if (stat?.isDirectory()) {
            register(resolved);
          } else if (!stat) {
            for (const [watchedDir, instance] of watchers) {
              if (watchedDir.startsWith(resolved)) {
                instance.close();
                watchers.delete(watchedDir);
              }
            }
          }
        });
      }
    });
    watchers.set(dir, watcher);
    await walkDirectories(dir, register);
  };

  register(target).catch((error) => warn(`Failed to register watcher for ${target}: ${error.message}`));

  return () => {
    for (const instance of watchers.values()) {
      instance.close();
    }
    watchers.clear();
  };
}

function createWatcher(target, onChange) {
  try {
    const watcher = fs.watch(
      target,
      { recursive: true },
      (eventType, fileName) => onChange(fileName ? path.join(target, fileName) : target, eventType)
    );
    log(`Watching ${target} (recursive)`);
    return () => watcher.close();
  } catch (error) {
    warn(
      `Recursive watch unsupported for ${target} (${error.message}); falling back to per-directory watchers.`
    );
    return fallbackWatch(target, onChange);
  }
}

async function main(argv = process.argv.slice(2)) {
  const options = parseArgs(argv);
  if (options.help) {
    console.log(`docs:watch

Watches documentation directories and rebuilds Codex summaries automatically.

Usage:
  node scripts/docs/watchDocs.mjs [--watch <path>] [--debounce <ms>] [--no-initial]

Options:
  --watch <path>    Additional directory to watch (can be repeated).
  --debounce <ms>   Debounce window in milliseconds before rebuilding (default: ${DEFAULT_DEBOUNCE_MS}).
  --no-initial      Skip the initial rebuild on startup.
  --help, -h        Show this help text.
`);
    return;
  }

  if (!options.watchPaths.length) {
    throw new Error("No existing watch paths found. Create a docs/ directory or pass --watch <path>.");
  }

  const rebuild = createRebuildTrigger(async (reason) => {
    log(`Change detected (${reason ?? "unknown"}); rebuilding summaries...`);
    await runCommands(DEFAULT_COMMANDS);
    log("Summaries rebuilt.");
  }, options.debounceMs);

  const closers = options.watchPaths.map((target) => createWatcher(target, rebuild));
  log(`Watching ${options.watchPaths.length} path(s): ${options.watchPaths.join(", ")}`);
  if (options.initialRun) {
    rebuild("initial");
  }

  const shutdown = () => {
    log("Stopping watchers...");
    for (const close of closers) close();
    process.exit(0);
  };

  process.on("SIGINT", shutdown);
  process.on("SIGTERM", shutdown);
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch((error) => {
    console.error(`[docs:watch] ${error.message}`);
    process.exitCode = 1;
  });
}

