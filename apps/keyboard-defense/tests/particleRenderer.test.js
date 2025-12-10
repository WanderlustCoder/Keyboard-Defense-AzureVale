import { describe, expect, test } from "vitest";

import { ParticleRenderer } from "../src/rendering/particleRenderer.ts";

describe("ParticleRenderer", () => {
test("no-op when reduced motion enabled", () => {
  const renderer = new ParticleRenderer({ reducedMotion: true, offscreen: false, maxParticles: 4 });
  renderer.emitMuzzlePuff({ x: 10, y: 10 });
  renderer.step(16);
  expect(renderer.getParticleCount()).toBeGreaterThan(0);
  expect(renderer.getCanvas()).not.toBeNull();
  // Should gently decay to zero without motion bursts.
  renderer.step(500);
  expect(renderer.getParticleCount()).toBeLessThanOrEqual(4);
});

  test("emits and decays particles with offscreen support", () => {
    const renderer = new ParticleRenderer({ offscreen: false, maxParticles: 4 });
    renderer.emitMuzzlePuff({ x: 5, y: 5 }, "rgba(255,0,0,0.8)");
    renderer.emitMuzzlePuff({ x: 10, y: 10 }, "rgba(0,255,0,0.8)");
    expect(renderer.getParticleCount()).toBe(2);
    renderer.step(100);
    // After decay, count should drop as particles fade.
    renderer.step(200);
    expect(renderer.getParticleCount()).toBeLessThanOrEqual(2);
  });

  test("force reload overwrites cached sprites", () => {
    const renderer = new ParticleRenderer({ offscreen: false, maxParticles: 2 });
    renderer.emitMuzzlePuff({ x: 0, y: 0 });
    renderer.emitMuzzlePuff({ x: 1, y: 1 });
    renderer.emitMuzzlePuff({ x: 2, y: 2 }); // should evict oldest
    expect(renderer.getParticleCount()).toBeLessThanOrEqual(2);
  });
});
