import { defaultWordBank, type WordBank, type WordDifficulty } from "../core/wordBank.js";
import { type TypingDrillMode, type TypingDrillSummary } from "../core/types.js";

type DrillConfig = {
  label: string;
  description: string;
  wordCount?: number;
  timerMs?: number;
  difficulties: WordDifficulty[];
  penalizeErrors?: boolean;
};

type DrillSummary = TypingDrillSummary & { tip: string };

const DRILL_CONFIGS: Record<TypingDrillMode, DrillConfig> = {
  burst: {
    label: "Burst Warmup",
    description: "Clear five snappy words to warm up before battle.",
    wordCount: 5,
    difficulties: ["easy", "easy", "medium", "medium", "hard"]
  },
  endurance: {
    label: "Endurance",
    description: "Stay consistent for thirty seconds; cadence matters more than speed.",
    timerMs: 30000,
    difficulties: ["easy", "medium", "medium", "hard"]
  },
  precision: {
    label: "Shield Breaker",
    description: "Eight tougher strings. Errors reset the current word to mimic shield pressure.",
    wordCount: 8,
    difficulties: ["medium", "medium", "hard", "hard"],
    penalizeErrors: true
  }
};

type TypingDrillCallbacks = {
  onClose?: () => void;
  onStart?: (mode: TypingDrillMode, source: string) => void;
  onSummary?: (summary: TypingDrillSummary) => void;
};

type TypingDrillState = {
  mode: TypingDrillMode;
  active: boolean;
  startSource: string;
  buffer: string;
  target: string;
  correctInputs: number;
  totalInputs: number;
  errors: number;
  wordsCompleted: number;
  combo: number;
  bestCombo: number;
  wordErrors: number;
  startTime: number;
  elapsedMs: number;
  timerEndsAt: number | null;
};

export class TypingDrillsOverlay {
  private readonly root: HTMLElement;
  private readonly wordBank: WordBank;
  private readonly callbacks: TypingDrillCallbacks;
  private readonly modeButtons: HTMLButtonElement[] = [];
  private readonly body?: HTMLElement | null;
  private readonly statusLabel?: HTMLElement | null;
  private readonly progressLabel?: HTMLElement | null;
  private readonly timerLabel?: HTMLElement | null;
  private readonly targetEl?: HTMLElement | null;
  private readonly input?: HTMLInputElement | null;
  private readonly startBtn?: HTMLButtonElement | null;
  private readonly resetBtn?: HTMLButtonElement | null;
  private readonly accuracyEl?: HTMLElement | null;
  private readonly comboEl?: HTMLElement | null;
  private readonly wpmEl?: HTMLElement | null;
  private readonly wordsEl?: HTMLElement | null;
  private readonly summaryEl?: HTMLElement | null;
  private readonly summaryTime?: HTMLElement | null;
  private readonly summaryAccuracy?: HTMLElement | null;
  private readonly summaryCombo?: HTMLElement | null;
  private readonly summaryWords?: HTMLElement | null;
  private readonly summaryErrors?: HTMLElement | null;
  private readonly summaryTip?: HTMLElement | null;
  private readonly fallbackEl?: HTMLElement | null;
  private readonly toastEl?: HTMLElement | null;
  private readonly recommendationEl?: HTMLElement | null;
  private readonly recommendationBadge?: HTMLElement | null;
  private readonly recommendationReason?: HTMLElement | null;
  private readonly recommendationRun?: HTMLButtonElement | null;
  private resizeHandler?: () => void;
  private layoutPulseTimeout?: number | null;
  private isCondensedLayout: boolean = false;
  private cleanupTimer?: () => void;
  private recommendationMode: TypingDrillMode | null = null;
  private toastTimeout?: number | null;
  private state: TypingDrillState = {
    mode: "burst",
    active: false,
    startSource: "cta",
    buffer: "",
    target: "",
    correctInputs: 0,
    totalInputs: 0,
    errors: 0,
    wordsCompleted: 0,
    combo: 0,
    bestCombo: 0,
    wordErrors: 0,
    startTime: 0,
    elapsedMs: 0,
    timerEndsAt: null
  };

