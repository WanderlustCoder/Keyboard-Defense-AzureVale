import { promises as fs } from "node:fs";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";

async function collectTargets(args) {
  const targets = [];
  for (const arg of args) {
    const full = path.resolve(arg);
    let stat;
    try {
      stat = await fs.stat(full);
    } catch (error) {
      console.warn(`analyticsAggregate: skipping ${arg} (${error?.message ?? "unreadable"})`);
      continue;
    }
    if (stat.isDirectory()) {
      const entries = await fs.readdir(full);
      for (const entry of entries) {
        if (entry.toLowerCase().endsWith(".json")) {
          targets.push(path.join(full, entry));
        }
      }
    } else if (stat.isFile()) {
      targets.push(full);
    }
  }
  return targets;
}

function escapeCsv(value) {
  if (value === null || value === undefined) return "";
  const string = String(value);
  if (/[",\n]/.test(string)) {
    return `"${string.replace(/"/g, '""')}"`;
  }
  return string;
}

function formatNumber(value, precision = 2) {
  if (!Number.isFinite(value)) {
    const fallback = Number(value ?? 0);
    return Number.isFinite(fallback) ? fallback : 0;
  }
  const factor = 10 ** precision;
  return Math.round(value * factor) / factor;
}

function boolOrEmpty(value) {
  return typeof value === "boolean" ? value : "";
}

function formatTurretStats(turretStats) {
  if (!Array.isArray(turretStats) || turretStats.length === 0) {
    return "";
  }
  return turretStats
    .map((stat) => {
      if (!stat || typeof stat !== "object") {
        return "";
      }
      const slot = stat.slotId ?? "";
      const type = stat.turretType ? String(stat.turretType) : "empty";
      const level = stat.level === null || stat.level === undefined ? "" : `L${stat.level}`;
      const damage = formatNumber(Number(stat.damage ?? 0));
      const dps = formatNumber(Number(stat.dps ?? 0));
      return `${slot}:${type}${level ? ` ${level}` : ""} dmg=${damage} dps=${dps}`;
    })
    .filter((entry) => entry.length > 0)
    .join(" | ");
}

function formatPassiveUnlockEntry(unlock) {
  if (!unlock || typeof unlock !== "object") {
    return "";
  }
  const labelMap = { regen: "Regen", armor: "Armor", gold: "Gold" };
  const id = typeof unlock.id === "string" ? unlock.id : "";
  const label = labelMap[id] ?? "Passive";
  const level = Number.isFinite(unlock.level) ? ` L${unlock.level}` : "";
  const deltaValue = Number.isFinite(unlock.delta) ? unlock.delta : 0;
  const totalValue = Number.isFinite(unlock.total) ? unlock.total : 0;

  let detail = "";
  switch (id) {
    case "regen": {
      const total = formatNumber(totalValue, 2);
      const delta = deltaValue > 0 ? ` (+${formatNumber(deltaValue, 2)})` : "";
      detail = `${total} HP/s${delta}`;
      break;
    }
    case "armor": {
      const total = Math.round(totalValue);
      const delta = Math.round(deltaValue);
      const deltaNote = delta > 0 ? ` (+${delta})` : "";
      detail = `+${total} armor${deltaNote}`;
      break;
    }
    case "gold": {
      const total = Math.round(totalValue * 100);
      const delta = Math.round(deltaValue * 100);
      const deltaNote = delta > 0 ? ` (+${delta}%)` : "";
      detail = `+${total}% gold${deltaNote}`;
      break;
    }
    default: {
      const total = formatNumber(totalValue, 2);
      const delta = deltaValue > 0 ? ` (+${formatNumber(deltaValue, 2)})` : "";
      detail = `${total}${delta}`;
    }
  }

  const time =
    unlock.time !== undefined && Number.isFinite(unlock.time)
      ? ` @ ${formatNumber(unlock.time, 2)}s`
      : "";

  return `${label}${level} ${detail}${time}`.trim();
}

function formatPassiveUnlockList(unlocks) {
  if (!Array.isArray(unlocks) || unlocks.length === 0) {
    return "";
  }
  return unlocks
    .map((unlock) => formatPassiveUnlockEntry(unlock))
    .filter((entry) => entry.length > 0)
    .join(" | ");
}

function formatTauntCounts(counts) {
  if (!counts || typeof counts !== "object") {
    return "";
  }
  const entries = Object.entries(counts)
    .map(([wave, value]) => {
      const waveIndex = Number(wave);
      const count = Number(value);
      if (!Number.isFinite(count)) {
        return null;
      }
      const label = Number.isFinite(waveIndex) ? `W${waveIndex}` : wave;
      return `${label}:${count}`;
    })
    .filter((entry) => entry);
  return entries.length > 0 ? entries.join(" | ") : "";
}

function formatTauntUniqueLines(lines) {
  if (!Array.isArray(lines) || lines.length === 0) {
    return "";
  }
  return lines
    .filter((line) => typeof line === "string" && line.trim().length > 0)
    .map((line) => line.trim())
    .join(" | ");
}

function* summarizeSnapshot(snapshot, sourcePath) {
  const summaries = snapshot?.analytics?.waveSummaries?.length
    ? snapshot.analytics.waveSummaries
    : snapshot?.analytics?.waveHistory;
  const telemetry = snapshot?.telemetry ?? null;
  const telemetryQueueSize =
    typeof telemetry?.queueSize === "number"
      ? telemetry.queueSize
      : Array.isArray(telemetry?.queue)
        ? telemetry.queue.length
        : "";
  const modeValue = snapshot?.mode ?? snapshot?.analytics?.mode ?? "";
  const practiceFlag = modeValue === "practice" ? "yes" : modeValue === "campaign" ? "no" : "";
  const soundEnabledValue =
    typeof snapshot?.settings?.soundEnabled === "boolean"
      ? snapshot.settings.soundEnabled
      : typeof snapshot?.soundEnabled === "boolean"
        ? snapshot.soundEnabled
        : "";
  const soundVolumeValue =
    typeof snapshot?.settings?.soundVolume === "number"
      ? Math.round(snapshot.settings.soundVolume * 100) / 100
      : typeof snapshot?.soundVolume === "number"
        ? Math.round(snapshot.soundVolume * 100) / 100
        : "";
  const soundIntensityValue =
    typeof snapshot?.settings?.soundIntensity === "number"
      ? Math.round(snapshot.settings.soundIntensity * 100) / 100
      : typeof snapshot?.soundIntensity === "number"
        ? Math.round(snapshot.soundIntensity * 100) / 100
        : "";
  const turretStatsValue = formatTurretStats(snapshot?.turretStats);
  const metadata = {
    file: sourcePath,
    capturedAt: snapshot?.capturedAt ?? "",
    status: snapshot?.status ?? "",
    soundEnabled: soundEnabledValue,
    soundVolume: soundVolumeValue,
    sessionBreaches: snapshot?.analytics?.sessionBreaches ?? "",
    sessionBestCombo: snapshot?.analytics?.sessionBestCombo ?? "",
    totalDamageDealt: snapshot?.analytics?.totalDamageDealt ?? "",
    totalTurretDamage:
      snapshot?.analytics?.totalTurretDamage ?? snapshot?.analytics?.totalDamageDealt ?? "",
    totalTypingDamage: snapshot?.analytics?.totalTypingDamage ?? "",
    totalShieldBreaks: snapshot?.analytics?.totalShieldBreaks ?? "",
    totalCastleRepairs: snapshot?.analytics?.totalCastleRepairs ?? "",
    totalRepairHealth: snapshot?.analytics?.totalRepairHealth ?? "",
    totalRepairGold: snapshot?.analytics?.totalRepairGold ?? "",
    totalPerfectWords: snapshot?.analytics?.totalPerfectWords ?? "",
    totalBonusGold: snapshot?.analytics?.totalBonusGold ?? "",
    totalCastleBonusGold: snapshot?.analytics?.totalCastleBonusGold ?? "",
    totalReactionTime: snapshot?.analytics?.totalReactionTime ?? "",
    reactionSamples: snapshot?.analytics?.reactionSamples ?? "",
    averageTotalDps: snapshot?.analytics?.averageTotalDps ?? "",
    averageTurretDps: snapshot?.analytics?.averageTurretDps ?? "",
    averageTypingDps: snapshot?.analytics?.averageTypingDps ?? "",
    tutorialAttempts: snapshot?.analytics?.tutorial?.attemptedRuns ?? "",
    tutorialAssists: snapshot?.analytics?.tutorial?.assistsShown ?? "",
    tutorialCompletions: snapshot?.analytics?.tutorial?.completedRuns ?? "",
    tutorialReplays: snapshot?.analytics?.tutorial?.replayedRuns ?? "",
    tutorialSkips: snapshot?.analytics?.tutorial?.skippedRuns ?? "",
    time: snapshot?.time ?? "",
    timeToFirstTurret:
      typeof snapshot?.analytics?.timeToFirstTurret === "number"
        ? snapshot.analytics.timeToFirstTurret
        : (snapshot?.analytics?.timeToFirstTurret ?? ""),
    telemetryAvailable:
      typeof telemetry?.available === "boolean"
        ? telemetry.available
        : telemetry
          ? Boolean(telemetry.available)
          : "",
    telemetryEnabled:
      typeof telemetry?.enabled === "boolean"
        ? telemetry.enabled
        : telemetry
          ? Boolean(telemetry.enabled)
          : "",
    telemetryEndpoint: telemetry?.endpoint ?? "",
    telemetryQueueSize: telemetryQueueSize === "" ? "" : telemetryQueueSize,
    waveIndex: snapshot?.wave?.index ?? "",
    waveTotal: snapshot?.wave?.total ?? "",
    mode: modeValue,
    practiceMode: practiceFlag,
    turretStats: turretStatsValue
  };
  metadata.soundIntensity = soundIntensityValue;
  const uiSnapshot = snapshot?.ui ?? null;
  const tutorialBannerUi = uiSnapshot?.tutorialBanner ?? {};
  const hudUi = uiSnapshot?.hud ?? {};
  const optionsUi = uiSnapshot?.options ?? {};
  const diagnosticsUi = uiSnapshot?.diagnostics ?? {};
  const preferencesUi = uiSnapshot?.preferences ?? {};
  metadata.uiCompactHeight = boolOrEmpty(uiSnapshot?.compactHeight);
  metadata.uiTutorialCondensed = boolOrEmpty(tutorialBannerUi?.condensed);
  metadata.uiTutorialExpanded = boolOrEmpty(tutorialBannerUi?.expanded);
  metadata.uiHudPassivesCollapsed = boolOrEmpty(hudUi?.passivesCollapsed);
  metadata.uiHudGoldEventsCollapsed = boolOrEmpty(hudUi?.goldEventsCollapsed);
  metadata.uiHudPrefersCondensed = boolOrEmpty(hudUi?.prefersCondensedLists);
  metadata.uiOptionsPassivesCollapsed = boolOrEmpty(optionsUi?.passivesCollapsed);
  metadata.uiDiagnosticsCondensed = boolOrEmpty(diagnosticsUi?.condensed);
  metadata.uiDiagnosticsSectionsCollapsed = boolOrEmpty(diagnosticsUi?.sectionsCollapsed);
  metadata.uiPrefHudPassivesCollapsed = boolOrEmpty(preferencesUi?.hudPassivesCollapsed);
  metadata.uiPrefHudGoldEventsCollapsed = boolOrEmpty(preferencesUi?.hudGoldEventsCollapsed);
  metadata.uiPrefOptionsPassivesCollapsed = boolOrEmpty(preferencesUi?.optionsPassivesCollapsed);

  const passiveUnlocks = Array.isArray(snapshot?.analytics?.castlePassiveUnlocks)
    ? snapshot.analytics.castlePassiveUnlocks
    : [];
  const passiveUnlockCount = passiveUnlocks.length;
  const lastPassiveUnlock = passiveUnlockCount > 0 ? passiveUnlocks[passiveUnlockCount - 1] : null;
  metadata.passiveUnlockCount = passiveUnlockCount;
  metadata.lastPassiveUnlock = formatPassiveUnlockEntry(lastPassiveUnlock);
  metadata.castlePassiveUnlocks = formatPassiveUnlockList(passiveUnlocks);

  const goldEvents = Array.isArray(snapshot?.analytics?.goldEvents)
    ? snapshot.analytics.goldEvents
    : [];
  const goldEventCount = goldEvents.length;
  const lastGoldEvent = goldEventCount > 0 ? goldEvents[goldEventCount - 1] : null;
  metadata.goldEventsTracked = goldEventCount;
  metadata.lastGoldDelta =
    lastGoldEvent && Number.isFinite(lastGoldEvent.delta)
      ? formatNumber(lastGoldEvent.delta, 2)
      : "";
  metadata.lastGoldEventTime =
    lastGoldEvent && Number.isFinite(lastGoldEvent.timestamp)
      ? formatNumber(lastGoldEvent.timestamp, 2)
      : "";
  const tauntState = snapshot?.analytics?.taunt ?? null;
  metadata.tauntActive =
    typeof tauntState?.active === "boolean" ? String(tauntState.active) : tauntState ? "false" : "";
  metadata.tauntText =
    typeof tauntState?.text === "string" && tauntState.text.length > 0 ? tauntState.text : "";
  metadata.tauntEnemyType =
    typeof tauntState?.enemyType === "string" ? tauntState.enemyType : "";
  metadata.tauntWaveIndex =
    typeof tauntState?.waveIndex === "number" ? tauntState.waveIndex : "";
  metadata.tauntLane = typeof tauntState?.lane === "number" ? tauntState.lane : "";
  metadata.tauntTimestamp =
    typeof tauntState?.timestampMs === "number"
      ? formatNumber(tauntState.timestampMs, 2)
      : "";
  metadata.tauntId = typeof tauntState?.id === "string" ? tauntState.id : "";
  metadata.tauntCountPerWave = formatTauntCounts(tauntState?.countPerWave);
  metadata.tauntUniqueLines = formatTauntUniqueLines(
    Array.isArray(tauntState?.uniqueLines) ? tauntState.uniqueLines : []
  );

  if (Array.isArray(summaries) && summaries.length > 0) {
    for (const summary of summaries) {
      yield {
        ...metadata,
        summaryWave: summary.index ?? "",
        mode: summary.mode ?? metadata.mode,
        practiceMode:
          summary.mode === "practice"
            ? "yes"
            : summary.mode === "campaign"
              ? "no"
              : metadata.practiceMode,
        duration: summary.duration ?? "",
        accuracy: summary.accuracy ?? "",
        enemiesDefeated: summary.enemiesDefeated ?? "",
        breaches: summary.breaches ?? "",
        perfectWords: summary.perfectWords ?? "",
        averageReaction: summary.averageReaction ?? "",
        dps: summary.dps ?? "",
        turretDps: summary.turretDps ?? "",
        typingDps: summary.typingDps ?? "",
        turretDamage: summary.turretDamage ?? "",
        typingDamage: summary.typingDamage ?? "",
        shieldBreaks: summary.shieldBreaks ?? "",
        repairsUsed: summary.repairsUsed ?? "",
        repairHealth: summary.repairHealth ?? "",
        repairGold: summary.repairGold ?? "",
        bonusGold: summary.bonusGold ?? "",
        castleBonusGold: summary.castleBonusGold ?? "",
        goldEarned: summary.goldEarned ?? "",
        maxCombo: summary.maxCombo ?? "",
        sessionBestCombo: summary.sessionBestCombo ?? metadata.sessionBestCombo
      };
    }
  } else {
    yield {
      ...metadata,
      summaryWave: snapshot?.wave?.index ?? "",
      mode: metadata.mode,
      practiceMode: metadata.practiceMode,
      duration: "",
      accuracy: snapshot?.typing?.accuracy ?? "",
      enemiesDefeated: "",
      breaches: snapshot?.analytics?.sessionBreaches ?? "",
      perfectWords: "",
      averageReaction: "",
      dps: "",
      turretDps: "",
      typingDps: "",
      turretDamage: "",
      typingDamage: "",
      shieldBreaks: "",
      repairsUsed: "",
      repairHealth: "",
      repairGold: "",
      bonusGold: "",
      castleBonusGold: "",
      goldEarned: "",
      maxCombo: snapshot?.typing?.combo ?? "",
      sessionBestCombo: metadata.sessionBestCombo
    };
  }
}

async function loadSnapshot(file) {
  try {
    const raw = await fs.readFile(file, "utf8");
    return JSON.parse(raw);
  } catch (error) {
    console.warn(`analyticsAggregate: failed to parse ${file}: ${error?.message ?? error}`);
    return null;
  }
}

function printCsv(rows) {
  const headers = [
    "file",
    "capturedAt",
    "status",
    "time",
    "telemetryAvailable",
    "telemetryEnabled",
    "telemetryEndpoint",
    "telemetryQueueSize",
    "soundEnabled",
    "soundVolume",
    "soundIntensity",
    "uiCompactHeight",
    "uiTutorialCondensed",
    "uiTutorialExpanded",
    "uiHudPassivesCollapsed",
    "uiHudGoldEventsCollapsed",
    "uiHudPrefersCondensed",
    "uiOptionsPassivesCollapsed",
    "uiDiagnosticsCondensed",
    "uiDiagnosticsSectionsCollapsed",
    "uiPrefHudPassivesCollapsed",
    "uiPrefHudGoldEventsCollapsed",
    "uiPrefOptionsPassivesCollapsed",
    "timeToFirstTurret",
    "waveIndex",
    "waveTotal",
    "mode",
    "practiceMode",
    "turretStats",
    "summaryWave",
    "duration",
    "accuracy",
    "enemiesDefeated",
    "breaches",
    "perfectWords",
    "averageReaction",
    "dps",
    "turretDps",
    "typingDps",
    "turretDamage",
    "typingDamage",
    "shieldBreaks",
    "repairsUsed",
    "repairHealth",
    "repairGold",
    "bonusGold",
    "castleBonusGold",
    "passiveUnlockCount",
    "lastPassiveUnlock",
    "castlePassiveUnlocks",
    "goldEventsTracked",
    "lastGoldDelta",
    "lastGoldEventTime",
    "tauntActive",
    "tauntText",
    "tauntEnemyType",
    "tauntWaveIndex",
    "tauntLane",
    "tauntTimestamp",
    "tauntId",
    "tauntCountPerWave",
    "tauntUniqueLines",
    "goldEarned",
    "maxCombo",
    "sessionBestCombo",
    "sessionBreaches",
    "totalDamageDealt",
    "totalTurretDamage",
    "totalTypingDamage",
    "totalShieldBreaks",
    "totalCastleRepairs",
    "totalRepairHealth",
    "totalRepairGold",
    "totalPerfectWords",
    "totalBonusGold",
    "totalCastleBonusGold",
    "totalReactionTime",
    "reactionSamples",
    "averageTotalDps",
    "averageTurretDps",
    "averageTypingDps",
    "tutorialAttempts",
    "tutorialAssists",
    "tutorialCompletions",
    "tutorialReplays",
    "tutorialSkips"
  ];
  console.log(headers.join(","));
  for (const row of rows) {
    const line = headers.map((header) => escapeCsv(row[header] ?? "")).join(",");
    console.log(line);
  }
}

function printUsage() {
  console.error("Usage: node scripts/analyticsAggregate.mjs <file-or-directory> [...]");
  console.error("Scans analytics JSON exports and prints a CSV summary to stdout.");
}

async function main(argv) {
  const args = argv.filter((arg) => !arg.startsWith("-"));
  const helpRequested = argv.includes("--help") || argv.includes("-h");

  if (helpRequested) {
    printUsage();
    return 0;
  }

  if (args.length === 0) {
    printUsage();
    return 1;
  }

  const files = await collectTargets(args);
  if (files.length === 0) {
    console.error("analyticsAggregate: no JSON snapshots found for provided arguments.");
    return 1;
  }

  const rows = [];
  for (const file of files) {
    const snapshot = await loadSnapshot(file);
    if (!snapshot) continue;
    for (const row of summarizeSnapshot(snapshot, file)) {
      rows.push(row);
    }
  }

  if (rows.length === 0) {
    console.error("analyticsAggregate: no analytics data could be derived.");
    return 1;
  }

  printCsv(rows);
  return 0;
}

const isCliInvocation =
  typeof process.argv[1] === "string" &&
  fileURLToPath(import.meta.url) === path.resolve(process.argv[1]);

if (isCliInvocation) {
  const exitCode = await main(process.argv.slice(2));
  process.exit(exitCode);
}

export { collectTargets, summarizeSnapshot, printCsv, main };
