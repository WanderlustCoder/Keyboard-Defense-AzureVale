type Vec2 = { x: number; y: number };

type Particle = {
  position: Vec2;
  radius: number;
  velocity: Vec2;
  alpha: number;
  decay: number;
  color: string;
};

export type ParticleRendererOptions = {
  reducedMotion?: boolean;
  maxParticles?: number;
  offscreen?: boolean;
};

export class ParticleRenderer {
  private readonly ctx: OffscreenCanvasRenderingContext2D | CanvasRenderingContext2D | null;
  private readonly canvas: OffscreenCanvas | HTMLCanvasElement | null;
  private readonly maxParticles: number;
  private readonly reducedMotion: boolean;
  private particles: Particle[] = [];

  constructor(options: ParticleRendererOptions = {}) {
    this.reducedMotion = Boolean(options.reducedMotion);
    const baseMax = Math.max(1, options.maxParticles ?? 256);
    this.maxParticles = this.reducedMotion ? Math.min(baseMax, 48) : baseMax;

    if (options.offscreen !== false && typeof OffscreenCanvas !== "undefined") {
      this.canvas = new OffscreenCanvas(256, 256);
      this.ctx = this.canvas.getContext("2d");
    } else if (typeof document !== "undefined") {
      const canvas = document.createElement("canvas");
      canvas.width = 256;
      canvas.height = 256;
      this.canvas = canvas;
      this.ctx = canvas.getContext("2d");
    } else {
      // Headless fallback so tests can exercise decay without a DOM.
      const ctx = createHeadlessContext();
      // Preserve a stub canvas so callers still see a render target.
      this.canvas = (ctx as { canvas?: OffscreenCanvas | HTMLCanvasElement }).canvas ?? null;
      this.ctx = ctx;
    }
  }

  emitMuzzlePuff(position: Vec2, color = "rgba(255,255,255,0.8)") {
    if (!this.ctx) return;
    if (this.particles.length >= this.maxParticles) {
      this.particles.shift();
    }
    const velocityScale = this.reducedMotion ? 0 : 1;
    const radius = this.reducedMotion ? 4 + Math.random() * 1.5 : 6 + Math.random() * 4;
    const decay = this.reducedMotion ? 0.05 + Math.random() * 0.02 : 0.02 + Math.random() * 0.01;
    const jitter = this.reducedMotion ? 0 : 1;
    this.particles.push({
      position: { ...position },
      radius,
      velocity: {
        x: (Math.random() - 0.5) * 10 * velocityScale * jitter,
        y: (Math.random() - 0.5) * 6 * velocityScale * jitter
      },
      alpha: 1,
      decay,
      color
    });
  }

  step(deltaMs: number) {
    if (!this.ctx) return;
    const ctx = this.ctx;
    const fallbackCanvas = (ctx as unknown as { canvas?: { width: number; height: number } }).canvas ?? null;
    const canvas = this.canvas ?? fallbackCanvas;
    if (!canvas) return;
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    const dt = deltaMs / 16.67; // normalize to ~60fps
    const remaining: Particle[] = [];
    for (const p of this.particles) {
      const velocityScale = this.reducedMotion ? 0.02 : 0.1;
      p.position.x += p.velocity.x * dt * velocityScale;
      p.position.y += p.velocity.y * dt * velocityScale;
      p.alpha = Math.max(0, p.alpha - p.decay * dt);
      const shrinkRate = this.reducedMotion ? 0.1 : 0.25;
      p.radius = Math.max(0, p.radius - shrinkRate * dt);
      if (p.alpha <= 0 || p.radius <= 0) continue;
      ctx.globalAlpha = p.alpha;
      ctx.fillStyle = p.color;
      ctx.beginPath();
      ctx.arc(p.position.x, p.position.y, p.radius, 0, Math.PI * 2);
      ctx.fill();
      remaining.push(p);
    }
    this.particles = remaining;
    ctx.globalAlpha = 1;
  }

  getParticleCount(): number {
    return this.particles.length;
  }

  getCanvas(): OffscreenCanvas | HTMLCanvasElement | null {
    return this.canvas;
  }
}

function createHeadlessContext(): CanvasRenderingContext2D | OffscreenCanvasRenderingContext2D | null {
  // Minimal stub that satisfies the drawing calls; no real rendering needed for tests.
  const operations: unknown[] = [];
  return {
    canvas: { width: 256, height: 256 } as unknown as HTMLCanvasElement,
    clearRect: () => {},
    beginPath: () => {},
    arc: () => {},
    fill: () => {},
    set globalAlpha(value: number) {
      operations.push(["alpha", value]);
    },
    get globalAlpha() {
      return 1;
    },
    set fillStyle(value: string | CanvasGradient | CanvasPattern) {
      operations.push(["fillStyle", value]);
    },
    get fillStyle() {
      return "#fff";
    }
  } as unknown as CanvasRenderingContext2D;
}