  constructor(options: { root: HTMLElement; wordBank?: WordBank; callbacks?: TypingDrillCallbacks }) {
    this.root = options.root;
    this.wordBank = options.wordBank ?? defaultWordBank;
    this.callbacks = options.callbacks ?? {};

    this.body = this.root.querySelector(".typing-drills-body");
    this.statusLabel = document.getElementById("typing-drill-status-label");
    this.progressLabel = document.getElementById("typing-drill-progress");
    this.timerLabel = document.getElementById("typing-drill-timer");
    this.targetEl = document.getElementById("typing-drill-target");
    this.input = document.getElementById("typing-drill-input") as HTMLInputElement | null;
    this.startBtn = document.getElementById("typing-drill-start") as HTMLButtonElement | null;
    this.resetBtn = document.getElementById("typing-drill-reset") as HTMLButtonElement | null;
    this.accuracyEl = document.getElementById("typing-drill-accuracy");
    this.comboEl = document.getElementById("typing-drill-combo");
    this.wpmEl = document.getElementById("typing-drill-wpm");
    this.wordsEl = document.getElementById("typing-drill-words");
    this.summaryEl = document.getElementById("typing-drill-summary");
    this.summaryTime = document.getElementById("typing-drill-summary-time");
    this.summaryAccuracy = document.getElementById("typing-drill-summary-accuracy");
    this.summaryCombo = document.getElementById("typing-drill-summary-combo");
    this.summaryWords = document.getElementById("typing-drill-summary-words");
    this.summaryErrors = document.getElementById("typing-drill-summary-errors");
    this.summaryTip = document.getElementById("typing-drill-summary-tip");
    this.fallbackEl = document.getElementById("typing-drill-fallback");
    this.toastEl = document.getElementById("typing-drill-toast");
    this.recommendationEl = document.getElementById("typing-drill-recommendation");
    this.recommendationBadge = document.getElementById("typing-drill-recommendation-badge");
    this.recommendationReason = document.getElementById("typing-drill-recommendation-reason");
    this.recommendationRun = document.getElementById(
      "typing-drill-recommendation-run"
    ) as HTMLButtonElement | null;

    const modeButtons = Array.from(
      this.root.querySelectorAll<HTMLButtonElement>(".typing-drill-mode")
    );
    this.modeButtons.push(...modeButtons);

    this.attachEvents();
    this.updateLayoutMode();
    if (typeof window !== "undefined") {
      this.resizeHandler = () => this.updateLayoutMode();
      window.addEventListener("resize", this.resizeHandler);
    }
    this.updateMode(this.state.mode, { silent: true });
    this.updateTarget();
    this.updateMetrics();
    this.updateTimer();
  }

  open(mode?: TypingDrillMode, source?: string, toastMessage?: string): void {
    this.root.dataset.visible = "true";
    this.state.startSource = source ?? this.state.startSource ?? "cta";
    this.reset(mode);
    this.input?.focus();
    if (toastMessage) {
      this.showToast(toastMessage);
    }
  }

  close(): void {
    this.cleanupTimer?.();
    this.cleanupTimer = undefined;
    if (this.toastEl) {
      this.toastEl.dataset.visible = "false";
      this.toastEl.textContent = "";
    }
    if (this.toastTimeout) {
      window.clearTimeout(this.toastTimeout);
      this.toastTimeout = null;
    }
    this.state.active = false;
    this.state.buffer = "";
    this.state.target = "";
    this.root.dataset.visible = "false";
    this.summaryEl?.setAttribute("data-visible", "false");
    this.callbacks.onClose?.();
  }

  isVisible(): boolean {
    return this.root.dataset.visible === "true";
  }

  isActive(): boolean {
    return this.state.active;
  }

