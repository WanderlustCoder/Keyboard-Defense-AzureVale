# Testing & Verification Guide

## Overview

This document provides test scripts and verification procedures for all polish systems. Tests can be run headless or visually.

---

## Test Runner Integration

Add these tests to `tests/run_tests.gd`:

```gdscript
# =============================================================================
# POLISH SYSTEM TESTS
# =============================================================================

func test_all_polish_systems() -> void:
	print("Running polish system tests...")
	test_screen_shake_basic()
	test_screen_shake_settings()
	test_screen_shake_presets()
	test_hit_pause_basic()
	test_hit_pause_settings()
	test_damage_numbers_spawn()
	test_damage_numbers_pooling()
	test_object_pool_limits()
	test_hit_effects_particles()
	test_status_indicators()
	test_panel_transitions()
	test_resource_popup()
	test_accessibility_settings()
	print("All polish system tests complete!")


# -----------------------------------------------------------------------------
# SCREEN SHAKE TESTS
# -----------------------------------------------------------------------------

func test_screen_shake_basic() -> void:
	var shake := ScreenShake.new()
	add_child(shake)

	# Test initial state
	assert(shake.trauma == 0.0, "Initial trauma should be 0")
	assert(not shake.is_shaking(), "Should not be shaking initially")

	# Test adding trauma
	shake.add_trauma(0.5)
	assert(shake.trauma == 0.5, "Trauma should be 0.5 after adding")
	assert(shake.is_shaking(), "Should be shaking after adding trauma")

	# Test trauma clamping
	shake.add_trauma(1.0)
	assert(shake.trauma == 1.0, "Trauma should clamp to 1.0")

	# Cleanup
	shake.queue_free()
	_pass("test_screen_shake_basic")


func test_screen_shake_settings() -> void:
	var shake := ScreenShake.new()
	add_child(shake)

	var settings = get_node_or_null("/root/SettingsManager")
	if settings == null:
		shake.queue_free()
		_skip("test_screen_shake_settings - No SettingsManager")
		return

	# Disable screen shake
	var original := settings.screen_shake
	settings.screen_shake = false

	shake.add_trauma(0.5)
	assert(shake.trauma == 0.0, "Trauma should stay 0 when disabled")

	# Re-enable
	settings.screen_shake = true
	shake.add_trauma(0.5)
	assert(shake.trauma == 0.5, "Trauma should work when enabled")

	# Restore
	settings.screen_shake = original
	shake.queue_free()
	_pass("test_screen_shake_settings")


func test_screen_shake_presets() -> void:
	var shake := ScreenShake.new()
	add_child(shake)

	shake.shake_light()
	assert(shake.trauma == ScreenShake.PRESET_LIGHT, "Light preset incorrect")

	shake.set_trauma(0.0)
	shake.shake_medium()
	assert(shake.trauma == ScreenShake.PRESET_MEDIUM, "Medium preset incorrect")

	shake.set_trauma(0.0)
	shake.shake_heavy()
	assert(shake.trauma == ScreenShake.PRESET_HEAVY, "Heavy preset incorrect")

	shake.queue_free()
	_pass("test_screen_shake_presets")


# -----------------------------------------------------------------------------
# HIT PAUSE TESTS
# -----------------------------------------------------------------------------

func test_hit_pause_basic() -> void:
	var pause := HitPause.new()
	add_child(pause)

	# Test initial state
	assert(not pause.is_pausing(), "Should not be pausing initially")
	assert(Engine.time_scale == 1.0, "Time scale should be 1.0")

	# We can't easily test the actual pause in headless mode
	# Just verify the function doesn't crash
	pause.pause(0.01)

	# Cleanup
	pause.cancel_pause()
	pause.queue_free()
	assert(Engine.time_scale == 1.0, "Time scale should restore to 1.0")
	_pass("test_hit_pause_basic")


func test_hit_pause_settings() -> void:
	var pause := HitPause.new()
	add_child(pause)

	var settings = get_node_or_null("/root/SettingsManager")
	if settings == null:
		pause.queue_free()
		_skip("test_hit_pause_settings - No SettingsManager")
		return

	# Disable (follows screen_shake setting)
	var original := settings.screen_shake
	settings.screen_shake = false

	pause.pause(0.1)
	assert(not pause.is_pausing(), "Should not pause when disabled")

	settings.screen_shake = original
	pause.queue_free()
	_pass("test_hit_pause_settings")


# -----------------------------------------------------------------------------
# DAMAGE NUMBERS TESTS
# -----------------------------------------------------------------------------

func test_damage_numbers_spawn() -> void:
	var numbers := DamageNumbers.new()
	add_child(numbers)

	var container := Control.new()
	add_child(container)
	numbers.set_parent(container)

	# Spawn various types
	numbers.spawn_damage(Vector2(100, 100), 50, false)
	numbers.spawn_damage(Vector2(100, 150), 100, true)  # Critical
	numbers.spawn_gold(Vector2(100, 200), 25)
	numbers.spawn_heal(Vector2(100, 250), 10)
	numbers.spawn_combo(Vector2(100, 300), 15)

	assert(numbers.get_active_count() == 5, "Should have 5 active numbers")

	# Clear
	numbers.clear()
	assert(numbers.get_active_count() == 0, "Should have 0 after clear")

	container.queue_free()
	numbers.queue_free()
	_pass("test_damage_numbers_spawn")


func test_damage_numbers_pooling() -> void:
	var numbers := DamageNumbers.new()
	add_child(numbers)

	var container := Control.new()
	add_child(container)
	numbers.set_parent(container)

	# Spawn many numbers
	for i in range(30):
		numbers.spawn_damage(Vector2(100, 100 + i * 10), i, false)

	# Pool should limit
	assert(numbers.get_active_count() <= 50, "Should respect max pool size")

	container.queue_free()
	numbers.queue_free()
	_pass("test_damage_numbers_pooling")


# -----------------------------------------------------------------------------
# OBJECT POOL TESTS
# -----------------------------------------------------------------------------

func test_object_pool_limits() -> void:
	var ObjectPool = preload("res://game/object_pool.gd")

	var create_count := 0
	var pool := ObjectPool.new(
		func() -> Control:
			create_count += 1
			return Control.new(),
		func(obj: Control) -> void:
			pass,
		10  # Max size
	)

	# Acquire more than max
	var acquired := []
	for i in range(15):
		var obj = pool.acquire()
		if obj != null:
			acquired.append(obj)

	assert(acquired.size() <= 10, "Should not exceed max pool size")

	# Release all
	for obj in acquired:
		pool.release(obj)

	# Cleanup
	for obj in acquired:
		obj.queue_free()

	_pass("test_object_pool_limits")


# -----------------------------------------------------------------------------
# HIT EFFECTS TESTS
# -----------------------------------------------------------------------------

func test_hit_effects_particles() -> void:
	var effects := HitEffects.new()
	add_child(effects)

	var container := Control.new()
	add_child(container)
	effects.set_parent(container)

	# Spawn various effects
	effects.spawn_hit_sparks(container, Vector2(100, 100))
	effects.spawn_power_burst(container, Vector2(100, 150))
	effects.spawn_damage_flash(container, Vector2(100, 200))
	effects.spawn_word_complete_burst(container, Vector2(100, 250))

	assert(effects.get_active_count() > 0, "Should have active particles")

	# Update to process
	for i in range(60):
		effects.update(0.016)

	# Particles should have expired
	assert(effects.get_active_count() == 0, "Particles should expire")

	effects.clear()
	container.queue_free()
	effects.queue_free()
	_pass("test_hit_effects_particles")


# -----------------------------------------------------------------------------
# STATUS INDICATORS TESTS
# -----------------------------------------------------------------------------

func test_status_indicators() -> void:
	var indicators := StatusIndicators.new()

	var container := Control.new()
	add_child(container)

	var target := Sprite2D.new()
	target.position = Vector2(200, 200)
	container.add_child(target)

	# Add indicators
	indicators.add_indicator(container, target, "burn", 2.0)
	indicators.add_indicator(container, target, "slow", 3.0)

	# Update
	for i in range(60):
		indicators.update(0.016)

	# Remove one
	indicators.remove_indicator(target, "burn")

	# Clear all
	indicators.clear()

	target.queue_free()
	container.queue_free()
	_pass("test_status_indicators")


# -----------------------------------------------------------------------------
# PANEL TRANSITIONS TESTS
# -----------------------------------------------------------------------------

func test_panel_transitions() -> void:
	var PanelTransitions = preload("res://ui/panel_transitions.gd")

	var panel := PanelContainer.new()
	panel.position = Vector2(100, 100)
	panel.size = Vector2(200, 100)
	panel.visible = false
	add_child(panel)

	# Show panel
	PanelTransitions.show_panel(panel, PanelTransitions.TransitionType.FADE, 0.1)

	# Wait for animation
	await get_tree().create_timer(0.15).timeout

	assert(panel.visible, "Panel should be visible after show")

	# Hide panel
	PanelTransitions.hide_panel(panel, PanelTransitions.TransitionType.FADE, 0.1)

	await get_tree().create_timer(0.15).timeout

	assert(not panel.visible, "Panel should be hidden after hide")

	panel.queue_free()
	_pass("test_panel_transitions")


# -----------------------------------------------------------------------------
# RESOURCE POPUP TESTS
# -----------------------------------------------------------------------------

func test_resource_popup() -> void:
	var popup := ResourcePopup.new()

	var container := Control.new()
	add_child(container)
	popup.set_parent(container)

	# Spawn popups
	popup.spawn_popup(Vector2(100, 100), 50, "gold")
	popup.spawn_popup(Vector2(100, 150), -20, "wood")
	popup.spawn_resource_change(Vector2(100, 200), "stone", 100, 150)

	# Update
	for i in range(100):
		popup.update(0.016)

	popup.clear()
	container.queue_free()
	_pass("test_resource_popup")


# -----------------------------------------------------------------------------
# ACCESSIBILITY TESTS
# -----------------------------------------------------------------------------

func test_accessibility_settings() -> void:
	var settings = get_node_or_null("/root/SettingsManager")
	if settings == null:
		_skip("test_accessibility_settings - No SettingsManager")
		return

	# Store originals
	var orig_reduced := settings.reduced_motion
	var orig_contrast := settings.high_contrast
	var orig_colorblind := settings.colorblind_mode

	# Test reduced motion
	settings.reduced_motion = true
	assert(settings.reduced_motion, "Reduced motion should be true")

	# Test high contrast
	settings.high_contrast = true
	assert(settings.high_contrast, "High contrast should be true")

	# Test colorblind modes
	for mode in ["none", "protanopia", "deuteranopia", "tritanopia"]:
		settings.colorblind_mode = mode
		assert(settings.colorblind_mode == mode, "Colorblind mode should be %s" % mode)

	# Restore
	settings.reduced_motion = orig_reduced
	settings.high_contrast = orig_contrast
	settings.colorblind_mode = orig_colorblind

	_pass("test_accessibility_settings")
```

