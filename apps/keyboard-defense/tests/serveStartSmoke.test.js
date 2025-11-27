import { describe, expect, it, vi } from "vitest";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";

import { runStartSmoke } from "../scripts/serveStartSmoke.mjs";

async function withTempDir(fn) {
  const dir = await fs.mkdtemp(path.join(os.tmpdir(), "start-smoke-"));
  try {
    return await fn(dir);
  } finally {
    await fs.rm(dir, { recursive: true, force: true });
  }
}

describe("serveStartSmoke", () => {
  it("records a passing summary and copies logs", async () =>
    withTempDir(async (dir) => {
      const artifact = path.join(dir, "summary.json");
      const log = path.join(dir, "summary.log");
      const sourceLog = path.join(dir, "source.log");
      const statePath = path.join(dir, "state.json");

      await fs.writeFile(sourceLog, "dev server log contents", "utf8");
      await fs.writeFile(statePath, JSON.stringify({ url: "http://127.0.0.1:4173" }), "utf8");

      const start = vi.fn().mockResolvedValue(undefined);
      const stop = vi.fn().mockResolvedValue(undefined);

      const summary = await runStartSmoke(
        { artifact, log, devServerLog: sourceLog, statePath },
        { startServer: start, stopServer: stop }
      );

      expect(summary.status).toBe("pass");
      const written = JSON.parse(await fs.readFile(artifact, "utf8"));
      expect(written.status).toBe("pass");
      expect(await fs.readFile(log, "utf8")).toContain("dev server log contents");
    }));

  it("rejects when attempts fail and persists the artifact", async () =>
    withTempDir(async (dir) => {
      const artifact = path.join(dir, "summary.json");
      const log = path.join(dir, "summary.log");
      await fs.writeFile(path.join(dir, "source.log"), "log", "utf8");

      const start = vi.fn().mockRejectedValue(new Error("boom"));
      const stop = vi.fn().mockResolvedValue(undefined);

      await expect(
        runStartSmoke(
          {
            artifact,
            log,
            devServerLog: path.join(dir, "source.log"),
            attempts: 2,
            retryDelayMs: 1
          },
          { startServer: start, stopServer: stop }
        )
      ).rejects.toThrow("boom");

      const written = JSON.parse(await fs.readFile(artifact, "utf8"));
      expect(written.status).toBe("fail");
      expect(written.attempts).toHaveLength(2);
    }));
});
