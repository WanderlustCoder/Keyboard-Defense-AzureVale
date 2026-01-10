# Onboarding & Tutorial Guide

This document explains the new player onboarding system and tutorial flow in Keyboard Defense.

## Overview

The onboarding system guides new players through core mechanics:

```
Welcome → Day Actions → End Day → Night Typing → Reach Dawn → Wrap Up
    ↓         ↓           ↓           ↓            ↓           ↓
  help   gather/build    end     type words    survive    panels
```

## Tutorial Steps

### Step Structure

```gdscript
# game/onboarding_flow.gd:20
const STEPS: Array = [
    {
        "id": "welcome_focus",
        "title": "Welcome to Keyboard Defense",
        "body_lines": [...],
        "try_line": "Try this: help",
        "success_line": "Success: The log shows the help output."
    },
    // ... more steps
]
```

### All Steps

| Step | ID | Title | Completion Criteria |
|------|----|----|---------------------|
| 1 | `welcome_focus` | Welcome to Keyboard Defense | Used help or status command |
| 2 | `day_actions` | Daytime actions | Built, explored, and gathered |
| 3 | `end_day` | End the day | Entered night phase |
| 4 | `night_typing` | Defend by typing | Hit an enemy |
| 5 | `reach_dawn` | Reach dawn | Survived to day phase |
| 6 | `wrap_up` | Panels and replay | Opened lessons, settings, toggled tutorial |

### Step 1: Welcome Focus

```gdscript
{
    "id": "welcome_focus",
    "title": "Welcome to Keyboard Defense",
    "body_lines": [
        "This game is typing-first. Keep your hands on the keyboard.",
        "The command bar stays focused so you can act instantly.",
        "We will use short commands to learn the day and night loop."
    ],
    "try_line": "Try this: help",
    "success_line": "Success: The log shows the help output."
}
```

Completes when: `snapshot.used_help_or_status == true`

### Step 2: Day Actions

```gdscript
{
    "id": "day_actions",
    "title": "Daytime actions",
    "body_lines": [
        "Daytime is for gathering, building, and exploring.",
        "Actions cost AP, so pick a small plan each day.",
        "Watch the log to confirm each command result."
    ],
    "try_line": "Try this: gather wood 5, build farm, explore",
    "success_line": "Success: Resources change and a tile is discovered."
}
```

Completes when: `did_build && did_explore && did_gather`

### Step 3: End Day

```gdscript
{
    "id": "end_day",
    "title": "End the day",
    "body_lines": [
        "Ending the day starts the night wave.",
        "Production happens immediately when you end the day.",
        "A defend prompt will appear at night."
    ],
    "try_line": "Try this: end",
    "success_line": "Success: Phase changes to night and a prompt appears."
}
```

Completes when: `entered_night == true` or `phase == "night"`

### Step 4: Night Typing

```gdscript
{
    "id": "night_typing",
    "title": "Defend by typing",
    "body_lines": [
        "Each enemy has a word. Type the word to attack that enemy.",
        "Prefixes are safe; Enter only submits on a full match.",
        "Commands like status still work at night."
    ],
    "try_line": "Try this: Type an enemy word from the wave list, then press Enter.",
    "success_line": "Success: The targeted enemy loses HP and the wave list updates."
}
```

Completes when: `hit_enemy == true`

### Step 5: Reach Dawn

```gdscript
{
    "id": "reach_dawn",
    "title": "Reach dawn",
    "body_lines": [
        "Keep typing enemy words until the wave is cleared.",
        "If you need a pause, use wait to advance without a penalty.",
        "Dawn returns you to the day phase."
    ],
    "try_line": "Try this: Defeat enemies until Dawn (or use wait if needed).",
    "success_line": "Success: Dawn is announced and the typing report appears."
}
```

Completes when: `reached_dawn == true` or `phase == "day"`

### Step 6: Wrap Up

```gdscript
{
    "id": "wrap_up",
    "title": "Panels and replay",
    "body_lines": [
        "Lessons and settings are available any time.",
        "The tutorial can be replayed if you want a refresher.",
        "You can switch goals and lessons as you improve."
    ],
    "try_line": "Try this: lessons, settings, tutorial",
    "success_line": "Success: Panels open and the tutorial controls are shown."
}
```

Completes when: `opened_lessons && opened_settings && toggled_tutorial`

## Snapshot Contract

The game layer provides a snapshot dictionary to track progress:

