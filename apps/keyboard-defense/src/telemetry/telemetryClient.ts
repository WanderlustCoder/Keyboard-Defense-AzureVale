import { type AnalyticsSnapshot, type WaveSummary } from "../core/types.js";

export interface TelemetryEnvelope {
  type: string;
  capturedAt: string;
  payload: unknown;
  metadata?: Record<string, unknown>;
}

export interface TelemetryClientOptions {
  enabled?: boolean;
  endpoint?: string | null;
  maxQueueSize?: number;
  batchSize?: number;
  onFlush?: (batch: TelemetryEnvelope[]) => void;
  onQueueChange?: (size: number) => void;
  transport?: (
    endpoint: string,
    batch: ReadonlyArray<TelemetryEnvelope>
  ) => void | Promise<void>;
}

const TELEMETRY_QUEUE_STORAGE_KEY = "keyboard-defense:telemetry-queue";
const TELEMETRY_QUEUE_VERSION = 1;
const DEFAULT_MAX_QUEUE_SIZE = 750;
const DEFAULT_BATCH_SIZE = 25;

type StoredTelemetryQueue = {
  version: number;
  queue: TelemetryEnvelope[];
};

function safeJsonStringify(value: unknown): string | null {
  try {
    return JSON.stringify(value);
  } catch {
    // Fallback: tolerate circular structures/bigints by degrading the payload.
    try {
      const seen = new WeakSet<object>();
      return JSON.stringify(value, (_key, entry) => {
        if (typeof entry === "bigint") return entry.toString();
        if (typeof entry === "object" && entry !== null) {
          const obj = entry as object;
          if (seen.has(obj)) return "[Circular]";
          seen.add(obj);
        }
        return entry;
      });
    } catch {
      return null;
    }
  }
}

function safeGetStorage(): Storage | null {
  try {
    if (typeof window !== "undefined" && window.localStorage) {
      return window.localStorage;
    }
  } catch {
    // ignore
  }

  try {
    const candidate = (globalThis as unknown as { localStorage?: unknown }).localStorage;
    if (!candidate) return null;
    const storage = candidate as Storage;
    if (
      typeof storage.getItem === "function" &&
      typeof storage.setItem === "function" &&
      typeof storage.removeItem === "function"
    ) {
      return storage;
    }
  } catch {
    // ignore
  }

  return null;
}

function parseStoredQueue(raw: string | null): TelemetryEnvelope[] {
  if (!raw) return [];
  try {
    const parsed = JSON.parse(raw) as unknown;
    if (!parsed || typeof parsed !== "object") return [];
    const data = parsed as Partial<StoredTelemetryQueue>;
    if (data.version !== TELEMETRY_QUEUE_VERSION) return [];
    if (!Array.isArray(data.queue)) return [];

    const sanitized: TelemetryEnvelope[] = [];
    for (const entry of data.queue) {
      if (!entry || typeof entry !== "object") continue;
      const envelope = entry as Partial<TelemetryEnvelope>;
      if (typeof envelope.type !== "string" || envelope.type.trim().length === 0) continue;
      if (typeof envelope.capturedAt !== "string" || envelope.capturedAt.length === 0) continue;

      const metadata =
        envelope.metadata && typeof envelope.metadata === "object" && !Array.isArray(envelope.metadata)
          ? (envelope.metadata as Record<string, unknown>)
          : undefined;

      sanitized.push({
        type: envelope.type,
        capturedAt: envelope.capturedAt,
        payload: envelope.payload,
        metadata
      });
    }
    return sanitized;
  } catch {
    return [];
  }
}

function normalizeSize(value: unknown, fallback: number, options?: { min?: number; max?: number }): number {
  const min = options?.min ?? 0;
  const max = options?.max ?? Number.POSITIVE_INFINITY;
  const numeric = typeof value === "number" ? value : Number.NaN;
  if (!Number.isFinite(numeric)) return fallback;
  const clamped = Math.min(max, Math.max(min, numeric));
  return Math.floor(clamped);
}

export class TelemetryClient {
  private enabled: boolean;
  private endpoint: string | null;
  private readonly queue: TelemetryEnvelope[];
  private readonly maxQueueSize: number;
  private readonly batchSize: number;
  private readonly onFlush?;
  private readonly onQueueChange?;
  private readonly transport?;
  private readonly storage: Storage | null;

  constructor(options: TelemetryClientOptions = {}) {
    this.enabled = options.enabled !== false;
    this.endpoint = typeof options.endpoint === "string" ? options.endpoint.trim() || null : null;
    this.maxQueueSize = normalizeSize(options.maxQueueSize, DEFAULT_MAX_QUEUE_SIZE, {
      min: 0,
      max: 25_000
    });
    this.batchSize = normalizeSize(options.batchSize, DEFAULT_BATCH_SIZE, { min: 1, max: 500 });
    this.onFlush = options.onFlush;
    this.onQueueChange = options.onQueueChange;
    this.transport = options.transport;
    this.storage = safeGetStorage();

    const restored = this.storage ? parseStoredQueue(this.storage.getItem(TELEMETRY_QUEUE_STORAGE_KEY)) : [];
    const trimmed = this.maxQueueSize > 0 ? restored.slice(-this.maxQueueSize) : [];
    this.queue = [...trimmed];
    this.onQueueChange?.(this.queue.length);
  }

