import { expect, test } from "@playwright/test";
import type { Page } from "@playwright/test";

import { disableAnimations, resetHud, waitForApp } from "./utils";

const SCREENSHOT_OPTIONS = { animations: "disabled", fullPage: true } as const;

async function captureHudMain(page: Page) {
  await page.evaluate(() => {
    const kd = window.keyboardDefense;
    if (!kd) throw new Error("keyboardDefense debug API unavailable.");
    kd.skipTutorial();
    kd.grantGold(600);
    kd.placeTurret("slot-1", "arrow");
    kd.upgradeTurret("slot-1");
    kd.spawnEnemy({ tierId: "runner", lane: 1 });
    kd.spawnEnemy({ tierId: "brute", lane: 0, shield: { health: 40 } });
    kd.resume();
  });
  await page.waitForTimeout(2500);
  await page.evaluate(() => window.keyboardDefense?.pause?.());
  await page.waitForTimeout(200);
}

async function captureOptionsOverlay(page: Page) {
  await page.evaluate(() => document.getElementById("pause-button")?.click());
  await page.waitForTimeout(400);
}

async function captureTutorialSummary(page: Page) {
  await page.evaluate(() => {
    const kd = window.keyboardDefense;
    if (!kd || typeof kd.showTutorialSummary !== "function") {
      throw new Error("keyboardDefense debug API missing showTutorialSummary.");
    }
    kd.pause?.();
    kd.showTutorialSummary({
      accuracy: 0.97,
      bestCombo: 42,
      breaches: 1,
      gold: 380
    });
  });
  await page.waitForTimeout(400);
}

async function captureWaveScorecard(page: Page) {
  await page.evaluate(() => {
    const kd = window.keyboardDefense;
    if (!kd || typeof kd.showWaveScorecard !== "function") {
      throw new Error("keyboardDefense debug API missing showWaveScorecard.");
    }
    kd.showWaveScorecard({
      waveIndex: 4,
      waveTotal: 7,
      mode: "campaign",
      accuracy: 0.91,
      enemiesDefeated: 18,
      breaches: 1,
      perfectWords: 6,
      averageReaction: 1.1,
      dps: 32,
      turretDps: 18,
      typingDps: 14,
      turretDamage: 640,
      typingDamage: 498,
      shieldBreaks: 3,
      repairsUsed: 1,
      repairHealth: 80,
      repairGold: 200,
      goldEarned: 210,
      bonusGold: 35,
      castleBonusGold: 24,
      bestCombo: 28,
      sessionBestCombo: 35
    });
  });
  await page.waitForTimeout(400);
}

test.describe("HUD visual regression", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/", { waitUntil: "networkidle" });
    await waitForApp(page);
    await disableAnimations(page);
    await resetHud(page);
  });

  test("hud-main screenshot", async ({ page }) => {
    await captureHudMain(page);
    await expect(page).toHaveScreenshot("hud-main.png", SCREENSHOT_OPTIONS);
  });

  test("options overlay screenshot", async ({ page }) => {
    await captureOptionsOverlay(page);
    await expect(page).toHaveScreenshot("options-overlay.png", SCREENSHOT_OPTIONS);
  });

  test("tutorial summary screenshot", async ({ page }) => {
    await captureTutorialSummary(page);
    await expect(page).toHaveScreenshot("tutorial-summary.png", SCREENSHOT_OPTIONS);
    await page.evaluate(() => window.keyboardDefense?.hideTutorialSummary?.());
  });

  test("wave scorecard screenshot", async ({ page }) => {
    await captureWaveScorecard(page);
    await expect(page).toHaveScreenshot("wave-scorecard.png", SCREENSHOT_OPTIONS);
    await page.evaluate(() => window.keyboardDefense?.hideWaveScorecard?.());
  });
});

declare global {
  interface Window {
    keyboardDefense?: Record<string, unknown>;
  }
}

export {};
