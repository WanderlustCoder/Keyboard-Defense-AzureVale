# Asset Performance & Optimization Specifications

## Design Philosophy
- **60 FPS Target**: Assets must not cause frame drops
- **Memory Conscious**: Optimize for low-end devices
- **Load Time Priority**: Fast level loading
- **Scalable Quality**: LOD options where beneficial

---

## PERFORMANCE BUDGETS

### Memory Budgets
```
Total Texture Memory:     64 MB maximum
Per-Scene Textures:       16 MB maximum
UI Textures:              8 MB
Character Sprites:        8 MB
Environment Tiles:        12 MB
Effects/Particles:        8 MB
Reserve/Buffer:           12 MB
```

### File Size Budgets
| Asset Type | Max Size | Target Size |
|------------|----------|-------------|
| Icon 8x8 | 500 B | 200 B |
| Icon 16x16 | 1 KB | 500 B |
| Sprite 16x24 | 2 KB | 1 KB |
| Sprite Sheet (4 frames) | 4 KB | 2 KB |
| Sprite Sheet (8 frames) | 6 KB | 3 KB |
| Large Sprite 32x40 | 4 KB | 2 KB |
| Boss Sprite 64x80 | 8 KB | 4 KB |
| Tile 16x16 | 1 KB | 500 B |
| UI Panel 48x48 | 3 KB | 1.5 KB |

---

## TEXTURE OPTIMIZATION

### Color Reduction
```
Recommended Colors:
- Simple icons:       4-8 colors
- Standard sprites:   8-12 colors
- Complex sprites:    12-16 colors
- UI elements:        4-8 colors

Maximum: 16 colors per sprite
```

### Compression Settings
```
PNG Optimization:
- Color type:     Indexed (palette) when possible
- Bit depth:      8-bit maximum
- Interlacing:    None
- Filter:         Auto (pngquant decides)
- Compression:    Maximum (level 9)

Tools:
- pngquant (lossy, excellent reduction)
- optipng (lossless optimization)
- pngcrush (lossless compression)
```

### Optimization Pipeline
```bash
# Step 1: Reduce colors with pngquant
pngquant --quality=80-100 --speed=1 input.png --output temp.png

# Step 2: Optimize with optipng
optipng -o7 temp.png -out output.png

# Step 3: Strip metadata
exiftool -all= output.png
```

---

## SPRITE ATLAS GUIDELINES

### Atlas Organization
```
Group by usage frequency:
- atlas_core.png:      Always loaded (HUD, player, common enemies)
- atlas_combat.png:    Combat assets (towers, projectiles, effects)
- atlas_ui.png:        UI elements (menus, buttons, panels)
- atlas_world_1.png:   World 1 specific assets
- atlas_world_2.png:   World 2 specific assets
```

### Atlas Size Limits
```
Maximum Atlas Size:  2048x2048 (4 MB uncompressed)
Recommended Size:    1024x1024 (1 MB uncompressed)
Minimum Padding:     2px between sprites
Power of 2:          Required for GPU efficiency
```

### Atlas Packing
```
Use tight packing:
- Algorithms: MaxRects, Guillotine
- Rotation: Disabled (pixel art)
- Trim: Enabled (remove transparent edges)
- Padding: 2px (prevent bleeding)
```

---

## ANIMATION OPTIMIZATION

### Frame Count Limits
| Animation Type | Max Frames | Notes |
|----------------|------------|-------|
| Idle | 4-6 | Loop frequently |
| Walk | 6 | Standard cycle |
| Attack | 6-8 | One-shot |
| Death | 8 | One-shot |
| Effect | 6 | Many instances |
| Particle | 4 | Very many instances |

### Animation Memory
```
Per animated sprite:
- Frame texture references (minimal)
- Current frame index (4 bytes)
- Animation timer (4 bytes)
- State enum (4 bytes)

Total per instance: ~20 bytes + texture references
```

### Shared Animations
```
Use AnimationLibrary:
- Share animation data between instances
- Single AnimationPlayer, multiple sprites
- Reduces memory per enemy type
```

---

## PARTICLE SYSTEM LIMITS

