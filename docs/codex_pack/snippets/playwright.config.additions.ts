// playwright.config.ts (additions)
// Keep this alongside your existing config.
import { defineConfig } from '@playwright/test';

export default defineConfig({
  expect: { toHaveScreenshot: { maxDiffPixelRatio: 0.01 } },
  use: {
    trace: 'on-first-retry',
    video: 'retain-on-failure',
    screenshot: 'only-on-failure'
  }
});