  start(mode?: TypingDrillMode): void {
    const nextMode = mode ?? this.state.mode;
    this.state = {
      ...this.state,
      mode: nextMode,
      active: true,
      startSource: this.state.startSource,
      buffer: "",
      target: "",
      correctInputs: 0,
      totalInputs: 0,
      errors: 0,
      wordsCompleted: 0,
      combo: 0,
      bestCombo: 0,
      wordErrors: 0,
      startTime: performance.now(),
      elapsedMs: 0,
      timerEndsAt: null
    };
    this.summaryEl?.setAttribute("data-visible", "false");
    this.updateMode(nextMode);
    this.state.target = this.pickWord(nextMode);
    const config = DRILL_CONFIGS[nextMode];
    if (typeof config.timerMs === "number" && config.timerMs > 0) {
      const endsAt = performance.now() + config.timerMs;
      this.state.timerEndsAt = endsAt;
      this.cleanupTimer = this.startTimer(endsAt);
    }
    this.updateTarget();
    this.updateMetrics();
    this.updateTimer();
    this.callbacks.onStart?.(nextMode, this.state.startSource);
    if (this.statusLabel) {
      this.statusLabel.textContent = config.label;
    }
    if (this.startBtn) {
      this.startBtn.textContent = "Restart";
    }
  }

  reset(mode?: TypingDrillMode): void {
    const nextMode = mode ?? this.state.mode;
    this.cleanupTimer?.();
    this.cleanupTimer = undefined;
    this.state = {
      mode: nextMode,
      active: false,
      startSource: this.state.startSource,
      buffer: "",
      target: this.pickWord(nextMode),
      correctInputs: 0,
      totalInputs: 0,
      errors: 0,
      wordsCompleted: 0,
      combo: 0,
      bestCombo: 0,
      wordErrors: 0,
      startTime: 0,
      elapsedMs: 0,
      timerEndsAt: null
    };
    this.updateMode(nextMode);
    this.updateTarget();
    this.updateMetrics();
    this.updateTimer();
    this.summaryEl?.setAttribute("data-visible", "false");
    if (this.fallbackEl) {
      this.fallbackEl.dataset.visible = "false";
    }
    if (this.statusLabel) {
      this.statusLabel.textContent = "Ready";
    }
    if (this.startBtn) {
      this.startBtn.textContent = "Start Drill";
    }
  }

  private updateLayoutMode(): void {
    const body = this.body;
    if (!body) return;
    if (typeof window === "undefined") {
      body.dataset.condensed = "false";
      this.isCondensedLayout = false;
      return;
    }
    const height = window.innerHeight;
    const width = window.innerWidth;
    const condensed = height < 760 || width < 960;
    const nextCondensed = condensed ? "true" : "false";
    const changed = body.dataset.condensed !== nextCondensed;
    body.dataset.condensed = nextCondensed;
    this.isCondensedLayout = condensed;
    if (changed) {
      body.classList.remove("typing-drills-layout-pulse");
      if (this.layoutPulseTimeout) {
        window.clearTimeout(this.layoutPulseTimeout);
      }
      void body.offsetWidth;
      body.classList.add("typing-drills-layout-pulse");
      this.layoutPulseTimeout = window.setTimeout(() => {
        body.classList.remove("typing-drills-layout-pulse");
        this.layoutPulseTimeout = null;
      }, 650);
    }
  }

  private attachEvents(): void {
    if (this.input) {
      this.input.addEventListener("keydown", (event) => this.handleKey(event));
    }
    if (this.startBtn) {
      this.startBtn.addEventListener("click", () => {
        if (!this.state.active) {
          this.start();
        } else {
          this.reset();
          this.start();
        }
      });
    }
    if (this.resetBtn) {
      this.resetBtn.addEventListener("click", () => this.reset());
    }
    this.modeButtons.forEach((btn) =>
      btn.addEventListener("click", () => {
        const mode = btn.dataset.mode as TypingDrillMode | undefined;
        if (!mode) return;
        this.reset(mode);
        if (this.state.active) {
          this.start(mode);
        }
      })
    );
    const closeBtn = document.getElementById("typing-drills-close");
    closeBtn?.addEventListener("click", () => this.close());
    if (this.recommendationRun) {
      this.recommendationRun.addEventListener("click", () => {
        if (this.recommendationMode) {
          this.reset(this.recommendationMode);
          this.start(this.recommendationMode);
        }
      });
    }
  }

