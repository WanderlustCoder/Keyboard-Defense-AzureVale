import { describe, expect, test } from "vitest";
import { readFileSync } from "node:fs";
import { parseHTML } from "linkedom";

const htmlSource = readFileSync(new URL("../public/index.html", import.meta.url), "utf8");

const splitIdRefs = (value) =>
  String(value ?? "")
    .split(/\s+/)
    .map((entry) => entry.trim())
    .filter(Boolean);

describe("aria audit", () => {
  test("static HTML contains no duplicate ids", () => {
    const { document } = parseHTML(htmlSource).window;
    const counts = new Map();
    for (const el of document.querySelectorAll("[id]")) {
      const id = el.getAttribute("id");
      if (!id) continue;
      counts.set(id, (counts.get(id) ?? 0) + 1);
    }
    const duplicates = Array.from(counts.entries())
      .filter(([, count]) => count > 1)
      .map(([id, count]) => `${id} (${count})`);
    expect(duplicates).toEqual([]);
  });

  test("aria-labelledby, aria-describedby, and aria-controls references exist", () => {
    const { document } = parseHTML(htmlSource).window;
    const ids = new Set(
      Array.from(document.querySelectorAll("[id]"))
        .map((el) => el.getAttribute("id"))
        .filter(Boolean)
    );

    const audited = ["aria-labelledby", "aria-describedby", "aria-controls"];
    const missing = [];
    for (const attr of audited) {
      for (const el of document.querySelectorAll(`[${attr}]`)) {
        const value = el.getAttribute(attr);
        for (const ref of splitIdRefs(value)) {
          if (!ids.has(ref)) {
            missing.push({ attribute: attr, ref });
          }
        }
      }
    }
    expect(missing).toEqual([]);
  });

  test("dialogs are modal and labeled", () => {
    const { document } = parseHTML(htmlSource).window;
    const dialogs = Array.from(document.querySelectorAll('[role="dialog"], [role="alertdialog"]'));
    expect(dialogs.length).toBeGreaterThan(0);
    const failures = [];
    for (const dialog of dialogs) {
      const modal = dialog.getAttribute("aria-modal");
      if (modal !== "true") {
        failures.push({ kind: "aria-modal", id: dialog.getAttribute("id") });
      }
      const labeledBy = splitIdRefs(dialog.getAttribute("aria-labelledby"));
      const label = String(dialog.getAttribute("aria-label") ?? "").trim();
      if (labeledBy.length === 0 && !label) {
        failures.push({ kind: "label", id: dialog.getAttribute("id") });
      }
    }
    expect(failures).toEqual([]);
  });
});