### Particle Budgets
```
Maximum Active Particles:      500 total screen
Maximum Per Effect:            50 particles
Maximum Emitters Active:       20 simultaneous
Particle Texture Size:         8x8 maximum
```

### Particle Optimization
```
Use GPU Particles when possible:
- CPUParticles2D: More features, higher CPU cost
- GPUParticles2D: Better performance, some limitations

Pool particle systems:
- Pre-instantiate common effects
- Reuse rather than create/destroy
- Object pool size: 20-30 per effect type
```

### Effect Priorities
```
Priority 1: Gameplay critical (hits, damage)
Priority 2: Player feedback (typing, combo)
Priority 3: Combat atmosphere (trails, impacts)
Priority 4: Ambient decoration (dust, sparkles)

When over budget: Skip Priority 4, reduce Priority 3
```

---

## RENDERING OPTIMIZATION

### Draw Call Reduction
```
Batch requirements:
- Same texture atlas
- Same material/shader
- Same render layer
- Contiguous in scene tree

Target: <100 draw calls per frame
Warning: >200 draw calls
```

### Layer Organization
```
CanvasLayer structure:
Layer -10: Background (parallax)
Layer 0:   Game world (tiles, entities)
Layer 10:  Effects (particles, overlays)
Layer 20:  UI elements
Layer 30:  Popups, tooltips
Layer 40:  Debug overlay
```

### Culling
```
Enable visibility culling:
- Off-screen sprites not processed
- Large margin for smooth entry
- Disable processing for invisible

VisibilityNotifier2D settings:
- Margin: 32px beyond screen
```

---

## LOADING OPTIMIZATION

### Asset Loading Strategy
```
Preload (at game start):
- Core UI elements
- Common enemy sprites
- Player character
- Basic effects

Load on demand:
- Level-specific assets
- Rare enemy types
- Boss assets
- Decorative elements

Background load:
- Next level assets
- Achievement graphics
- Optional content
```

### Load Time Targets
```
Initial load:        <5 seconds
Level transition:    <2 seconds
In-level loading:    <100ms (async)
Asset streaming:     Invisible to player
```

### Preload Manifest
```json
{
  "preload": [
    "res://assets/sprites/player/*",
    "res://assets/sprites/ui/hud/*",
    "res://assets/sprites/enemies/common/*"
  ],
  "demand_load": [
    "res://assets/sprites/bosses/*",
    "res://assets/sprites/world_*/*"
  ]
}
```

---

## MEMORY MANAGEMENT

### Texture Lifecycle
```
Load:
1. Read from disk
2. Decompress
3. Upload to GPU
4. Retain reference

Unload:
1. Remove references
2. Queue for deletion
3. GPU memory freed
4. RAM freed
```

### Resource Tracking
```gdscript
# Monitor resource usage
func _process(_delta):
    if OS.is_debug_build():
        var tex_mem = Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)
        var draw_calls = Performance.get_monitor(Performance.RENDER_2D_DRAW_CALLS_IN_FRAME)
        print("Texture Memory: %d MB" % (tex_mem / 1048576))
        print("Draw Calls: %d" % draw_calls)
```

### Memory Leak Prevention
```
Always:
- Free resources when done
- Use WeakRef for caches
- Clear references in _exit_tree
- Avoid circular references

Never:
- Store textures in static vars
- Hold level references globally
- Cache entire atlases unnecessarily
```

---

## MOBILE/LOW-END OPTIMIZATION

### Reduced Quality Mode
```
Visual reductions:
- Particle count: 50%
- Animation frames: -2 per animation
- Effect range: Reduced
- Ambient particles: Disabled
```

### Texture Quality Tiers
```
High (Default):
- Full resolution
- All atlases loaded

Medium:
- 50% resolution
- Reduced atlases

Low:
- 25% resolution
- Minimal atlases
- Reduced colors
```

### Performance Fallbacks
```
if FPS < 30:
    reduce_particle_count()
    disable_ambient_effects()
    simplify_shadows()

if FPS < 20:
    disable_all_particles()
    reduce_animation_frames()
    emergency_mode()
```

---

## PROFILING TARGETS