  private handleKey(event: KeyboardEvent): void {
    if (event.key === "Escape") {
      event.preventDefault();
      this.close();
      return;
    }
    if (!this.state.active) {
      if (event.key === "Enter") {
        event.preventDefault();
        this.start();
      }
      return;
    }

    if (event.key === "Backspace") {
      event.preventDefault();
      this.state.buffer = this.state.buffer.slice(0, -1);
      this.updateTarget();
      return;
    }

    if (event.key === "Enter") {
      event.preventDefault();
      this.commitWord(true);
      return;
    }

    if (event.key.length === 1 && /^[a-zA-Z]$/.test(event.key)) {
      event.preventDefault();
      const char = event.key.toLowerCase();
      this.state.buffer += char;
      this.state.totalInputs += 1;
      const expected = this.state.target[this.state.buffer.length - 1] ?? "";
      if (char === expected) {
        this.state.correctInputs += 1;
      } else {
        this.state.errors += 1;
        this.state.wordErrors += 1;
        if (DRILL_CONFIGS[this.state.mode].penalizeErrors) {
          this.state.combo = 0;
          this.state.buffer = "";
        }
      }
      this.updateTarget();
      this.updateMetrics();
      this.evaluateCompletion();
    }
  }

  private evaluateCompletion(): void {
    if (!this.state.target || this.state.buffer.length === 0) {
      return;
    }
    if (this.state.buffer === this.state.target) {
      this.commitWord(false);
    }
  }

  private commitWord(skipped: boolean): void {
    const config = DRILL_CONFIGS[this.state.mode];
    const flawless = this.state.wordErrors === 0 && !skipped;
    if (flawless) {
      this.state.combo += 1;
    } else if (!skipped) {
      this.state.combo = Math.max(0, Math.floor(this.state.combo * 0.5));
    } else {
      this.state.combo = Math.max(0, this.state.combo - 1);
      this.state.errors += 1;
    }
    this.state.bestCombo = Math.max(this.state.bestCombo, this.state.combo);
    this.state.wordsCompleted += skipped ? 0 : 1;
    this.state.wordErrors = 0;
    this.state.buffer = "";
    this.updateMetrics();

    const now = performance.now();
    this.state.elapsedMs = this.state.startTime > 0 ? now - this.state.startTime : 0;
    const reachedWordGoal =
      typeof config.wordCount === "number" && this.state.wordsCompleted >= config.wordCount;

    if (reachedWordGoal) {
      this.finish("complete");
      return;
    }
    this.state.target = this.pickWord(this.state.mode);
    this.updateTarget();
  }

  private finish(reason: "complete" | "timeout"): void {
    this.cleanupTimer?.();
    this.cleanupTimer = undefined;
    const now = performance.now();
    this.state.active = false;
    this.state.elapsedMs =
      this.state.startTime > 0 && now > this.state.startTime ? now - this.state.startTime : 0;
    this.state.buffer = "";
    this.updateTarget();
    this.updateMetrics();
    if (this.statusLabel) {
      this.statusLabel.textContent = reason === "timeout" ? "Time" : "Complete";
    }
    const summary = this.buildSummary();
    this.renderSummary(summary);
    const analyticsSummary = this.toAnalyticsSummary(summary);
    this.callbacks.onSummary?.(analyticsSummary);
    if (this.startBtn) {
      this.startBtn.textContent = "Run again";
    }
  }

  private buildSummary(): DrillSummary {
    const elapsedMs = this.state.elapsedMs > 0 ? this.state.elapsedMs : 1;
    const accuracy =
      this.state.totalInputs > 0 ? this.state.correctInputs / this.state.totalInputs : 1;
    const minutes = elapsedMs / 60000;
    const wpm = minutes > 0 ? (this.state.correctInputs / 5) / minutes : 0;
    return {
      mode: this.state.mode,
      source: (this.state.startSource as TypingDrillSummary["source"]) ?? "cta",
      timestamp: Date.now(),
      elapsedMs,
      accuracy,
      bestCombo: this.state.bestCombo,
      words: this.state.wordsCompleted,
      errors: this.state.errors,
      wpm,
      tip: this.buildTip(accuracy, wpm)
    };
  }

