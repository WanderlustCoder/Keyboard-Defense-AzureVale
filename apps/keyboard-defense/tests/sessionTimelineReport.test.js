import { describe, expect, test } from "vitest";
import { buildSessionTimelineCsv } from "../src/utils/sessionTimelineReport.ts";

describe("sessionTimelineReport", () => {
  test("buildSessionTimelineCsv renders header and wave rows", () => {
    const csv = buildSessionTimelineCsv([
      {
        index: 1,
        mode: "campaign",
        duration: 30.1,
        accuracy: 0.957,
        enemiesDefeated: 18,
        breaches: 1,
        perfectWords: 5,
        dps: 47.8,
        goldEarned: 132,
        bonusGold: 45,
        castleBonusGold: 12,
        maxCombo: 6,
        sessionBestCombo: 9,
        turretDamage: 226,
        typingDamage: 156,
        turretDps: 28.3333,
        typingDps: 19.5,
        shieldBreaks: 3,
        repairsUsed: 2,
        repairHealth: 180,
        repairGold: 150,
        averageReaction: 1.23,
        bossActive: false
      },
      {
        index: 2,
        mode: "practice",
        duration: 42,
        accuracy: 1,
        enemiesDefeated: 22,
        breaches: 0,
        perfectWords: 8,
        dps: 60.1234,
        goldEarned: 200,
        bonusGold: 0,
        castleBonusGold: 0,
        maxCombo: 10,
        sessionBestCombo: 10,
        turretDamage: 300,
        typingDamage: 200,
        turretDps: 40.5,
        typingDps: 19.6,
        shieldBreaks: 4,
        repairsUsed: 0,
        repairHealth: 0,
        repairGold: 0,
        averageReaction: 0.98765,
        bossActive: true,
        bossPhase: "phase-1",
        bossLane: 2
      }
    ]);

    const lines = csv.split("\n");
    expect(lines[0]).toBe(
      [
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
      ].join(",")
    );
    expect(lines[1]).toBe(
      [
        "1",
        "campaign",
        "30.10",
        "95.7",
        "18",
        "1",
        "5",
        "132",
        "45",
        "12",
        "47.80",
        "28.33",
        "19.50",
        "226",
        "156",
        "3",
        "2",
        "180",
        "150",
        "6",
        "9",
        "1.230",
        "false",
        "",
        ""
      ].join(",")
    );
    expect(lines[2]).toBe(
      [
        "2",
        "practice",
        "42.00",
        "100.0",
        "22",
        "0",
        "8",
        "200",
        "0",
        "0",
        "60.12",
        "40.50",
        "19.60",
        "300",
        "200",
        "4",
        "0",
        "0",
        "0",
        "10",
        "10",
        "0.988",
        "true",
        "phase-1",
        "2"
      ].join(",")
    );
  });

  test("buildSessionTimelineCsv returns header for empty input", () => {
    const csv = buildSessionTimelineCsv([]);
    expect(csv.split("\n")).toHaveLength(1);
    expect(csv).toContain("waveIndex,mode");
  });
});
