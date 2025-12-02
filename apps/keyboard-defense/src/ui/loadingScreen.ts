// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-nocheck
const DEFAULT_TIPS = [
  "Keep wrists relaxed and float your fingers above home row.",
  "Look at the screen, not the keyboard — muscle memory wins battles.",
  "Short bursts first: accuracy > speed. Speed comes after clean reps.",
  "Use the spacebar with your thumbs to keep rhythm steady.",
  "Stretch your fingers before longer sessions to avoid fatigue.",
  "Balance hands: alternating between left/right keeps pace smooth.",
  "Shift with the opposite hand from the key you are typing.",
  "If accuracy drops, pause and breathe — reset your posture.",
  "Light taps beat heavy presses; less force means faster recovery.",
  "Glance at upcoming words so you are always one letter ahead."
];
const TIP_INTERVAL_MS = 3800;
export class LoadingScreen {
  constructor(options = {}) {
    this.container =
      document.getElementById(options.containerId ?? "loading-screen") ?? null;
    this.statusLabel =
      document.getElementById(options.statusId ?? "loading-status") ?? null;
    this.tipLabel = document.getElementById(options.tipId ?? "loading-tip") ?? null;
    this.tips =
      Array.isArray(options.tips) && options.tips.length > 0 ? options.tips : DEFAULT_TIPS;
    this.tipIndex = 0;
    this.tipTimer = null;
  }
  show(statusText) {
    if (!this.container) return;
    this.container.dataset.visible = "true";
    this.container.setAttribute("aria-busy", "true");
    if (statusText) this.setStatus(statusText);
    if (this.tipLabel && !this.tipLabel.textContent) {
      this.setTip(this.tips[this.tipIndex % this.tips.length]);
    }
    this.startTipRotation();
  }
  hide() {
    if (!this.container) return;
    this.container.dataset.visible = "false";
    this.container.removeAttribute("aria-busy");
    this.stopTipRotation();
  }
  setStatus(text) {
    if (!this.statusLabel || typeof text !== "string") return;
    this.statusLabel.textContent = text;
  }
  setTip(text) {
    if (!this.tipLabel || typeof text !== "string") return;
    this.tipLabel.textContent = text;
  }
  startTipRotation() {
    if (!this.tipLabel || this.tipTimer) return;
    this.tipTimer = window.setInterval(() => {
      this.tipIndex = (this.tipIndex + 1) % this.tips.length;
      this.setTip(this.tips[this.tipIndex]);
    }, TIP_INTERVAL_MS);
  }
  stopTipRotation() {
    if (this.tipTimer) {
      clearInterval(this.tipTimer);
      this.tipTimer = null;
    }
  }
}