  private toAnalyticsSummary(summary: DrillSummary): TypingDrillSummary {
    return {
      mode: summary.mode,
      source: summary.source,
      elapsedMs: summary.elapsedMs,
      accuracy: summary.accuracy,
      bestCombo: summary.bestCombo,
      words: summary.words,
      errors: summary.errors,
      wpm: summary.wpm,
      timestamp: summary.timestamp
    };
  }

  private buildTip(accuracy: number, wpm: number): string {
    if (accuracy < 0.85) {
      return "Slow the first three letters and reset on mistakes to rebuild accuracy.";
    }
    if (this.state.mode === "burst" && accuracy >= 0.97) {
      return "Great start. Jump to Shield Breaker to stress accuracy under pressure.";
    }
    if (this.state.mode === "endurance" && wpm >= 55) {
      return "Solid cadence. Try holding 55+ WPM with fewer than two errors next run.";
    }
    if (this.state.mode === "precision" && this.state.bestCombo >= 4) {
      return "You are breaking shields. Add a metronome or try the Burst warmup between waves.";
    }
    return "Use drills between waves to keep combo decay comfortable before rejoining the siege.";
  }

  private renderSummary(summary: DrillSummary): void {
    if (!this.summaryEl) return;
    this.summaryEl.setAttribute("data-visible", "true");
    if (this.summaryTime) {
      this.summaryTime.textContent = `${(summary.elapsedMs / 1000).toFixed(1)}s`;
    }
    if (this.summaryAccuracy) {
      this.summaryAccuracy.textContent = `${Math.round(summary.accuracy * 100)}%`;
    }
    if (this.summaryCombo) {
      this.summaryCombo.textContent = `x${summary.bestCombo}`;
    }
    if (this.summaryWords) {
      this.summaryWords.textContent = `${summary.words}`;
    }
    if (this.summaryErrors) {
      this.summaryErrors.textContent = `${summary.errors}`;
    }
    if (this.summaryTip) {
      this.summaryTip.textContent = summary.tip;
    }
  }

  private updateMode(mode: TypingDrillMode, options: { silent?: boolean } = {}): void {
    this.state.mode = mode;
    for (const btn of this.modeButtons) {
      const selected = btn.dataset.mode === mode;
      btn.setAttribute("aria-selected", selected ? "true" : "false");
    }
    if (!options.silent) {
      this.state.target = this.pickWord(mode);
      this.updateTarget();
    }
  }

  private pickWord(mode: TypingDrillMode): string {
    const config = DRILL_CONFIGS[mode];
    const pool = [...config.difficulties];
    const difficulty =
      pool.length > 0 ? pool[Math.floor(Math.random() * pool.length)] : ("easy" as WordDifficulty);
    const source = this.wordBank[difficulty] ?? defaultWordBank[difficulty];
    if (!Array.isArray(source) || source.length === 0) {
      return "defend";
    }
    return source[Math.floor(Math.random() * source.length)] ?? "defend";
  }

  private updateTarget(): void {
    if (!this.targetEl) return;
    const typed = this.state.buffer;
    const remaining = (this.state.target ?? "").slice(typed.length);
    const typedSpan = document.createElement("span");
    typedSpan.className = "typed";
    typedSpan.textContent = typed || " ";
    const remainingSpan = document.createElement("span");
    remainingSpan.className = "target-remaining";
    remainingSpan.textContent = remaining || " ";
    this.targetEl.replaceChildren(typedSpan, remainingSpan);
    if (this.input) {
      this.input.value = this.state.buffer;
    }
  }

