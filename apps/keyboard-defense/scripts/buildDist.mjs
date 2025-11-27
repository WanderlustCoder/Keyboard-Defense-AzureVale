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
const TEMP_ROOT = path.join(APP_ROOT, "temp", "dist-build");
const BUILD_OUT = path.join(TEMP_ROOT, "src");
const DIST_OUT = path.join(APP_ROOT, "public", "dist", "src");

async function runTsc() {
  await rm(TEMP_ROOT, { recursive: true, force: true });
  await mkdir(TEMP_ROOT, { recursive: true });
  await new Promise((resolve, reject) => {
    const child = spawn("tsc", ["-p", "tsconfig.build.json"], {
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
  await cp(BUILD_OUT, DIST_OUT, { recursive: true, force: true });
  await rm(TEMP_ROOT, { recursive: true, force: true });
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
