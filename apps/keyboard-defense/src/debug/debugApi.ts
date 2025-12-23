import type { AnalyticsUiSnapshot, TurretTypeId } from "../core/types.js";
import type { SpawnEnemyInput } from "../systems/enemySystem.js";
import type { TutorialState, TutorialStepId } from "../tutorial/tutorialTypes.js";
import type { AssetIntegritySummary } from "../types/assetIntegrity.js";

export interface Debuggable {
  pause(): void;
  resume(): void;
  step(frames?: number): void;
  setSpeed(multiplier: number): void;
  getStateSnapshot(): object;
  spawnEnemy(payload: SpawnEnemyInput): void;
  grantGold(amount: number): void;
  simulateTyping(text: string): void;
  damageCastle(amount: number): void;
  upgradeCastle(): void;
  placeTurret(slotId: string, type: TurretTypeId): void;
  upgradeTurret(slotId: string): void;
  downgradeTurret(slotId: string): void;
  breakEnemyShield(enemyId: string): boolean;
  getTutorialState(): TutorialState | null;
  completeTutorialStep(stepId?: TutorialStepId): boolean;
  setDiagnosticsVisible(visible: boolean): void;
  toggleDiagnostics(): void;
  setSoundEnabled(enabled: boolean): void;
  toggleSound(): void;
  setAudioIntensity(
    intensity: number,
    options?: { silent?: boolean; persist?: boolean; source?: string }
  ): void;
  resetAnalytics(): void;
  exportAnalytics(): void;
  collectUiCondensedSnapshot(): AnalyticsUiSnapshot | null;
  debugShowTutorialSummary(summary?: {
    accuracy?: number;
    bestCombo?: number;
    breaches?: number;
    gold?: number;
  }): void;
  debugHideTutorialSummary(): void;
  debugShowWaveScorecard(summary?: Record<string, unknown>): void;
  debugHideWaveScorecard(): void;
  replayTutorial(): void;
  skipTutorial(): void;
  getTutorialAnalyticsSummary(): object;
  getAssetIntegritySummary(): AssetIntegritySummary | null;
  setTelemetryEnabled(enabled: boolean): boolean;
  toggleTelemetry(): boolean;
  setTurretDowngradeEnabled(enabled: boolean): boolean;
  toggleTurretDowngrade(): boolean;
  flushTelemetry(): unknown[];
  setTelemetryEndpoint(endpoint: string | null): void;
  getTelemetryQueueSnapshot(): unknown[];
  getTelemetryEndpoint(): string | null;
  exportTelemetryQueue(options?: { silent?: boolean }): void;
  setStarfieldScene(
    scene?: Record<string, unknown> | string | null
  ): Record<string, unknown> | null;
  spawnPracticeDummy(lane: number): void;
  clearPracticeDummies(): void;
}

export class DebugApi {
  constructor(private readonly controller: Debuggable) {}