  private updateMetrics(): void {
    const accuracy =
      this.state.totalInputs > 0 ? this.state.correctInputs / this.state.totalInputs : 1;
    const minutes = this.state.elapsedMs / 60000;
    const wpm = minutes > 0 ? (this.state.correctInputs / 5) / minutes : 0;
    if (this.accuracyEl) {
      this.accuracyEl.textContent = `${Math.round(accuracy * 100)}%`;
    }
    if (this.comboEl) {
      this.comboEl.textContent = `x${this.state.combo}`;
    }
    if (this.wpmEl) {
      this.wpmEl.textContent = Math.max(0, Math.round(wpm)).toString();
    }
    if (this.wordsEl) {
      this.wordsEl.textContent = `${this.state.wordsCompleted}`;
    }
    if (this.progressLabel) {
      const config = DRILL_CONFIGS[this.state.mode];
      if (typeof config.wordCount === "number") {
        this.progressLabel.textContent = `${this.state.wordsCompleted}/${config.wordCount}`;
      } else {
        this.progressLabel.textContent = `Words: ${this.state.wordsCompleted}`;
      }
    }
  }

  private updateTimer(): void {
    const label = this.timerLabel;
    if (!label) return;
    if (this.state.timerEndsAt && this.state.active) {
      const remainingMs = Math.max(0, this.state.timerEndsAt - performance.now());
      const minutes = Math.floor(remainingMs / 60000);
      const seconds = Math.floor((remainingMs % 60000) / 1000);
      label.textContent = `${minutes.toString().padStart(2, "0")}:${seconds
        .toString()
        .padStart(2, "0")}`;
      if (remainingMs <= 0) {
        this.finish("timeout");
      }
      return;
    }
    const elapsedSeconds = Math.max(0, this.state.elapsedMs / 1000);
    const minutes = Math.floor(elapsedSeconds / 60);
    const seconds = Math.floor(elapsedSeconds % 60);
    label.textContent = `${minutes.toString().padStart(2, "0")}:${seconds
      .toString()
      .padStart(2, "0")}`;
  }

  private startTimer(endsAt: number): () => void {
    const interval = window.setInterval(() => {
      this.state.elapsedMs =
        this.state.startTime > 0 ? Math.max(0, performance.now() - this.state.startTime) : 0;
      this.updateMetrics();
      this.updateTimer();
      if (performance.now() >= endsAt) {
        this.finish("timeout");
      }
    }, 120);
    return () => window.clearInterval(interval);
  }

  setRecommendation(mode: TypingDrillMode, reason: string): void {
    if (this.fallbackEl) {
      this.fallbackEl.dataset.visible = "false";
    }
    this.recommendationMode = mode;
    this.modeButtons.forEach((btn) => {
      const isRecommended = btn.dataset.mode === mode;
      btn.dataset.recommended = isRecommended ? "true" : "false";
    });
    if (this.recommendationEl && this.recommendationBadge && this.recommendationReason) {
      this.recommendationBadge.textContent =
        mode === "burst" ? "Warmup" : mode === "endurance" ? "Cadence" : "Accuracy";
      this.recommendationReason.textContent = reason;
      this.recommendationEl.dataset.visible = "true";
    }
  }

  showNoRecommendation(message: string, autoStartMode?: TypingDrillMode | null): void {
    if (this.recommendationEl) {
      this.recommendationEl.dataset.visible = "false";
    }
    this.recommendationMode = null;
    this.modeButtons.forEach((btn) => {
      btn.dataset.recommended = "false";
    });
    if (this.fallbackEl) {
      this.fallbackEl.dataset.visible = "true";
      const textNode = this.fallbackEl.querySelector(".typing-drill-fallback__text");
      if (textNode) {
        textNode.textContent = autoStartMode
          ? `${message} Starting ${this.getModeLabel(autoStartMode)}.`
          : message;
      }
    }
  }

  private getModeLabel(mode: TypingDrillMode): string {
    switch (mode) {
      case "precision":
        return "Shield Breaker";
      case "endurance":
        return "Endurance";
      case "burst":
      default:
        return "Burst Warmup";
    }
  }

  showToast(message: string): void {
    if (!this.toastEl) return;
    this.toastEl.textContent = message;
    this.toastEl.dataset.visible = "true";
    window.clearTimeout(this.toastTimeout ?? 0);
    this.toastTimeout = window.setTimeout(() => {
      if (this.toastEl) {
        this.toastEl.dataset.visible = "false";
        this.toastEl.textContent = "";
      }
    }, 3200);
  }
}