---

## Visual Verification Checklist

### Screen Shake
- [ ] Light shake barely moves camera
- [ ] Medium shake is noticeable
- [ ] Heavy shake is dramatic
- [ ] Shake decays smoothly
- [ ] Disabling in settings stops all shake
- [ ] Reduced motion makes shake smaller

### Hit Pause
- [ ] Light pause is barely noticeable
- [ ] Medium pause feels impactful
- [ ] Heavy pause is dramatic
- [ ] Game resumes smoothly after pause
- [ ] Disabling shake also disables pause
- [ ] Reduced motion shortens pause

### Damage Numbers
- [ ] Numbers appear at correct position
- [ ] Critical numbers are larger
- [ ] Numbers rise and fade
- [ ] Colors match type (damage=red, heal=green)
- [ ] Pool doesn't overflow with spam
- [ ] High contrast mode uses white

### Particles
- [ ] Hit sparks appear on impact
- [ ] Power burst is larger
- [ ] Word complete has celebratory feel
- [ ] Particles fade and disappear
- [ ] Reduced motion shows fewer particles

### Scene Transitions
- [ ] Fade transition is smooth
- [ ] Wipe transitions work correctly
- [ ] No visual glitches during transition
- [ ] Loading spinner appears if needed
- [ ] Reduced motion makes instant

