// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-nocheck
const MS_PER_MINUTE = 60_000;

function formatTime(ms) {
  if (!Number.isFinite(ms) || ms < 0) return "00:00";
  const totalSeconds = Math.floor(ms / 1000);
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  if (minutes >= 60) {
    const hours = Math.floor(minutes / 60);
    const remainingMinutes = minutes % 60;
    return `${hours.toString().padStart(2, "0")}:${remainingMinutes
      .toString()
      .padStart(2, "0")}`;
  }
  return `${minutes.toString().padStart(2, "0")}:${seconds.toString().padStart(2, "0")}`;
}

export class SessionWellness {
  constructor(options = {}) {
    this.timerLabel =
      document.getElementById(options.timerId ?? "session-timer") ?? null;
    this.container =
      document.getElementById(options.reminderId ?? "break-reminder") ?? null;
    this.tipLabel =
      document.getElementById(options.tipId ?? "break-reminder-tip") ?? null;
    this.snoozeButton =
      document.getElementById(options.snoozeId ?? "break-reminder-snooze") ?? null;
    this.resetButton =
      document.getElementById(options.resetId ?? "break-reminder-reset") ?? null;
    this.handlers = {
      onSnooze: typeof options.onSnooze === "function" ? options.onSnooze : null,
      onReset: typeof options.onReset === "function" ? options.onReset : null
    };
    this.reminderVisible = false;
    if (this.snoozeButton) {
      this.snoozeButton.addEventListener("click", () => {
        this.handlers.onSnooze?.();
      });
    }
    if (this.resetButton) {
      this.resetButton.addEventListener("click", () => {
        this.handlers.onReset?.();
      });
    }
    if (this.container) {
      this.container.dataset.visible = this.container.dataset.visible ?? "false";
      this.container.setAttribute("aria-hidden", "true");
    }
  }

  setElapsed(elapsedMs) {
    if (this.timerLabel) {
      this.timerLabel.textContent = formatTime(elapsedMs);
      this.timerLabel.dataset.minutes = Math.floor(elapsedMs / MS_PER_MINUTE).toString();
    }
  }

  showReminder(elapsedMs, message) {
    if (!this.container) return;
    const minutes = Math.max(1, Math.floor(elapsedMs / MS_PER_MINUTE));
    if (this.tipLabel) {
      const copy =
        message ??
        `You have been practicing for ${minutes} minute${minutes === 1 ? "" : "s"}. Stand, stretch, and sip water.`;
      this.tipLabel.textContent = copy;
    }
    this.container.dataset.visible = "true";
    this.container.setAttribute("aria-hidden", "false");
    this.reminderVisible = true;
  }

  hideReminder() {
    if (!this.container) return;
    this.container.dataset.visible = "false";
    this.container.setAttribute("aria-hidden", "true");
    this.reminderVisible = false;
  }
}