  expose(): void {
    const api = {
      pause: () => this.controller.pause(),
      resume: () => this.controller.resume(),
      step: (frames?: number) => this.controller.step(frames),
      setSpeed: (multiplier: number) => this.controller.setSpeed(multiplier),
      getState: () => this.controller.getStateSnapshot(),
      spawnEnemy: (payload: SpawnEnemyInput) => this.controller.spawnEnemy(payload),
      grantGold: (amount: number) => this.controller.grantGold(amount),
      simulateTyping: (text: string) => this.controller.simulateTyping(text),
      damageCastle: (amount: number) => this.controller.damageCastle(amount),
      upgradeCastle: () => this.controller.upgradeCastle(),
      placeTurret: (slotId: string, type: TurretTypeId) =>
        this.controller.placeTurret(slotId, type),
      upgradeTurret: (slotId: string) => this.controller.upgradeTurret(slotId),
      downgradeTurret: (slotId: string) =>
        this.controller.downgradeTurret(slotId),
      breakShield: (enemyId: string) => this.controller.breakEnemyShield(enemyId),
      getTutorialState: () => this.controller.getTutorialState(),
      completeTutorialStep: (stepId?: TutorialStepId) =>
        this.controller.completeTutorialStep(stepId),
      showDiagnostics: () => this.controller.setDiagnosticsVisible(true),
      hideDiagnostics: () => this.controller.setDiagnosticsVisible(false),
      toggleDiagnostics: () => this.controller.toggleDiagnostics(),
      enableSound: () => this.controller.setSoundEnabled(true),
      disableSound: () => this.controller.setSoundEnabled(false),
      toggleSound: () => this.controller.toggleSound(),
      setAudioIntensity: (
        intensity: number,
        options?: { silent?: boolean; persist?: boolean; source?: string }
      ) => this.controller.setAudioIntensity(intensity, options),
      resetAnalytics: () => this.controller.resetAnalytics(),
      exportAnalytics: () => this.controller.exportAnalytics(),
      getUiSnapshot: () => this.controller.collectUiCondensedSnapshot(),
      showTutorialSummary: (data?: {
        accuracy?: number;
        bestCombo?: number;
        breaches?: number;
        gold?: number;
      }) => this.controller.debugShowTutorialSummary(data ?? {}),
      hideTutorialSummary: () => this.controller.debugHideTutorialSummary(),
      showWaveScorecard: (data?: Record<string, unknown>) =>
        this.controller.debugShowWaveScorecard(data ?? {}),
      hideWaveScorecard: () => this.controller.debugHideWaveScorecard(),
      replayTutorial: () => this.controller.replayTutorial(),
      skipTutorial: () => this.controller.skipTutorial(),
      getTutorialAnalytics: () => this.controller.getTutorialAnalyticsSummary(),
      enableTelemetry: () => this.controller.setTelemetryEnabled(true),
      disableTelemetry: () => this.controller.setTelemetryEnabled(false),
      toggleTelemetry: () => this.controller.toggleTelemetry(),
      enableTurretDowngrade: () =>
        this.controller.setTurretDowngradeEnabled(true),
      disableTurretDowngrade: () =>
        this.controller.setTurretDowngradeEnabled(false),
      toggleTurretDowngrade: () => this.controller.toggleTurretDowngrade(),
      flushTelemetry: () => this.controller.flushTelemetry(),
      setTelemetryEndpoint: (endpoint?: string | null) =>
        this.controller.setTelemetryEndpoint(endpoint ?? null),
      getTelemetryQueue: () => this.controller.getTelemetryQueueSnapshot(),
      getTelemetryEndpoint: () => this.controller.getTelemetryEndpoint(),
      exportTelemetryQueue: () => this.controller.exportTelemetryQueue(),
      getAssetIntegritySummary: () =>
        this.controller.getAssetIntegritySummary?.(),
      setStarfieldScene: (options?: Record<string, unknown> | string | null) =>
        this.controller.setStarfieldScene(options ?? null),
      spawnPracticeDummy: (lane: number) =>
        this.controller.spawnPracticeDummy(lane),
      clearPracticeDummies: () => this.controller.clearPracticeDummies()
    };

    Object.defineProperty(window, "keyboardDefense", {
      value: api,
      writable: false,
      configurable: true
    });
  }
}

declare global {
  interface Window {
    keyboardDefense?: {
      pause(): void;
      resume(): void;
      step(frames?: number): void;
      setSpeed(multiplier: number): void;
      getState(): object;
      spawnEnemy(payload: SpawnEnemyInput): void;
      grantGold(amount: number): void;
      simulateTyping(text: string): void;
      damageCastle(amount: number): void;
      upgradeCastle(): void;
      placeTurret(slotId: string, type: TurretTypeId): void;
      upgradeTurret(slotId: string): void;
      downgradeTurret(slotId: string): void;
      breakShield(enemyId: string): boolean;
      getTutorialState(): TutorialState | null;
      completeTutorialStep(stepId?: TutorialStepId): boolean;
      showDiagnostics(): void;
      hideDiagnostics(): void;
      toggleDiagnostics(): void;
      enableSound(): void;
      disableSound(): void;
      toggleSound(): void;
      setAudioIntensity(
        intensity: number,
        options?: { silent?: boolean; persist?: boolean; source?: string }
      ): void;
      resetAnalytics(): void;
      exportAnalytics(): void;
      showTutorialSummary(data?: {
        accuracy?: number;
        bestCombo?: number;
        breaches?: number;
        gold?: number;
      }): void;
      hideTutorialSummary(): void;
      showWaveScorecard(data?: Record<string, unknown>): void;
      hideWaveScorecard(): void;
      getUiSnapshot(): AnalyticsUiSnapshot | null;
      replayTutorial(): void;
      skipTutorial(): void;
      getTutorialAnalytics(): object;
      getAssetIntegritySummary(): AssetIntegritySummary | null;
      enableTelemetry(): boolean;
      disableTelemetry(): boolean;
      toggleTelemetry(): boolean;
      enableTurretDowngrade(): boolean;
      disableTurretDowngrade(): boolean;
      toggleTurretDowngrade(): boolean;
      flushTelemetry(): unknown[];
      setTelemetryEndpoint(endpoint?: string | null): void;
      getTelemetryQueue(): unknown[];
      getTelemetryEndpoint(): string | null;
      exportTelemetryQueue(): void;
      setStarfieldScene(
        scene?: Record<string, unknown> | string | null
      ): Record<string, unknown> | null;
      spawnPracticeDummy(lane: number): void;
      clearPracticeDummies(): void;
    };
  }
}
