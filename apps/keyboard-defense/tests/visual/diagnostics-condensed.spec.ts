import { expect, test } from "@playwright/test";
import type { Page } from "@playwright/test";

import { disableAnimations, resetHud, waitForApp } from "./utils";

type UiSnapshot = {
  diagnostics?: {
    condensed?: boolean;
    sectionsCollapsed?: boolean;
    collapsedSections?: Record<string, boolean>;
  };
  preferences?: {
    diagnosticsSections?: Record<string, boolean>;
    diagnosticsSectionsUpdatedAt?: string | null;
  };
} | null;

async function showDiagnosticsOverlay(page: Page): Promise<void> {
  await page.evaluate(() => {
    const kd = window.keyboardDefense;
    kd?.resume?.();
    kd?.pause?.();
    kd?.showDiagnostics?.();
  });
  await expect(page.locator("body")).toHaveAttribute("data-diagnostics-condensed", "true");
}

async function getUiSnapshot(page: Page): Promise<UiSnapshot> {
  return page.evaluate(() => window.keyboardDefense?.getUiSnapshot?.() ?? null);
}

async function toggleSection(page: Page, sectionId: string): Promise<void> {
  const control = page.locator(
    `#diagnostics-section-controls [data-section="${sectionId}"]`
  );
  await control.waitFor();
  await control.click();
}

test.describe("Diagnostics condensed smoke", () => {
  test.beforeEach(async ({ page }) => {
    await page.setViewportSize({ width: 1024, height: 500 });
    await page.goto("/", { waitUntil: "networkidle" });
    await waitForApp(page);
    await disableAnimations(page);
    await resetHud(page);
  });

  test("collapsed preferences persist across reloads", async ({ page }) => {
    await showDiagnosticsOverlay(page);
    await toggleSection(page, "gold-events");
    await toggleSection(page, "turret-dps");

    const body = page.locator("body");
    await expect(body).toHaveAttribute("data-diagnostics-sections-collapsed", "false");

    const snapshot = await getUiSnapshot(page);
    expect(snapshot?.diagnostics?.sectionsCollapsed).toBe(false);
    expect(snapshot?.diagnostics?.collapsedSections?.["gold-events"]).toBe(false);
    expect(snapshot?.diagnostics?.collapsedSections?.["turret-dps"]).toBe(false);
    expect(snapshot?.preferences?.diagnosticsSections?.["gold-events"]).toBe(false);
    expect(snapshot?.preferences?.diagnosticsSections?.["turret-dps"]).toBe(false);
    expect(
      typeof snapshot?.preferences?.diagnosticsSectionsUpdatedAt === "string" &&
        (snapshot?.preferences?.diagnosticsSectionsUpdatedAt?.length ?? 0) > 0
    ).toBe(true);

    await page.reload({ waitUntil: "networkidle" });
    await waitForApp(page);
    await disableAnimations(page);
    await resetHud(page);
    await showDiagnosticsOverlay(page);

    const controls = page.locator("#diagnostics-section-controls");
    await expect(
      controls.locator('[data-section="gold-events"]')
    ).toHaveText(/Hide Gold events/i);
    await expect(
      controls.locator('[data-section="turret-dps"]')
    ).toHaveText(/Hide Turret DPS/i);

    const snapshotAfterReload = await getUiSnapshot(page);
    expect(snapshotAfterReload?.diagnostics?.collapsedSections?.["gold-events"]).toBe(false);
    expect(snapshotAfterReload?.preferences?.diagnosticsSections?.["gold-events"]).toBe(false);
    expect(snapshotAfterReload?.preferences?.diagnosticsSectionsUpdatedAt).toBeTruthy();
    await expect(body).toHaveAttribute("data-diagnostics-sections-collapsed", "false");
  });
});