### Frame Time Budget (60 FPS = 16.67ms)
```
Rendering:      8ms maximum
Physics:        2ms maximum
Animation:      2ms maximum
Game Logic:     3ms maximum
Audio:          1ms maximum
Reserve:        0.67ms
```

### Render Time Breakdown
```
Background:     1ms
Tiles:          2ms
Entities:       2ms
Effects:        1ms
UI:             2ms
Total:          8ms
```

### Memory Breakdown (64 MB total)
```
Texture Atlas:  24 MB (6 × 2048×2048)
Audio:          16 MB
Fonts:          2 MB
Scripts/Data:   6 MB
Runtime:        16 MB
```

---

## QUALITY SETTINGS

### Graphics Options
| Setting | Low | Medium | High |
|---------|-----|--------|------|
| Particles | 25% | 50% | 100% |
| Animations | Basic | Normal | Full |
| Screen Shake | Off | Reduced | Full |
| Ambient FX | Off | Half | Full |
| Resolution | 720p | 1080p | Native |

### Settings Implementation
```gdscript
enum Quality { LOW, MEDIUM, HIGH }

var quality_presets = {
    Quality.LOW: {
        "particle_multiplier": 0.25,
        "animation_skip": 2,
        "ambient_enabled": false
    },
    Quality.MEDIUM: {
        "particle_multiplier": 0.50,
        "animation_skip": 0,
        "ambient_enabled": true
    },
    Quality.HIGH: {
        "particle_multiplier": 1.0,
        "animation_skip": 0,
        "ambient_enabled": true
    }
}
```

---

## BENCHMARKING

### Test Scenarios
```
Scenario 1: Idle
- Empty level
- Player only
- Target: 60 FPS, <10 MB

Scenario 2: Light Combat
- 10 enemies
- 3 towers
- Basic effects
- Target: 60 FPS, <20 MB

Scenario 3: Heavy Combat
- 30 enemies
- 7 towers
- Full effects
- Target: 60 FPS, <40 MB

Scenario 4: Boss Fight
- Boss + 10 enemies
- Maximum effects
- All systems active
- Target: 55+ FPS, <50 MB

Scenario 5: Stress Test
- 50 enemies
- 10 towers
- Extreme effects
- Target: 30+ FPS, <64 MB
```

### Performance Monitoring
```gdscript
# Continuous monitoring
var fps_samples = []
var memory_samples = []

func _process(_delta):
    fps_samples.append(Engine.get_frames_per_second())
    memory_samples.append(OS.get_static_memory_usage())

    if fps_samples.size() > 300:  # 5 seconds at 60fps
        analyze_performance()
        fps_samples.clear()
        memory_samples.clear()
```

---

## OPTIMIZATION CHECKLIST

### Per-Asset Checklist
- [ ] File size within budget
- [ ] Color count optimized
- [ ] PNG properly compressed
- [ ] Metadata stripped
- [ ] Correct atlas placement
- [ ] Proper mipmaps (if scaled)

### Per-Scene Checklist
- [ ] Draw calls under 100
- [ ] No orphan nodes
- [ ] Particles within budget
- [ ] Culling enabled
- [ ] Async loading used
- [ ] No memory leaks

### Release Checklist
- [ ] All quality tiers tested
- [ ] Mobile performance verified
- [ ] Load times acceptable
- [ ] Memory peaks tracked
- [ ] Stress test passed
- [ ] No dropped frames in gameplay

---

## TOOLS & DEBUGGING

### Godot Profiler
- Monitor frame time
- Identify render bottlenecks
- Track function costs
- Memory allocation view

### Debug Overlays
```gdscript
# Performance overlay
func draw_debug():
    var fps = Engine.get_frames_per_second()
    var mem = OS.get_static_memory_usage() / 1048576
    draw_string(font, Vector2(10, 20), "FPS: %d" % fps)
    draw_string(font, Vector2(10, 40), "MEM: %.1f MB" % mem)
```

### Validation Scripts
```bash
# Check all asset sizes
find assets/sprites -name "*.png" -size +10k -print

# Count colors in image
identify -format "%k colors\n" image.png

# Report texture memory
grep -r "expected_width" data/assets_manifest.json | \
  awk -F: '{sum += $2 * $3} END {print sum/1024, "KB total"}'
```

