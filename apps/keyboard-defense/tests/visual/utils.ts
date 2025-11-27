import type { Page } from "@playwright/test";

export async function waitForApp(page: Page): Promise<void> {
  await page.waitForFunction(() => typeof window.keyboardDefense === "object", {
    timeout: 60_000
  });
}

export async function disableAnimations(page: Page): Promise<void> {
  await page.addStyleTag({
    content: `
      *,
      *::before,
      *::after {
        transition-duration: 0s !important;
        animation-duration: 0s !important;
        animation-delay: 0s !important;
      }
    `
  });
}

export async function resetHud(page: Page): Promise<void> {
  await page.evaluate(() => {
    const kd = window.keyboardDefense;
    document.getElementById("main-menu-skip-tutorial")?.dispatchEvent(new MouseEvent("click", { bubbles: true }));
    kd?.pause?.();
    kd?.reset?.();
    kd?.skipTutorial?.();
    kd?.setHudFontScale?.(1);
    kd?.setReducedMotionEnabled?.(true);
    kd?.setDiagnosticsCondensed?.(false);
    kd?.resume?.();
  });
}

type KeyboardDefenseApi = {
  pause?: () => void;
  reset?: () => void;
  skipTutorial?: () => void;
  setHudFontScale?: (scale: number) => void;
  setReducedMotionEnabled?: (enabled: boolean) => void;
  setDiagnosticsCondensed?: (condensed: boolean) => void;
  resume?: () => void;
  [key: string]: unknown;
};

declare global {
  interface Window {
    keyboardDefense?: KeyboardDefenseApi;
  }
}
