import { describe, expect, test, beforeEach, afterEach } from "vitest";
import { parseHTML } from "linkedom";
import { WavePreviewPanel } from "../src/ui/wavePreview.ts";
import { defaultConfig } from "../src/core/config.ts";
import { getEnemyBiography } from "../src/data/bestiary.ts";

describe("WavePreviewPanel selection", () => {
  let window;
  let document;
  let container;

  beforeEach(() => {
    const dom = parseHTML(`<div id="root"></div>`);
    window = dom.window;
    document = dom.document;
    container = document.getElementById("root");
    global.window = window;
    global.document = document;
    global.HTMLElement = window.HTMLElement;
  });

  afterEach(() => {
    delete global.window;
    delete global.document;
    delete global.HTMLElement;
  });

  test("renders selection state and dispatches callbacks", () => {
    const panel = new WavePreviewPanel(container, defaultConfig);
    let selected = null;
    const entries = [
      {
        waveIndex: 0,
        lane: 0,
        tierId: "grunt",
        timeUntil: 1.2,
        scheduledTime: 1.2,
        isNextWave: false
      }
    ];

    panel.render(entries, {
      selectedTierId: "grunt",
      onSelect: (tierId) => {
        selected = tierId;
      }
    });

    const row = container.querySelector(".wave-preview-row");
    expect(row).not.toBeNull();
    expect(row?.dataset.selected).toBe("true");
    row?.dispatchEvent(new window.Event("click", { bubbles: true }));
    expect(selected).toBe("grunt");
  });
});

describe("Enemy biographies", () => {
  test("returns cataloged bios and falls back gracefully", () => {
    const grunt = getEnemyBiography("grunt", defaultConfig.enemyTiers["grunt"]);
    expect(grunt.name).toMatch(/Grunt/i);
    expect(Array.isArray(grunt.tips)).toBe(true);
    const unknown = getEnemyBiography("unknown-tier");
    expect(unknown.name).toBe("Unknown-tier");
    expect(unknown.description).toMatch(/Details on this enemy are still being gathered/i);
  });
});
