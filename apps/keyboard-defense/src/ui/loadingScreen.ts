// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-nocheck
import { loadingTips as defaultLoadingTips } from "../data/loadingTips.js";

const TIP_INTERVAL_MS = 3800;
const MIN_TIP_INTERVAL_MS = 1500;

function normalizeTips(rawTips) {
  if (!Array.isArray(rawTips)) {
    return [...defaultLoadingTips];
  }
  const normalized = rawTips
    .map((tip) => (typeof tip === "string" ? tip.trim() : ""))
    .filter(Boolean);
  const unique = Array.from(new Set(normalized));
  return unique.length > 0 ? unique : [...defaultLoadingTips];
}
export class LoadingScreen {
  constructor(options = {}) {
    this.container =
      document.getElementById(options.containerId ?? "loading-screen") ?? null;
    this.statusLabel =
      document.getElementById(options.statusId ?? "loading-status") ?? null;
    this.tipLabel = document.getElementById(options.tipId ?? "loading-tip") ?? null;
    this.tipIntervalMs =
      typeof options.tipIntervalMs === "number" && options.tipIntervalMs >= MIN_TIP_INTERVAL_MS
        ? options.tipIntervalMs
        : TIP_INTERVAL_MS;
    this.tips = normalizeTips(options.tips ?? defaultLoadingTips);
    this.tipIndex = this.getCurrentTipIndex();
    this.tipTimer = null;
  }
  show(statusText) {
    if (!this.container) return;
    this.container.dataset.visible = "true";
    this.container.setAttribute("aria-busy", "true");
    if (statusText) this.setStatus(statusText);
    if (this.tipLabel && this.tips.length > 0) {
      this.tipIndex = this.getCurrentTipIndex();
      this.setTip(this.tips[this.tipIndex]);
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
    if (!this.tipLabel || this.tipTimer || this.tips.length < 2) return;
    this.tipTimer = window.setInterval(() => {
      this.tipIndex = (this.tipIndex + 1) % this.tips.length;
      this.setTip(this.tips[this.tipIndex]);
    }, this.tipIntervalMs);
  }
  stopTipRotation() {
    if (this.tipTimer) {
      clearInterval(this.tipTimer);
      this.tipTimer = null;
    }
  }

  getCurrentTipIndex() {
    if (!this.tipLabel || this.tips.length === 0) return 0;
    const current = (this.tipLabel.textContent ?? "").trim();
    const existingIndex = this.tips.findIndex((tip) => tip === current);
    if (existingIndex >= 0) {
      return existingIndex;
    }
    return Math.floor(Math.random() * this.tips.length);
  }
}
