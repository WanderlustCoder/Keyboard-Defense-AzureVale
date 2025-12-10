/**
 * Lightweight speech synthesis helper for spoken menu cues.
 */
export class NarrationManager {
  private enabled = false;
  private readonly synth: SpeechSynthesis | null;

  constructor() {
    this.synth = typeof window !== "undefined" ? window.speechSynthesis ?? null : null;
  }

  setEnabled(enabled: boolean): void {
    this.enabled = Boolean(enabled);
    if (!this.enabled) {
      this.cancel();
    }
  }

  speak(message: string, options?: { interrupt?: boolean; rate?: number }): boolean {
    if (!this.enabled || !this.synth || typeof SpeechSynthesisUtterance === "undefined") {
      return false;
    }
    const trimmed = message?.trim();
    if (!trimmed) {
      return false;
    }
    if (options?.interrupt) {
      this.cancel();
    }
    const utterance = new SpeechSynthesisUtterance(trimmed);
    if (typeof options?.rate === "number" && Number.isFinite(options.rate)) {
      utterance.rate = options.rate;
    }
    this.synth.speak(utterance);
    return true;
  }

  cancel(): void {
    this.synth?.cancel();
  }
}
