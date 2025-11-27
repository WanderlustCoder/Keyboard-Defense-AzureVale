export type ResolutionTransitionState = "idle" | "running";

export interface ResolutionTransitionOptions {
  fadeMs?: number;
  holdMs?: number;
  onStateChange?: (state: ResolutionTransitionState) => void;
}

export class ResolutionTransitionController {
  private overlay: HTMLCanvasElement | null = null;
  private cleanupTimer: number | null = null;
  private state: ResolutionTransitionState = "idle";

  constructor(
    private readonly canvas: HTMLCanvasElement,
    private readonly options: ResolutionTransitionOptions = {}
  ) {}

  trigger(bounds?: DOMRect | null) {
    if (typeof document === "undefined" || typeof window === "undefined") {
      return;
    }
    const overlay = document.createElement("canvas");
    overlay.className = "canvas-transition-overlay";
    overlay.width = this.canvas.width;
    overlay.height = this.canvas.height;
    const ctx = overlay.getContext("2d");
    if (!ctx) {
      return;
    }
    try {
      ctx.drawImage(this.canvas, 0, 0, overlay.width, overlay.height);
    } catch {
      return;
    }

    const rect = bounds ?? this.canvas.getBoundingClientRect();
    overlay.style.position = "fixed";
    overlay.style.left = `${Math.round(rect.left)}px`;
    overlay.style.top = `${Math.round(rect.top)}px`;
    overlay.style.width = `${Math.max(1, Math.round(rect.width))}px`;
    overlay.style.height = `${Math.max(1, Math.round(rect.height))}px`;
    overlay.style.pointerEvents = "none";
    overlay.style.opacity = "1";
    overlay.style.transition = `opacity ${this.fadeMs}ms ease`;
    overlay.dataset.transition = "canvas-resolution";

    document.body.appendChild(overlay);
    this.disposeOverlay();
    this.overlay = overlay;
    this.setState("running");

    requestAnimationFrame(() => {
      overlay.style.opacity = "0";
    });

    const duration = this.getDuration();
    this.cleanupTimer = window.setTimeout(() => {
      this.disposeOverlay();
      this.setState("idle");
    }, duration);
  }

  getDuration() {
    return this.fadeMs + this.holdMs;
  }

  destroy() {
    if (this.cleanupTimer !== null && typeof window !== "undefined") {
      window.clearTimeout(this.cleanupTimer);
      this.cleanupTimer = null;
    }
    this.disposeOverlay();
    this.setState("idle");
  }

  private disposeOverlay() {
    if (this.overlay && this.overlay.parentNode) {
      this.overlay.parentNode.removeChild(this.overlay);
    }
    this.overlay = null;
  }

  private setState(next: ResolutionTransitionState) {
    if (this.state === next) return;
    this.state = next;
    this.options.onStateChange?.(next);
  }

  private get fadeMs() {
    return typeof this.options.fadeMs === "number" ? this.options.fadeMs : 180;
  }

  private get holdMs() {
    return typeof this.options.holdMs === "number" ? this.options.holdMs : 70;
  }
}
