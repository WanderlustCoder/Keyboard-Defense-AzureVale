import { defineConfig, devices } from "@playwright/test";

const BASE_URL = process.env.VISUAL_BASE_URL ?? "http://127.0.0.1:4173";
const WEB_COMMAND = process.env.PLAYWRIGHT_WEB_COMMAND ?? "npm run start";
const WEB_PORT = Number(process.env.PLAYWRIGHT_WEB_PORT ?? 4173);

export default defineConfig({
  testDir: "./tests/visual",
  timeout: 60_000,
  expect: {
    toHaveScreenshot: {
      maxDiffPixelRatio: 0.01
    }
  },
  fullyParallel: false,
  reporter: process.env.CI
    ? [["line"], ["html", { open: "never", outputFolder: "playwright-report" }]]
    : [["list"]],
  use: {
    baseURL: BASE_URL,
    viewport: { width: 1280, height: 720 },
    trace: "on-first-retry",
    video: "retain-on-failure",
    screenshot: "only-on-failure",
    ...devices["Desktop Chrome"]
  },
  projects: [
    {
      name: "visual",
      testMatch: /.*\.spec\.ts/
    }
  ],
  webServer: {
    command: WEB_COMMAND,
    url: `http://127.0.0.1:${WEB_PORT}`,
    reuseExistingServer: !process.env.CI,
    timeout: 120_000,
    env: {
      DEVSERVER_SKIP_BUILD: "1",
      ...process.env
    }
  }
});
