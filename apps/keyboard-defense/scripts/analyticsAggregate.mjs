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

function formatDiagnosticsSections(value) {
  if (!value || typeof value !== "object") {
    return "";
  }
  const parts = [];
  for (const [key, flag] of Object.entries(value)) {
    if (typeof flag === "boolean") {
      parts.push(`${key}:${flag ? "collapsed" : "expanded"}`);
    }
  }
  return parts.join(" | ");
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

function formatResolutionChange(entry) {
  if (!entry || typeof entry !== "object") {
    return "";
  }
  const cause = entry.cause ?? "auto";
  const from =
    Number.isFinite(entry.fromDpr) || Number.isFinite(entry.previousDpr)
      ? formatNumber(entry.fromDpr ?? entry.previousDpr ?? 0, 2)
      : "?";
  const to =
    Number.isFinite(entry.toDpr) || Number.isFinite(entry.nextDpr)
      ? formatNumber(entry.toDpr ?? entry.nextDpr ?? 0, 2)
      : "?";
  const cssWidth = Number.isFinite(entry.cssWidth) ? Math.round(entry.cssWidth) : "?";
  const renderWidth = Number.isFinite(entry.renderWidth) ? Math.round(entry.renderWidth) : "?";
  return `${cause}:${from}->${to} (${cssWidth}->${renderWidth})`;
}

function formatResolutionChanges(entries) {
  if (!Array.isArray(entries) || entries.length === 0) {
    return "";
  }
  return entries
    .map((entry) => formatResolutionChange(entry))
    .filter((line) => line.length > 0)
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

function formatAssetIntegrityFailure(failure) {
  if (!failure || typeof failure !== "object") {
    return "";
  }
  const path =
    typeof failure.path === "string" && failure.path.length > 0
      ? failure.path
      : typeof failure.key === "string"
        ? failure.key
        : null;
  const mapped = path && failure.key && failure.key !== path ? `${path} (${failure.key})` : path ?? "-";
  const typeLabel = typeof failure.type === "string" ? failure.type : "unknown";
  return `${mapped} [${typeLabel}]`;
}

function normalizeAudioIntensityHistory(history) {
  if (!Array.isArray(history)) {
    return [];
  }
  return history
    .map((entry) => {
      if (!entry || typeof entry !== "object") {
        return null;
      }
      const toValue = Number.isFinite(entry.to) ? Number(entry.to) : null;
      const comboValue = Number.isFinite(entry.combo) ? Number(entry.combo) : null;
      const accuracyValue = Number.isFinite(entry.accuracy) ? Number(entry.accuracy) : null;
      if (toValue === null && comboValue === null && accuracyValue === null) {
        return null;
      }
      return {
        to: toValue,
        combo: comboValue,
        accuracy: accuracyValue
      };
    })
    .filter((entry) => entry);
}

function computeCorrelation(pairs) {
  if (!Array.isArray(pairs) || pairs.length < 2) {
    return null;
  }
  const xs = pairs.map((pair) => pair.x);
  const ys = pairs.map((pair) => pair.y);
  const meanX = xs.reduce((sum, value) => sum + value, 0) / xs.length;
  const meanY = ys.reduce((sum, value) => sum + value, 0) / ys.length;
  let numerator = 0;
  let denomX = 0;
  let denomY = 0;
  for (let i = 0; i < pairs.length; i += 1) {
    const dx = xs[i] - meanX;
    const dy = ys[i] - meanY;
    numerator += dx * dy;
    denomX += dx * dx;
    denomY += dy * dy;
  }
  if (denomX === 0 || denomY === 0) {
    return null;
  }
  return formatNumber(numerator / Math.sqrt(denomX * denomY), 3);
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

function formatComboWarningHistory(history) {
  if (!Array.isArray(history) || history.length === 0) {
    return "";
  }
  return history
    .map((entry) => {
      if (!entry || typeof entry !== "object") {
        return "";
      }
      const wave =
        typeof entry.waveIndex === "number" && Number.isFinite(entry.waveIndex)
          ? `W${entry.waveIndex}`
          : "W?";
      const before =
        typeof entry.comboBefore === "number" && Number.isFinite(entry.comboBefore)
          ? `x${entry.comboBefore}`
          : "x?";
      const after =
        typeof entry.comboAfter === "number" && Number.isFinite(entry.comboAfter)
          ? `x${entry.comboAfter}`
          : "x?";
      const delta =
        typeof entry.deltaPercent === "number" && Number.isFinite(entry.deltaPercent)
          ? `${formatNumber(entry.deltaPercent, 2)}%`
          : "";
      return delta ? `${wave}:${delta} (${before}->${after})` : `${wave} (${before}->${after})`;
    })
    .filter((entry) => entry.length > 0)
    .join(" | ");
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
  const assetIntegrity = snapshot?.assetIntegrity ?? null;
  metadata.assetIntegrityStatus = assetIntegrity?.status ?? "";
  metadata.assetIntegrityStrict =
    typeof assetIntegrity?.strictMode === "boolean" ? String(assetIntegrity.strictMode) : "";
  metadata.assetIntegrityScenario = assetIntegrity?.scenario ?? "";
  metadata.assetIntegrityManifest =
    assetIntegrity?.manifest ?? assetIntegrity?.manifestUrl ?? "";
  metadata.assetIntegrityChecked =
    typeof assetIntegrity?.checked === "number" ? assetIntegrity.checked : "";
  metadata.assetIntegrityMissing =
    typeof assetIntegrity?.missingHash === "number" ? assetIntegrity.missingHash : "";
  metadata.assetIntegrityFailed =
    typeof assetIntegrity?.failed === "number" ? assetIntegrity.failed : "";
  metadata.assetIntegrityTotal =
    typeof assetIntegrity?.totalImages === "number" ? assetIntegrity.totalImages : "";
  metadata.assetIntegrityFirstFailure = formatAssetIntegrityFailure(
    assetIntegrity?.firstFailure
  );
  const defeatBurst = snapshot?.analytics?.defeatBurst ?? null;
  metadata.defeatBurstCount =
    typeof defeatBurst?.total === "number" ? defeatBurst.total : "";
  metadata.defeatBurstSpriteCount =
    typeof defeatBurst?.sprite === "number" ? defeatBurst.sprite : "";
  metadata.defeatBurstProceduralCount =
    typeof defeatBurst?.procedural === "number" ? defeatBurst.procedural : "";
  metadata.defeatBurstLastEnemyType = defeatBurst?.lastEnemyType ?? "";
  metadata.defeatBurstLastLane =
    typeof defeatBurst?.lastLane === "number" ? defeatBurst.lastLane : "";
  metadata.defeatBurstLastMode = defeatBurst?.lastMode ?? "";
  metadata.defeatBurstLastTimestamp =
    typeof defeatBurst?.lastTimestamp === "number" ? formatNumber(defeatBurst.lastTimestamp, 2) : "";
  const defeatBurstHistory =
    Array.isArray(defeatBurst?.history) && defeatBurst.history.length > 0
      ? defeatBurst.history
          .map((entry) => {
            const laneLabel =
              typeof entry.lane === "number" && Number.isFinite(entry.lane)
                ? `L${entry.lane}`
                : "L?";
            const modeLabel = entry.mode ?? "";
            return `${entry.enemyType ?? "enemy"}@${laneLabel}:${modeLabel}`;
          })
          .join(" | ")
      : "";
  metadata.defeatBurstHistory = defeatBurstHistory;
  const defeatElapsedMinutes = typeof snapshot?.time === "number" && snapshot.time > 0 ? snapshot.time / 60 : null;
  const defeatPerMinute =
    defeatElapsedMinutes && typeof defeatBurst?.total === "number" && defeatElapsedMinutes > 0
      ? defeatBurst.total / defeatElapsedMinutes
      : null;
  metadata.defeatBurstPerMinute =
    defeatPerMinute !== null && Number.isFinite(defeatPerMinute)
      ? formatNumber(defeatPerMinute, 2)
      : "";
  const spritePct =
    typeof defeatBurst?.total === "number" &&
    defeatBurst.total > 0 &&
    typeof defeatBurst?.sprite === "number"
      ? formatNumber((defeatBurst.sprite / defeatBurst.total) * 100, 1)
      : "";
  metadata.defeatBurstSpritePct = spritePct;
  const starfieldState = snapshot?.analytics?.starfield ?? null;
  metadata.starfieldDepth =
    typeof starfieldState?.depth === "number" ? formatNumber(starfieldState.depth, 3) : "";
  metadata.starfieldDrift =
    typeof starfieldState?.driftMultiplier === "number"
      ? formatNumber(starfieldState.driftMultiplier, 3)
      : "";
  metadata.starfieldTint = starfieldState?.tint ?? "";
  metadata.starfieldWaveProgress =
    typeof starfieldState?.waveProgress === "number"
      ? formatNumber(starfieldState.waveProgress * 100, 1)
      : "";
  metadata.starfieldCastleRatio =
    typeof starfieldState?.castleHealthRatio === "number"
      ? formatNumber(starfieldState.castleHealthRatio * 100, 1)
      : "";
  metadata.starfieldSeverity =
    typeof starfieldState?.severity === "number"
      ? formatNumber(starfieldState.severity * 100, 1)
      : "";
  metadata.starfieldReducedMotionApplied = starfieldState?.reducedMotionApplied ? "true" : "false";
  const starfieldLayers =
    Array.isArray(starfieldState?.layers) && starfieldState.layers.length > 0
      ? starfieldState.layers
          .map((layer) => {
            const id = layer.id ?? "layer";
            const velocity =
              typeof layer.velocity === "number" && Number.isFinite(layer.velocity)
                ? formatNumber(layer.velocity, 4)
                : "?";
            const arrow = layer.direction === -1 ? "←" : "→";
            const depth =
              typeof layer.depth === "number" && Number.isFinite(layer.depth)
                ? formatNumber(layer.depth, 2)
                : "?";
            return `${id}:${velocity}${arrow}${depth ? ` (z ${depth})` : ""}`;
          })
          .join(" | ")
      : "";
  metadata.starfieldLayers = starfieldLayers;
  const comboWarning = snapshot?.analytics?.comboWarning ?? snapshot?.comboWarning ?? null;
  const comboWarningCount =
    typeof comboWarning?.count === "number" && comboWarning.count > 0
      ? comboWarning.count
      : Array.isArray(comboWarning?.history)
        ? comboWarning.history.length
        : "";
  metadata.comboWarningCount = comboWarningCount === "" ? "" : comboWarningCount;
  metadata.comboWarningDeltaLast =
    comboWarning?.lastDelta !== null && comboWarning?.lastDelta !== undefined
      ? formatNumber(comboWarning.lastDelta, 2)
      : "";
  const comboWarningAverage =
    comboWarning &&
    typeof comboWarning.count === "number" &&
    comboWarning.count > 0 &&
    typeof comboWarning.deltaSum === "number"
      ? comboWarning.deltaSum / comboWarning.count
      : null;
  metadata.comboWarningDeltaAvg =
    comboWarningAverage !== null ? formatNumber(comboWarningAverage, 2) : "";
  metadata.comboWarningDeltaMin =
    comboWarning?.deltaMin !== null && comboWarning?.deltaMin !== undefined
      ? formatNumber(comboWarning.deltaMin, 2)
      : "";
  metadata.comboWarningDeltaMax =
    comboWarning?.deltaMax !== null && comboWarning?.deltaMax !== undefined
      ? formatNumber(comboWarning.deltaMax, 2)
      : "";
  metadata.comboWarningHistory = formatComboWarningHistory(comboWarning?.history);
  const audioHistory = normalizeAudioIntensityHistory(
    snapshot?.analytics?.audioIntensityHistory ?? snapshot?.audioIntensityHistory
  );
  const audioValues = audioHistory
    .map((entry) => (entry.to !== null ? entry.to : null))
    .filter((value) => value !== null);
  const audioAvg =
    audioValues.length > 0
      ? formatNumber(
          audioValues.reduce((sum, value) => sum + value, 0) / audioValues.length,
          3
        )
      : null;
  const audioDelta =
    audioValues.length >= 2
      ? formatNumber(audioValues[audioValues.length - 1] - audioValues[0], 3)
      : null;
  const comboPairs = audioHistory
    .map((entry) =>
      entry.to !== null && entry.combo !== null ? { x: entry.to, y: entry.combo } : null
    )
    .filter((entry) => entry);
  const accuracyPairs = audioHistory
    .map((entry) =>
      entry.to !== null && entry.accuracy !== null ? { x: entry.to, y: entry.accuracy } : null
    )
    .filter((entry) => entry);
  metadata.audioIntensitySamples = audioHistory.length || "";
  metadata.audioIntensityAvg =
    audioAvg ?? (soundIntensityValue !== "" ? soundIntensityValue : "");
  metadata.audioIntensityDelta = audioDelta ?? "";
  metadata.audioIntensityComboCorrelation = computeCorrelation(comboPairs) ?? "";
  metadata.audioIntensityAccuracyCorrelation = computeCorrelation(accuracyPairs) ?? "";
  const uiSnapshot = snapshot?.ui ?? null;
  const tutorialBannerUi = uiSnapshot?.tutorialBanner ?? {};
  const hudUi = uiSnapshot?.hud ?? {};
  const optionsUi = uiSnapshot?.options ?? {};
  const diagnosticsUi = uiSnapshot?.diagnostics ?? {};
  const preferencesUi = uiSnapshot?.preferences ?? {};
  const resolutionUi = uiSnapshot?.resolution ?? null;
  const resolutionChangesUi = Array.isArray(uiSnapshot?.resolutionChanges)
    ? uiSnapshot.resolutionChanges
    : [];
  metadata.uiCompactHeight = boolOrEmpty(uiSnapshot?.compactHeight);
  metadata.uiTutorialCondensed = boolOrEmpty(tutorialBannerUi?.condensed);
  metadata.uiTutorialExpanded = boolOrEmpty(tutorialBannerUi?.expanded);
  metadata.uiHudPassivesCollapsed = boolOrEmpty(hudUi?.passivesCollapsed);
  metadata.uiHudGoldEventsCollapsed = boolOrEmpty(hudUi?.goldEventsCollapsed);
  metadata.uiHudPrefersCondensed = boolOrEmpty(hudUi?.prefersCondensedLists);
  metadata.uiHudLayout = typeof hudUi?.layout === "string" ? hudUi.layout : "";
  metadata.uiOptionsPassivesCollapsed = boolOrEmpty(optionsUi?.passivesCollapsed);
  metadata.uiResolutionCssWidth =
    Number.isFinite(resolutionUi?.cssWidth) && resolutionUi?.cssWidth !== null
      ? Math.round(resolutionUi.cssWidth)
      : "";
  metadata.uiResolutionCssHeight =
    Number.isFinite(resolutionUi?.cssHeight) && resolutionUi?.cssHeight !== null
      ? Math.round(resolutionUi.cssHeight)
      : "";
  metadata.uiResolutionRenderWidth =
    Number.isFinite(resolutionUi?.renderWidth) && resolutionUi?.renderWidth !== null
      ? Math.round(resolutionUi.renderWidth)
      : "";
  metadata.uiResolutionRenderHeight =
    Number.isFinite(resolutionUi?.renderHeight) && resolutionUi?.renderHeight !== null
      ? Math.round(resolutionUi.renderHeight)
      : "";
  metadata.uiResolutionDevicePixelRatio =
    typeof resolutionUi?.devicePixelRatio === "number"
      ? formatNumber(resolutionUi.devicePixelRatio, 2)
      : "";
  metadata.uiResolutionLastCause =
    typeof resolutionUi?.lastResizeCause === "string" && resolutionUi.lastResizeCause.length > 0
      ? resolutionUi.lastResizeCause
      : "";
  metadata.uiResolutionHudLayout =
    typeof resolutionUi?.hudLayout === "string" ? resolutionUi.hudLayout : "";
  metadata.uiResolutionChangeCount = resolutionChangesUi.length || "";
  metadata.uiResolutionChanges = formatResolutionChanges(resolutionChangesUi);
  metadata.uiDiagnosticsCondensed = boolOrEmpty(diagnosticsUi?.condensed);
  metadata.uiDiagnosticsSectionsCollapsed = boolOrEmpty(diagnosticsUi?.sectionsCollapsed);
  metadata.uiDiagnosticsCollapsedSections = formatDiagnosticsSections(
    diagnosticsUi?.collapsedSections
  );
  metadata.uiDiagnosticsLastUpdatedAt = diagnosticsUi?.lastUpdatedAt ?? "";
  metadata.uiPrefHudPassivesCollapsed = boolOrEmpty(preferencesUi?.hudPassivesCollapsed);
  metadata.uiPrefHudGoldEventsCollapsed = boolOrEmpty(preferencesUi?.hudGoldEventsCollapsed);
  metadata.uiPrefOptionsPassivesCollapsed = boolOrEmpty(preferencesUi?.optionsPassivesCollapsed);
  metadata.uiPrefDiagnosticsSections = formatDiagnosticsSections(preferencesUi?.diagnosticsSections);
  metadata.uiPrefDiagnosticsSectionsUpdatedAt =
    preferencesUi?.diagnosticsSectionsUpdatedAt ?? "";
  metadata.uiPrefDevicePixelRatio =
    typeof preferencesUi?.devicePixelRatio === "number"
      ? formatNumber(preferencesUi.devicePixelRatio, 2)
      : "";
  metadata.uiPrefHudLayout =
    typeof preferencesUi?.hudLayout === "string" ? preferencesUi.hudLayout : "";

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
    "assetIntegrityStatus",
    "assetIntegrityStrict",
    "assetIntegrityScenario",
    "assetIntegrityManifest",
    "assetIntegrityChecked",
    "assetIntegrityMissing",
    "assetIntegrityFailed",
    "assetIntegrityTotal",
    "assetIntegrityFirstFailure",
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
    "uiHudLayout",
    "uiOptionsPassivesCollapsed",
    "uiResolutionCssWidth",
    "uiResolutionCssHeight",
    "uiResolutionRenderWidth",
    "uiResolutionRenderHeight",
    "uiResolutionDevicePixelRatio",
    "uiResolutionLastCause",
    "uiResolutionHudLayout",
    "uiResolutionChangeCount",
    "uiResolutionChanges",
    "uiDiagnosticsCondensed",
    "uiDiagnosticsSectionsCollapsed",
    "uiDiagnosticsCollapsedSections",
    "uiDiagnosticsLastUpdatedAt",
    "uiPrefHudPassivesCollapsed",
    "uiPrefHudGoldEventsCollapsed",
    "uiPrefOptionsPassivesCollapsed",
    "uiPrefDiagnosticsSections",
    "uiPrefDiagnosticsSectionsUpdatedAt",
    "uiPrefDevicePixelRatio",
    "uiPrefHudLayout",
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
    "defeatBurstCount",
    "defeatBurstSpriteCount",
    "defeatBurstProceduralCount",
    "defeatBurstPerMinute",
    "defeatBurstSpritePct",
    "defeatBurstLastEnemyType",
    "defeatBurstLastLane",
    "defeatBurstLastMode",
    "defeatBurstLastTimestamp",
    "defeatBurstHistory",
    "starfieldDepth",
    "starfieldDrift",
    "starfieldTint",
    "starfieldWaveProgress",
    "starfieldCastleRatio",
    "starfieldSeverity",
    "starfieldReducedMotionApplied",
    "starfieldLayers",
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
    "tutorialSkips",
    "comboWarningCount",
    "comboWarningDeltaLast",
    "comboWarningDeltaAvg",
    "comboWarningDeltaMin",
    "comboWarningDeltaMax",
    "comboWarningHistory",
    "audioIntensitySamples",
    "audioIntensityAvg",
    "audioIntensityDelta",
    "audioIntensityComboCorrelation",
    "audioIntensityAccuracyCorrelation"
  ];
  console.log(headers.join(","));
  for (const row of rows) {
    const line = headers.map((header) => escapeCsv(row[header] ?? "")).join(",");
    console.log(line);
  }
}

function printUsage() {
  console.error("Usage: node scripts/analyticsAggregate.mjs [options] <file-or-directory> [...]");
  console.error("Scans analytics JSON exports and prints a CSV summary to stdout.");
  console.error("");
  console.error("Options:");
  console.error("  --passive-summary <file>      Write passive unlock JSON summary");
  console.error("  --passive-summary-csv <file>  Write passive unlock CSV");
  console.error("  --passive-summary-md <file>   Write passive unlock Markdown summary");
  console.error("  --help                        Show this message");
}

function parseAggregateArgs(argv = []) {
  const options = {
    help: false,
    targets: [],
    passiveSummaryJson: null,
    passiveSummaryCsv: null,
    passiveSummaryMarkdown: null
  };

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    switch (token) {
      case "--help":
      case "-h":
        options.help = true;
        break;
      case "--passive-summary": {
        const value = argv[++i];
        if (!value) throw new Error("Expected path after --passive-summary");
        options.passiveSummaryJson = path.resolve(value);
        break;
      }
      case "--passive-summary-csv": {
        const value = argv[++i];
        if (!value) throw new Error("Expected path after --passive-summary-csv");
        options.passiveSummaryCsv = path.resolve(value);
        break;
      }
      case "--passive-summary-md": {
        const value = argv[++i];
        if (!value) throw new Error("Expected path after --passive-summary-md");
        options.passiveSummaryMarkdown = path.resolve(value);
        break;
      }
      default:
        if (token.startsWith("-")) {
          throw new Error(`Unknown argument "${token}". Use --help for usage.`);
        }
        options.targets.push(token);
    }
  }

  return options;
}

function buildPassiveEntries(snapshot, sourcePath) {
  const unlocks = snapshot?.analytics?.castlePassiveUnlocks;
  if (!Array.isArray(unlocks) || unlocks.length === 0) {
    return [];
  }
  const relativeFile = path.relative(process.cwd(), sourcePath) || sourcePath;
  const capturedAt = snapshot?.capturedAt ?? "";
  const status = snapshot?.status ?? "";
  const mode = snapshot?.mode ?? snapshot?.analytics?.mode ?? "";
  const waveIndex = snapshot?.wave?.index ?? "";

  return unlocks.map((unlock, index) => ({
    file: relativeFile,
    capturedAt,
    status,
    mode,
    waveIndex,
    unlockIndex: index,
    passiveId: unlock?.id ?? "",
    level: unlock?.level ?? "",
    time: Number.isFinite(unlock?.time) ? Number(unlock.time) : "",
    total: typeof unlock?.total === "number" ? unlock.total : "",
    delta: typeof unlock?.delta === "number" ? unlock.delta : ""
  }));
}

function sortPassiveEntries(entries) {
  return [...entries].sort((a, b) => {
    if (a.capturedAt && b.capturedAt && a.capturedAt !== b.capturedAt) {
      return a.capturedAt.localeCompare(b.capturedAt);
    }
    if (a.file !== b.file) {
      return a.file.localeCompare(b.file);
    }
    const timeA = Number.isFinite(a.time) ? a.time : Number.POSITIVE_INFINITY;
    const timeB = Number.isFinite(b.time) ? b.time : Number.POSITIVE_INFINITY;
    if (timeA !== timeB) {
      return timeA - timeB;
    }
    return a.unlockIndex - b.unlockIndex;
  });
}

function summarizePassiveEntries(entries) {
  const sorted = sortPassiveEntries(entries);
  const fileSet = new Set(sorted.map((entry) => entry.file));
  const breakdown = new Map();

  for (const entry of sorted) {
    const id = entry.passiveId || "unknown";
    const bucket = breakdown.get(id) ?? { count: 0, last: null };
    bucket.count += 1;
    bucket.last = entry;
    breakdown.set(id, bucket);
  }

  const passiveBreakdown = {};
  for (const [id, bucket] of breakdown.entries()) {
    passiveBreakdown[id] = {
      count: bucket.count,
      lastLevel: bucket.last?.level ?? "",
      lastTotal: bucket.last?.total ?? "",
      lastFile: bucket.last?.file ?? "",
      lastTime: bucket.last?.time ?? ""
    };
  }

  return {
    stats: {
      unlockCount: sorted.length,
      fileCount: fileSet.size,
      passiveBreakdown
    },
    entries: sorted
  };
}

function formatPassiveEntriesCsv(entries) {
  const headers = [
    "file",
    "capturedAt",
    "status",
    "mode",
    "waveIndex",
    "unlockIndex",
    "passiveId",
    "level",
    "time",
    "total",
    "delta"
  ];
  const lines = [headers.join(",")];
  for (const entry of entries) {
    lines.push(headers.map((key) => escapeCsv(entry[key] ?? "")).join(","));
  }
  return lines.join("\n");
}

function formatPassiveMarkdown(summary) {
  const lines = [];
  lines.push("# Passive Unlock Summary");
  lines.push("");
  if (summary.stats.unlockCount === 0) {
    lines.push("No castle passive unlocks were detected in the processed snapshots.");
    return lines.join("\n");
  }
  lines.push(
    `Total unlocks: **${summary.stats.unlockCount}** across **${summary.stats.fileCount}** snapshot${
      summary.stats.fileCount === 1 ? "" : "s"
    }.`
  );
  const breakdown = summary.stats.passiveBreakdown;
  if (Object.keys(breakdown).length > 0) {
    lines.push("");
    lines.push("| Passive | Unlocks | Last Level | Last Total | Last Source |");
    lines.push("| --- | --- | --- | --- | --- |");
    for (const [id, info] of Object.entries(breakdown)) {
      lines.push(
        `| ${id || "-"} | ${info.count} | ${info.lastLevel ?? ""} | ${info.lastTotal ?? ""} | ${
          info.lastFile ?? ""
        } |`
      );
    }
  }
  return lines.join("\n");
}

async function writePassiveSummaryFiles(entries, options) {
  const needsOutput =
    options.passiveSummaryJson || options.passiveSummaryCsv || options.passiveSummaryMarkdown;
  if (!needsOutput) return;

  const summary = summarizePassiveEntries(entries);

  if (options.passiveSummaryJson) {
    await fs.mkdir(path.dirname(options.passiveSummaryJson), { recursive: true });
    await fs.writeFile(
      options.passiveSummaryJson,
      JSON.stringify(summary, null, 2),
      "utf8"
    );
    console.error(
      `analyticsAggregate: passive summary JSON written to ${options.passiveSummaryJson}`
    );
  }
  if (options.passiveSummaryCsv) {
    await fs.mkdir(path.dirname(options.passiveSummaryCsv), { recursive: true });
    const csv = formatPassiveEntriesCsv(summary.entries);
    await fs.writeFile(options.passiveSummaryCsv, `${csv}\n`, "utf8");
    console.error(
      `analyticsAggregate: passive summary CSV written to ${options.passiveSummaryCsv}`
    );
  }
  if (options.passiveSummaryMarkdown) {
    await fs.mkdir(path.dirname(options.passiveSummaryMarkdown), { recursive: true });
    const markdown = formatPassiveMarkdown(summary);
    await fs.writeFile(options.passiveSummaryMarkdown, `${markdown}\n`, "utf8");
    console.error(
      `analyticsAggregate: passive summary Markdown written to ${options.passiveSummaryMarkdown}`
    );
  }
}

async function main(argv) {
  let options;
  try {
    options = parseAggregateArgs(argv);
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    printUsage();
    return 1;
  }

  if (options.help) {
    printUsage();
    return 0;
  }

  if (options.targets.length === 0) {
    printUsage();
    return 1;
  }

  const files = await collectTargets(options.targets);
  if (files.length === 0) {
    console.error("analyticsAggregate: no JSON snapshots found for provided arguments.");
    return 1;
  }

  const rows = [];
  const passiveEntries = [];
  for (const file of files) {
    const snapshot = await loadSnapshot(file);
    if (!snapshot) continue;
    for (const row of summarizeSnapshot(snapshot, file)) {
      rows.push(row);
    }
    passiveEntries.push(...buildPassiveEntries(snapshot, file));
  }

  if (rows.length === 0) {
    console.error("analyticsAggregate: no analytics data could be derived.");
    return 1;
  }

  await writePassiveSummaryFiles(passiveEntries, options);
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
