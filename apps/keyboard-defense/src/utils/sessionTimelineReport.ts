import type { WaveSummary } from "../core/types.js";

function csvEscape(value: string): string {
  if (!value) return "";
  if (!/[",\n]/.test(value)) return value;
  return `"${value.replace(/"/g, "\"\"")}"`;
}

function formatCount(value: unknown): string {
  if (typeof value !== "number" || !Number.isFinite(value)) return "";
  return Math.round(value).toString();
}

function formatFixed(value: unknown, digits: number): string {
  if (typeof value !== "number" || !Number.isFinite(value)) return "";
  return value.toFixed(digits);
}

function formatFlag(value: unknown): string {
  if (typeof value !== "boolean") return "";
  return value ? "true" : "false";
}

function formatText(value: unknown): string {
  if (typeof value !== "string") return "";
  return value;
}

export function buildSessionTimelineCsv(waves: WaveSummary[]): string {
  const headers = [
    "waveIndex",
    "mode",
    "durationSeconds",
    "accuracyPct",
    "enemiesDefeated",
    "breaches",
    "perfectWords",
    "goldEarned",
    "bonusGold",
    "castleBonusGold",
    "dps",
    "turretDps",
    "typingDps",
    "turretDamage",
    "typingDamage",
    "shieldBreaks",
    "repairsUsed",
    "repairHealth",
    "repairGold",
    "maxCombo",
    "sessionBestCombo",
    "averageReactionSeconds",
    "bossActive",
    "bossPhase",
    "bossLane"
  ];
  const lines: string[] = [headers.join(",")];
  if (!Array.isArray(waves) || waves.length === 0) return lines.join("\n");

  for (const wave of waves) {
    const row = [
      formatCount(wave?.index),
      formatText(wave?.mode),
      formatFixed(wave?.duration, 2),
      formatFixed((wave?.accuracy ?? 0) * 100, 1),
      formatCount(wave?.enemiesDefeated),
      formatCount(wave?.breaches),
      formatCount(wave?.perfectWords),
      formatCount(wave?.goldEarned),
      formatCount(wave?.bonusGold),
      formatCount(wave?.castleBonusGold),
      formatFixed(wave?.dps, 2),
      formatFixed(wave?.turretDps, 2),
      formatFixed(wave?.typingDps, 2),
      formatCount(wave?.turretDamage),
      formatCount(wave?.typingDamage),
      formatCount(wave?.shieldBreaks),
      formatCount(wave?.repairsUsed),
      formatCount(wave?.repairHealth),
      formatCount(wave?.repairGold),
      formatCount(wave?.maxCombo),
      formatCount(wave?.sessionBestCombo),
      formatFixed(wave?.averageReaction, 3),
      formatFlag(wave?.bossActive),
      formatText(wave?.bossPhase),
      typeof wave?.bossLane === "number" ? formatCount(wave.bossLane) : ""
    ];
    lines.push(row.map(csvEscape).join(","));
  }
  return lines.join("\n");
}

