import { describe, expect, test } from "vitest";
import { readFileSync } from "node:fs";
import { parseHTML } from "linkedom";

import { listEnemyBiographies } from "../src/data/bestiary.ts";
import { DIALOGUE_LYRA } from "../src/data/dialogue.ts";
import { getEliteAffixCatalog } from "../src/data/eliteAffixes.ts";
import { loadingTips } from "../src/data/loadingTips.ts";
import { LORE_ENTRIES } from "../src/data/lore.ts";
import { LORE_SCROLLS } from "../src/data/loreScrolls.ts";
import { SEASON_ROADMAP } from "../src/data/roadmap.ts";
import { listSeasonTrack } from "../src/data/seasonTrack.ts";
import { TAUNT_CATALOG } from "../src/data/taunts.js";

const TOKEN_REGEX = /[a-z0-9]+(?:[-'][a-z0-9]+)*/gi;
const TOKEN_WHOLE_REGEX = /^[a-z0-9]+(?:[-'][a-z0-9]+)*$/i;

function readDenylist() {
  const raw = readFileSync(new URL("../data/wordlists/denylist.txt", import.meta.url), "utf8");
  const entries = raw
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => line && !line.startsWith("#"))
    .map((line) => line.toLowerCase());
  return entries;
}

function summarizeSnippet(text, index) {
  const start = Math.max(0, index - 45);
  const end = Math.min(text.length, index + 45);
  return text
    .slice(start, end)
    .replace(/\s+/g, " ")
    .trim();
}

function findDenylistHits({ source, text, denylist }) {
  const hits = [];
  const haystack = String(text ?? "");
  if (!haystack) return hits;
  for (const match of haystack.matchAll(TOKEN_REGEX)) {
    const token = (match[0] ?? "").toLowerCase();
    if (!token || !denylist.has(token)) continue;
    hits.push({
      source,
      token,
      snippet: summarizeSnippet(haystack, match.index ?? 0)
    });
  }
  return hits;
}

function validateDenylist(entries) {
  const failures = [];
  const seen = new Set();
  for (const entry of entries) {
    if (entry !== entry.toLowerCase()) {
      failures.push(`denylist entry must be lowercase: "${entry}"`);
    }
    if (!TOKEN_WHOLE_REGEX.test(entry)) {
      failures.push(`denylist entry must be a single token: "${entry}"`);
    }
    if (seen.has(entry)) {
      failures.push(`denylist entry duplicated: "${entry}"`);
    }
    seen.add(entry);
  }
  return failures;
}

function scanIndexHtml(denylist) {
  const hits = [];
  const html = readFileSync(new URL("../public/index.html", import.meta.url), "utf8");
  const { document } = parseHTML(html).window;
  for (const el of document.querySelectorAll("script, style")) {
    el.remove();
  }

  hits.push(
    ...findDenylistHits({
      source: "public/index.html text",
      text: document.documentElement?.textContent ?? "",
      denylist
    })
  );

  const attributeNames = ["aria-label", "title", "alt", "placeholder", "aria-roledescription"];
  for (const attributeName of attributeNames) {
    for (const el of document.querySelectorAll(`[${attributeName}]`)) {
      const value = el.getAttribute(attributeName);
      if (!value) continue;
      const tag = String(el.tagName ?? "element").toLowerCase();
      const id = el.getAttribute("id");
      const source = `public/index.html ${tag}${id ? `#${id}` : ""} [${attributeName}]`;
      hits.push(...findDenylistHits({ source, text: value, denylist }));
    }
  }

  return hits;
}

function scanContentCatalogs(denylist) {
  const hits = [];

  for (const [index, tip] of loadingTips.entries()) {
    hits.push(...findDenylistHits({ source: `loadingTips[${index}]`, text: tip, denylist }));
  }

  for (const reward of listSeasonTrack()) {
    hits.push(
      ...findDenylistHits({
        source: `seasonTrack[${reward.id}].title`,
        text: reward.title,
        denylist
      }),
      ...findDenylistHits({
        source: `seasonTrack[${reward.id}].description`,
        text: reward.description,
        denylist
      })
    );
  }

  hits.push(
    ...findDenylistHits({
      source: "seasonRoadmap.season",
      text: SEASON_ROADMAP.season,
      denylist
    }),
    ...findDenylistHits({
      source: "seasonRoadmap.theme",
      text: SEASON_ROADMAP.theme,
      denylist
    })
  );
  for (const item of SEASON_ROADMAP.items ?? []) {
    hits.push(
      ...findDenylistHits({
        source: `seasonRoadmap[${item.id}].title`,
        text: item.title,
        denylist
      }),
      ...findDenylistHits({
        source: `seasonRoadmap[${item.id}].milestone`,
        text: item.milestone,
        denylist
      }),
      ...findDenylistHits({
        source: `seasonRoadmap[${item.id}].summary`,
        text: item.summary,
        denylist
      }),
      ...findDenylistHits({
        source: `seasonRoadmap[${item.id}].reward`,
        text: item.reward ?? "",
        denylist
      })
    );
  }

  for (const enemy of listEnemyBiographies()) {
    hits.push(
      ...findDenylistHits({
        source: `bestiary[${enemy.id}].name`,
        text: enemy.name,
        denylist
      }),
      ...findDenylistHits({
        source: `bestiary[${enemy.id}].role`,
        text: enemy.role,
        denylist
      }),
      ...findDenylistHits({
        source: `bestiary[${enemy.id}].danger`,
        text: enemy.danger,
        denylist
      }),
      ...findDenylistHits({
        source: `bestiary[${enemy.id}].description`,
        text: enemy.description,
        denylist
      })
    );
    for (const [index, ability] of (enemy.abilities ?? []).entries()) {
      hits.push(
        ...findDenylistHits({
          source: `bestiary[${enemy.id}].abilities[${index}]`,
          text: ability,
          denylist
        })
      );
    }
    for (const [index, tip] of (enemy.tips ?? []).entries()) {
      hits.push(
        ...findDenylistHits({
          source: `bestiary[${enemy.id}].tips[${index}]`,
          text: tip,
          denylist
        })
      );
    }
  }

  for (const affix of getEliteAffixCatalog()) {
    hits.push(
      ...findDenylistHits({
        source: `eliteAffixes[${affix.id}].label`,
        text: affix.label,
        denylist
      }),
      ...findDenylistHits({
        source: `eliteAffixes[${affix.id}].description`,
        text: affix.description,
        denylist
      })
    );
  }

  hits.push(
    ...findDenylistHits({
      source: "dialogueLyra.speaker",
      text: DIALOGUE_LYRA.speaker,
      denylist
    }),
    ...findDenylistHits({
      source: "dialogueLyra.episode",
      text: DIALOGUE_LYRA.episode,
      denylist
    })
  );
  for (const entry of DIALOGUE_LYRA.entries ?? []) {
    hits.push(
      ...findDenylistHits({
        source: `dialogueLyra[${entry.id}].text`,
        text: entry.text,
        denylist
      })
    );
  }

  for (const entry of TAUNT_CATALOG ?? []) {
    hits.push(
      ...findDenylistHits({
        source: `taunts[${entry.id}].text`,
        text: entry.text,
        denylist
      })
    );
  }

  for (const entry of LORE_ENTRIES ?? []) {
    hits.push(
      ...findDenylistHits({
        source: `lore[${entry.id}].title`,
        text: entry.title,
        denylist
      }),
      ...findDenylistHits({
        source: `lore[${entry.id}].summary`,
        text: entry.summary,
        denylist
      }),
      ...findDenylistHits({
        source: `lore[${entry.id}].body`,
        text: entry.body ?? "",
        denylist
      })
    );
  }

  for (const entry of LORE_SCROLLS ?? []) {
    hits.push(
      ...findDenylistHits({
        source: `loreScrolls[${entry.id}].title`,
        text: entry.title,
        denylist
      }),
      ...findDenylistHits({
        source: `loreScrolls[${entry.id}].summary`,
        text: entry.summary,
        denylist
      }),
      ...findDenylistHits({
        source: `loreScrolls[${entry.id}].body`,
        text: entry.body ?? "",
        denylist
      })
    );
  }

  return hits;
}

describe("content safety audit", () => {
  test("denylist terms are absent from user-facing content", () => {
    const entries = readDenylist();
    expect(entries.length).toBeGreaterThan(0);

    const denylistFailures = validateDenylist(entries);
    expect(denylistFailures).toEqual([]);

    const denylist = new Set(entries);
    const hits = [
      ...scanIndexHtml(denylist),
      ...scanContentCatalogs(denylist)
    ].sort((a, b) => a.source.localeCompare(b.source) || a.token.localeCompare(b.token));

    expect(hits).toEqual([]);
  });
});