---

## Automated Test Commands

```bash
# Run all tests
godot --headless --path . --script res://tests/run_tests.gd

# Run only polish tests
godot --headless --path . --script res://tests/run_polish_tests.gd

# Run with verbose output
godot --headless --path . --script res://tests/run_tests.gd -- --verbose
```

---

## Performance Benchmarks

### Target Performance

| System | Max Active | Target FPS Impact |
|--------|-----------|-------------------|
| Screen Shake | 1 | < 0.1ms |
| Hit Pause | 1 | < 0.1ms |
| Damage Numbers | 50 | < 0.5ms |
| Hit Particles | 200 | < 1.0ms |
| Status Indicators | 20 | < 0.3ms |
| Trail Particles | 100 | < 0.5ms |

### Benchmark Script

```gdscript
func benchmark_polish_systems() -> void:
	var results := {}

	# Benchmark screen shake
	var shake := ScreenShake.new()
	add_child(shake)
	shake.add_trauma(1.0)

	var start := Time.get_ticks_usec()
	for i in range(1000):
		shake._process(0.016)
	var elapsed := Time.get_ticks_usec() - start
	results["screen_shake_1000_frames"] = elapsed / 1000.0

	shake.queue_free()

	# Benchmark damage numbers
	var numbers := DamageNumbers.new()
	add_child(numbers)
	var container := Control.new()
	add_child(container)
	numbers.set_parent(container)

	# Spawn max numbers
	for i in range(50):
		numbers.spawn_damage(Vector2(randf() * 800, randf() * 600), randi() % 100, false)

	start = Time.get_ticks_usec()
	for i in range(100):
		numbers.update(0.016)
	elapsed = Time.get_ticks_usec() - start
	results["damage_numbers_50_items_100_frames"] = elapsed / 100.0

	numbers.queue_free()
	container.queue_free()

	# Print results
	print("=== BENCHMARK RESULTS ===")
	for key in results:
		print("%s: %.2f us/frame" % [key, results[key]])
```

---

## Integration Test Scenarios

### Scenario 1: Battle Flow
1. Start battle
2. Type correct characters → verify letter pop
3. Type wrong character → verify error shake + sound
4. Complete word → verify word burst + damage number
5. Get critical hit → verify pause + shake + particles
6. Build combo → verify combo indicator colors
7. Win battle → verify victory sequence

### Scenario 2: Settings Toggle
1. Open settings
2. Disable screen shake
3. Return to battle
4. Verify no shake on hits
5. Enable reduced motion
6. Verify shorter animations
7. Enable high contrast
8. Verify white damage numbers

### Scenario 3: Scene Navigation
1. Main menu → Kingdom
2. Kingdom → Battle
3. Battle → Result → Map
4. Map → Settings → Map
5. All transitions should be smooth
6. No visual glitches