```gdscript
# Expected snapshot fields from game/main.gd:
{
    "used_help_or_status": bool,   # Player used help or status
    "did_gather": bool,            # Player gathered resources
    "did_build": bool,             # Player built something
    "did_explore": bool,           # Player explored a tile
    "entered_night": bool,         # Night phase was entered
    "hit_enemy": bool,             # Player damaged an enemy
    "reached_dawn": bool,          # Player survived to dawn
    "opened_lessons": bool,        # Lessons panel was opened
    "opened_settings": bool,       # Settings panel was opened
    "toggled_tutorial": bool,      # Tutorial was toggled

    # Optional enrichment fields:
    "phase": String,               # Current phase ("day", "night")
    "buildings_total": int,        # Total buildings placed
    "explored_count": int          # Tiles discovered
}
```

## API Reference

### Getting Step Information

```gdscript
# Get all steps
var steps: Array = OnboardingFlow.steps()

# Get step count
var count: int = OnboardingFlow.step_count()

# Clamp step to valid range
var valid: int = OnboardingFlow.clamp_step(step)
```

### Formatting Step Display

```gdscript
# game/onboarding_flow.gd:98
static func format_step(step: int) -> String:
    var total: int = step_count()
    var lines: Array[String] = []
    lines.append("[b]Tutorial[/b]")

    if total == 0:
        lines.append("No tutorial steps configured.")
        return "\n".join(lines)

    var clamped: int = clamp_step(step)
    if clamped >= total:
        lines.append("Status: COMPLETE")
        lines.append("Use 'tutorial restart' to replay.")
        lines.append("Commands: tutorial | tutorial restart | tutorial skip")
        return "\n".join(lines)

    var entry: Dictionary = STEPS[clamped]
    lines.append("Step %d/%d" % [clamped + 1, total])
    lines.append("[b]%s[/b]" % str(entry.get("title", "Step")))

    var body_lines: Array = entry.get("body_lines", [])
    for line in body_lines:
        lines.append(str(line))

    var try_line: String = str(entry.get("try_line", ""))
    if try_line != "":
        lines.append(try_line)

    var success_line: String = str(entry.get("success_line", ""))
    if success_line != "":
        lines.append(success_line)

    lines.append("Commands: tutorial | tutorial restart | tutorial skip")
    return "\n".join(lines)
```

### Checking Step Completion

```gdscript
# game/onboarding_flow.gd:126
static func is_step_complete(step: int, snapshot: Dictionary) -> bool:
    var phase: String = str(snapshot.get("phase", ""))
    match step:
        0:
            return bool(snapshot.get("used_help_or_status", false))
        1:
            var built: bool = bool(snapshot.get("did_build", false))
            var explored: bool = bool(snapshot.get("did_explore", false))
            var gathered: bool = bool(snapshot.get("did_gather", false))
            if not built:
                built = int(snapshot.get("buildings_total", 0)) > 0
            if not explored:
                explored = int(snapshot.get("explored_count", 0)) > 1
            return built and explored and gathered
        2:
            return bool(snapshot.get("entered_night", false)) or phase == "night"
        3:
            return bool(snapshot.get("hit_enemy", false))
        4:
            return bool(snapshot.get("reached_dawn", false)) or phase == "day"
        5:
            return bool(snapshot.get("opened_lessons", false)) \
                and bool(snapshot.get("opened_settings", false)) \
                and bool(snapshot.get("toggled_tutorial", false))
    return false
```

### Advancing Steps

```gdscript
# game/onboarding_flow.gd:152
static func advance(step: int, snapshot: Dictionary) -> int:
    var clamped: int = clamp_step(step)
    var total: int = step_count()
    if clamped >= total:
        return total
    if is_step_complete(clamped, snapshot):
        return clamped + 1
    return clamped
```

## Integration Example

### Main Game Integration