  setEnabled(enabled: boolean): void {
    this.enabled = Boolean(enabled);
  }

  isEnabled(): boolean {
    return this.enabled;
  }

  setEndpoint(endpoint: string | null): void {
    const normalized = typeof endpoint === "string" ? endpoint.trim() : "";
    this.endpoint = normalized.length > 0 ? normalized : null;
  }

  getEndpoint(): string | null {
    return this.endpoint;
  }

  getQueue(): readonly TelemetryEnvelope[] {
    return [...this.queue];
  }

  track(type: string, payload: unknown, metadata?: Record<string, unknown>): void {
    if (!this.enabled) return;
    if (typeof type !== "string") return;
    const normalizedType = type.trim();
    if (normalizedType.length === 0) return;
    const envelope: TelemetryEnvelope = {
      type: normalizedType,
      capturedAt: new Date().toISOString(),
      payload,
      metadata: metadata ? { ...metadata } : undefined
    };
    this.enqueue(envelope);
  }

  enqueueWaveSummary(summary: WaveSummary, extra?: Record<string, unknown>): void {
    this.track("wave-summary", summary, extra);
  }

  enqueueAnalyticsSnapshot(snapshot: AnalyticsSnapshot, extra?: Record<string, unknown>): void {
    this.track("analytics-snapshot", snapshot, extra);
  }

  purge(): number {
    const removed = this.queue.length;
    if (removed === 0) return 0;
    this.queue.splice(0, removed);
    this.persistQueue();
    this.onQueueChange?.(this.queue.length);
    return removed;
  }

  flush(): TelemetryEnvelope[] {
    const endpoint = this.endpoint;
    if (!this.enabled) return [];
    if (!endpoint) return [];

    const batch = this.queue.splice(0, this.batchSize);
    if (batch.length === 0) return [];

    this.persistQueue();
    this.onQueueChange?.(this.queue.length);

    const send = this.transport ?? ((target: string, payload: ReadonlyArray<TelemetryEnvelope>) =>
      this.sendWithDefaultTransport(target, payload));

    try {
      const result = send(endpoint, batch);
      if (result && typeof (result as Promise<void>).catch === "function") {
        void (result as Promise<void>).catch(() => this.restoreBatch(batch));
      }
    } catch {
      this.restoreBatch(batch);
    }

    this.onFlush?.(batch);
    return batch;
  }

  private enqueue(envelope: TelemetryEnvelope): void {
    if (this.maxQueueSize <= 0) {
      return;
    }
    this.queue.push(envelope);
    const overflow = this.queue.length - this.maxQueueSize;
    if (overflow > 0) {
      this.queue.splice(0, overflow);
    }
    this.persistQueue();
    this.onQueueChange?.(this.queue.length);
  }

  private persistQueue(): void {
    if (!this.storage) return;
    if (this.queue.length === 0) {
      try {
        this.storage.removeItem(TELEMETRY_QUEUE_STORAGE_KEY);
      } catch {
        // ignore
      }
      return;
    }
    const payload: StoredTelemetryQueue = {
      version: TELEMETRY_QUEUE_VERSION,
      queue: this.queue
    };
    const serialized = safeJsonStringify(payload);
    if (serialized === null) return;

    try {
      this.storage.setItem(TELEMETRY_QUEUE_STORAGE_KEY, serialized);
    } catch {
      // Try trimming the oldest half of the queue to recover from quota errors.
      const drop = Math.ceil(this.queue.length / 2);
      if (drop > 0) {
        this.queue.splice(0, drop);
      }
      try {
        const fallbackPayload: StoredTelemetryQueue = {
          version: TELEMETRY_QUEUE_VERSION,
          queue: this.queue
        };
        const retry = safeJsonStringify(fallbackPayload);
        if (retry === null) return;
        this.storage.setItem(TELEMETRY_QUEUE_STORAGE_KEY, retry);
      } catch {
        try {
          this.storage.removeItem(TELEMETRY_QUEUE_STORAGE_KEY);
        } catch {
          // ignore
        }
      }
    }
  }

  private restoreBatch(batch: TelemetryEnvelope[]): void {
    if (batch.length === 0) return;
    this.queue.unshift(...batch);
    const overflow = this.queue.length - this.maxQueueSize;
    if (overflow > 0) {
      this.queue.splice(this.queue.length - overflow, overflow);
    }
    this.persistQueue();
    this.onQueueChange?.(this.queue.length);
  }

  private sendWithDefaultTransport(endpoint: string, batch: ReadonlyArray<TelemetryEnvelope>): void | Promise<void> {
    const body = safeJsonStringify({
      flushedAt: new Date().toISOString(),
      batch
    });
    if (body === null) {
      throw new Error("Telemetry payload was not serializable.");
    }

    if (typeof navigator !== "undefined" && typeof navigator.sendBeacon === "function" && typeof Blob !== "undefined") {
      try {
        const blob = new Blob([body], { type: "application/json" });
        const ok = navigator.sendBeacon(endpoint, blob);
        if (ok) return;
      } catch {
        // fall back
      }
    }

    if (typeof fetch !== "function") {
      throw new Error("Fetch unavailable for telemetry transport.");
    }

    return fetch(endpoint, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body,
      keepalive: true
    }).then((response) => {
      if (!response.ok) {
        throw new Error(`Telemetry flush failed (${response.status} ${response.statusText})`);
      }
    });
  }
}
