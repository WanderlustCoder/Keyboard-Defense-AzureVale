import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { describe, expect, test, vi } from "vitest";

import { createRebuildTrigger, defaultWatchPaths, parseArgs } from "../scripts/docs/watchDocs.mjs";

const wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

describe("watchDocs", () => {
  test("defaultWatchPaths prefers existing docs directories", async () => {
    const root = await fs.mkdtemp(path.join(os.tmpdir(), "watchdocs-"));
    const appDir = path.join(root, "apps", "keyboard-defense");
    const rootDocs = path.join(root, "docs");
    const appDocs = path.join(appDir, "docs");
    await fs.mkdir(rootDocs, { recursive: true });
    await fs.mkdir(appDocs, { recursive: true });

    const defaults = defaultWatchPaths(appDir);
    expect(defaults).toEqual([appDocs, rootDocs]);
  });

  test("parseArgs merges custom watch paths, debounce, and flags", async () => {
    const root = await fs.mkdtemp(path.join(os.tmpdir(), "watchdocs-args-"));
    const appDir = path.join(root, "apps", "keyboard-defense");
    const altWatch = path.join(root, "alt-docs");
    await fs.mkdir(path.join(root, "docs"), { recursive: true });
    await fs.mkdir(path.join(appDir, "docs"), { recursive: true });
    await fs.mkdir(altWatch, { recursive: true });

    const options = parseArgs(
      ["--watch", altWatch, "--debounce", "125", "--no-initial"],
      appDir
    );

    expect(options.initialRun).toBe(false);
    expect(options.debounceMs).toBe(125);
    expect(options.watchPaths).toEqual([
      path.join(appDir, "docs"),
      path.join(root, "docs"),
      altWatch
    ]);
  });

  test("createRebuildTrigger debounces and queues rebuilds", async () => {
    vi.useFakeTimers();
    const invocations = [];
    const trigger = createRebuildTrigger(async (reason) => {
      invocations.push(reason);
      await wait(10);
    }, 5);

    trigger("first");
    trigger("second");
    await vi.advanceTimersByTimeAsync(20);
    expect(invocations).toEqual(["second"]);

    trigger("slow");
    await vi.advanceTimersByTimeAsync(6);
    trigger("queued");
    await vi.advanceTimersByTimeAsync(40);
    expect(invocations).toEqual(["second", "slow", "queued"]);
    vi.useRealTimers();
  });
});
