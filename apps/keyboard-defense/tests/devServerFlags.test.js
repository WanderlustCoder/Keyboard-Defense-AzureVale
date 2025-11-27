import { describe, expect, it, vi } from "vitest";

import { parseStartOptions, startServer } from "../scripts/devServer.mjs";

describe("devServer flags", () => {
  it("parses --no-build and --force-restart flags", () => {
    const options = parseStartOptions(["--no-build", "--force-restart"]);
    expect(options.noBuild).toBe(true);
    expect(options.forceRestart).toBe(true);
  });

  it("startServer skips build when no-build is set", async () => {
    const runBuild = vi.fn();
    const writeState = vi.fn();
    const waitForReady = vi.fn();
    const clearState = vi.fn();
    const launchHttpServer = vi.fn().mockResolvedValue({ pid: 321 });

    await startServer(
      { noBuild: true },
      {
        readState: vi.fn().mockResolvedValue(null),
        isProcessRunning: vi.fn().mockReturnValue(false),
        runBuild,
        launchHttpServer,
        writeState,
        waitForReady,
        clearState,
        terminateProcess: vi.fn()
      }
    );

    expect(runBuild).not.toHaveBeenCalled();
    expect(writeState).toHaveBeenCalled();
    const firstState = writeState.mock.calls[0][0];
    expect(firstState.flags).toContain("no-build");
    expect(waitForReady).toHaveBeenCalledWith(firstState.url);
  });

  it("startServer stops an existing process when force-restart is used", async () => {
    const existingState = {
      pid: 111,
      url: "http://127.0.0.1:4173",
      logPath: ".devserver/server.log"
    };
    const readState = vi
      .fn()
      .mockResolvedValueOnce(existingState)
      .mockResolvedValueOnce(existingState)
      .mockResolvedValue(null);
    const isProcessRunning = vi.fn().mockReturnValue(true);
    const terminateProcess = vi.fn();
    const clearState = vi.fn();
    const writeState = vi.fn();

    await startServer(
      { forceRestart: true },
      {
        readState,
        isProcessRunning,
        runBuild: vi.fn(),
        launchHttpServer: vi.fn().mockResolvedValue({ pid: 222 }),
        writeState,
        waitForReady: vi.fn(),
        clearState,
        terminateProcess
      }
    );

    expect(terminateProcess).toHaveBeenCalledWith(existingState.pid);
    expect(clearState).toHaveBeenCalled();
    const firstState = writeState.mock.calls[0][0];
    expect(firstState.flags).toContain("force-restart");
  });
});