```gdscript
# game/main.gd
var tutorial_step: int = 0
var tutorial_snapshot: Dictionary = {}

func _ready() -> void:
    _reset_tutorial_snapshot()

func _reset_tutorial_snapshot() -> void:
    tutorial_snapshot = {
        "used_help_or_status": false,
        "did_gather": false,
        "did_build": false,
        "did_explore": false,
        "entered_night": false,
        "hit_enemy": false,
        "reached_dawn": false,
        "opened_lessons": false,
        "opened_settings": false,
        "toggled_tutorial": false,
        "phase": "day",
        "buildings_total": 0,
        "explored_count": 1
    }

func _on_command_executed(command: String, result: Dictionary) -> void:
    # Update snapshot based on command
    match command:
        "help", "status":
            tutorial_snapshot.used_help_or_status = true
        "gather":
            tutorial_snapshot.did_gather = true
        "build":
            tutorial_snapshot.did_build = true
            tutorial_snapshot.buildings_total += 1
        "explore":
            tutorial_snapshot.did_explore = true
            tutorial_snapshot.explored_count += 1

    _check_tutorial_advance()

func _on_phase_changed(new_phase: String) -> void:
    tutorial_snapshot.phase = new_phase
    if new_phase == "night":
        tutorial_snapshot.entered_night = true
    elif new_phase == "day" and tutorial_snapshot.entered_night:
        tutorial_snapshot.reached_dawn = true
    _check_tutorial_advance()

func _on_enemy_hit() -> void:
    tutorial_snapshot.hit_enemy = true
    _check_tutorial_advance()

func _on_panel_opened(panel: String) -> void:
    match panel:
        "lessons":
            tutorial_snapshot.opened_lessons = true
        "settings":
            tutorial_snapshot.opened_settings = true
        "tutorial":
            tutorial_snapshot.toggled_tutorial = true
    _check_tutorial_advance()

func _check_tutorial_advance() -> void:
    var new_step: int = OnboardingFlow.advance(tutorial_step, tutorial_snapshot)
    if new_step != tutorial_step:
        tutorial_step = new_step
        _show_tutorial_step(tutorial_step)

func _show_tutorial_step(step: int) -> void:
    var text: String = OnboardingFlow.format_step(step)
    tutorial_panel.text = text
```

### Tutorial Commands

```gdscript
# Parse tutorial command
"tutorial":
    if tokens.size() > 1:
        match tokens[1]:
            "restart":
                return SimIntents.make("tutorial", {"action": "restart"})
            "skip":
                return SimIntents.make("tutorial", {"action": "skip"})
    return SimIntents.make("tutorial", {"action": "show"})

# Apply tutorial intent
"tutorial":
    var action: String = str(intent.get("action", "show"))
    match action:
        "restart":
            tutorial_step = 0
            _reset_tutorial_snapshot()
            events.append("Tutorial restarted from step 1.")
        "skip":
            tutorial_step = OnboardingFlow.step_count()
            events.append("Tutorial skipped.")
        "show":
            events.append(OnboardingFlow.format_step(tutorial_step))
```

## First-Time Detection

```gdscript
# Check if player is new
func is_first_time_player() -> bool:
    var profile := TypingProfile.load_or_create()
    return profile.get("games_played", 0) == 0

func _ready() -> void:
    if is_first_time_player():
        tutorial_step = 0
        _show_tutorial_step(0)
    else:
        tutorial_step = OnboardingFlow.step_count()  # Skip
```

## Persistence

```gdscript
# Save tutorial progress
func save_tutorial_progress() -> void:
    var profile := TypingProfile.load_or_create()
    profile["tutorial_step"] = tutorial_step
    profile["tutorial_complete"] = tutorial_step >= OnboardingFlow.step_count()
    TypingProfile.save(profile)

# Load tutorial progress
func load_tutorial_progress() -> void:
    var profile := TypingProfile.load_or_create()
    tutorial_step = int(profile.get("tutorial_step", 0))
```

## Audio Integration

```gdscript
func _on_tutorial_step_complete(step: int) -> void:
    AudioManager.play_sfx(AudioManager.SFX.TUTORIAL_DING)

func _on_tutorial_complete() -> void:
    AudioManager.play_sfx(AudioManager.SFX.ACHIEVEMENT_UNLOCK)
```

## Testing

```gdscript
func test_tutorial_step_completion():
    var snapshot := {
        "used_help_or_status": true
    }
    assert(OnboardingFlow.is_step_complete(0, snapshot))
    assert(not OnboardingFlow.is_step_complete(1, snapshot))
    _pass("test_tutorial_step_completion")

func test_tutorial_advance():
    var snapshot := {
        "used_help_or_status": true,
        "did_gather": true,
        "did_build": true,
        "did_explore": true
    }

    var step := OnboardingFlow.advance(0, snapshot)
    assert(step == 1, "Should advance past step 0")

    step = OnboardingFlow.advance(1, snapshot)
    assert(step == 2, "Should advance past step 1")

    _pass("test_tutorial_advance")

func test_tutorial_format():
    var text := OnboardingFlow.format_step(0)
    assert("[b]Tutorial[/b]" in text)
    assert("Welcome" in text)
    _pass("test_tutorial_format")
```

## Design Principles

1. **Typing-First** - All interactions through keyboard commands
2. **Progressive Disclosure** - One concept per step
3. **Immediate Feedback** - Success/failure is visible
4. **Skippable** - Experienced players can skip
5. **Replayable** - Tutorial can be restarted anytime
6. **Non-Blocking** - Game continues to work normally
