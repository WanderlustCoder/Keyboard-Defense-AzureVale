#!/usr/bin/env node
/**
 * Compiles TypeScript sources and copies the generated JS/typings into public/dist/src.
 */
import { spawn } from "node:child_process";
import { cp, mkdir, rm } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const APP_ROOT = path.resolve(__dirname, "..");
const TEMP_ROOT_BASE = path.join(APP_ROOT, "temp", "dist-build");
const TEMP_ROOT = path.join(
  TEMP_ROOT_BASE,
  `${Date.now()}-${Math.random().toString(16).slice(2)}`
);
const BUILD_OUT = path.join(TEMP_ROOT, "src");
const DIST_OUT = path.join(APP_ROOT, "public", "dist", "src");
const DOCS_SRC = path.join(APP_ROOT, "docs");
const DOCS_OUT = path.join(APP_ROOT, "public", "dist", "docs");
const DOC_FOLDERS = ["lore", "enemies", "roadmap", "taunts", "dialogue"];

async function runTsc() {
  await mkdir(TEMP_ROOT, { recursive: true });
  await new Promise((resolve, reject) => {
    const child = spawn("tsc", ["-p", "tsconfig.build.json", "--outDir", BUILD_OUT], {
      cwd: APP_ROOT,
      stdio: "inherit",
      shell: process.platform === "win32"
    });
    child.on("error", reject);
    child.on("exit", (code) => {
      if (code === 0) resolve();
      else reject(new Error(`tsc exited with code ${code}`));
    });
  });
}

async function copyArtifacts() {
  await mkdir(DIST_OUT, { recursive: true });
  try {
    await cp(BUILD_OUT, DIST_OUT, { recursive: true, force: true });
  } catch (error) {
    console.warn(
      "Warning: failed to copy dist artifacts; existing files may be locked",
      error instanceof Error ? error.message : String(error)
    );
  }
  await mkdir(DOCS_OUT, { recursive: true });
  for (const folder of DOC_FOLDERS) {
    const from = path.join(DOCS_SRC, folder);
    const to = path.join(DOCS_OUT, folder);
    try {
      await cp(from, to, { recursive: true, force: true });
    } catch (error) {
      console.warn(
        `Warning: failed to copy docs folder ${folder}; existing files may be locked`,
        error instanceof Error ? error.message : String(error)
      );
    }
  }
  try {
    await rm(TEMP_ROOT, { recursive: true, force: true });
  } catch (error) {
    console.warn("Warning: failed to clean temp dist dir", error?.message ?? error);
  }
}

async function main() {
  await runTsc();
  await copyArtifacts();
  console.log("Dist sources updated from TypeScript.");
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
});
