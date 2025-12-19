import { test } from "vitest";
import assert from "node:assert/strict";
import fs from "node:fs/promises";

import { defaultWordBank } from "../src/core/wordBank.ts";
import { gradeEntries, scoreEntry } from "../scripts/wordlistReadability.mjs";

test("readability scoring increases with complexity", () => {
  const tiny = scoreEntry("aa");
  const easy = scoreEntry("arrow");
  const hard = scoreEntry("impenetrable");
  assert.ok(tiny.recommendedAge <= easy.recommendedAge);
  assert.ok(easy.recommendedAge <= hard.recommendedAge);
  assert.ok(tiny.score <= easy.score);
  assert.ok(easy.score <= hard.score);
});

test("default word bank stays within the age-appropriate envelope", () => {
  const easy = gradeEntries(defaultWordBank.easy);
  const medium = gradeEntries(defaultWordBank.medium);
  const hard = gradeEntries(defaultWordBank.hard);

  assert.ok(easy.count > 0);
  assert.ok(medium.count > 0);
  assert.ok(hard.count > 0);

  assert.ok(easy.recommendedAge.p90 <= 12);
  assert.ok(medium.recommendedAge.p90 <= 14);
  assert.ok(hard.recommendedAge.p90 <= 16);

  assert.ok(easy.tokens.maxTokenLength <= 16);
  assert.ok(medium.tokens.maxTokenLength <= 16);
  assert.ok(hard.tokens.maxTokenLength <= 16);

  assert.ok(easy.punctuation.maxHardPunctuation <= 2);
  assert.ok(medium.punctuation.maxHardPunctuation <= 2);
  assert.ok(hard.punctuation.maxHardPunctuation <= 2);
});

test("wordlist JSON files avoid overly complex punctuation and phrases", async () => {
  const wordlistDir = new URL("../data/wordlists/", import.meta.url);
  const entries = await fs.readdir(wordlistDir, { withFileTypes: true });
  const jsonFiles = entries
    .filter((entry) => entry.isFile() && entry.name.toLowerCase().endsWith(".json"))
    .map((entry) => entry.name);

  assert.ok(jsonFiles.length > 0);

  for (const file of jsonFiles) {
    const fullPath = new URL(`../data/wordlists/${file}`, import.meta.url);
    const raw = await fs.readFile(fullPath, "utf8");
    const json = JSON.parse(raw);
    const words = Array.isArray(json.words) ? json.words : [];
    const summary = gradeEntries(words);

    assert.ok(summary.punctuation.maxHardPunctuation <= 2, `${file} has too much punctuation`);
    assert.ok(summary.tokens.maxTokenCount <= 6, `${file} has overly long phrases`);
    assert.ok(summary.tokens.maxTokenLength <= 16, `${file} has overly long tokens`);
  }
});
