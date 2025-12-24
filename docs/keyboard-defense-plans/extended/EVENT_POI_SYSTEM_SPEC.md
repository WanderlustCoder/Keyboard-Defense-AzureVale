# Event and POI System Specification

Goal: a moddable, deterministic event system that feeds exploration and day
planning while reinforcing typing practice.

## LANDMARK: Requirements
- Deterministic: seed + run state -> same event offers.
- Data-first: events in `apps/keyboard-defense-godot/data/events/`.
- POIs in `apps/keyboard-defense-godot/data/pois/`.
- Localizable: text keys or inline text with optional localization pass.
- Pedagogy tags: tier, letters, bigrams, punctuation.
- Mechanical outcomes: gold, buffs, damage, unlocks, new POIs.
- Typing-first choices: player types an option code or phrase (configurable).

## Conceptual model
- A POI (Point of Interest) exists on the world map.
- Interacting with a POI triggers one or more events.
- Each event may present:
  - narration
  - 1 to 4 choices
  - optional typing challenge prompts
  - deterministic resolution with effects

## Core structures

### POI
Fields:
- `id` (string)
- `biome` (enum)
- `name` (string)
- `icon` (string asset key)
- `event_table_id` (string)
- `rarity` (number 1..100)
- `tags` (string[])
- `min_day`, `max_day` (optional)

### EventTable
An EventTable selects events using weighted rolls and run context filters.
Fields:
- `id`
- `entries[]`: { `event_id`, `weight`, `conditions?` }

Conditions can check:
- day number
- biome
- resources or gold
- building or upgrade counts
- meta unlock flags
- player typing skill bracket (derived, not stored)

### Event
Fields:
- `id`
- `title`
- `body` (string)
- `tier` (0..5)
- `tags` (string[])
- `choices[]`
- `cooldown_days` (optional, to avoid repeats)

### Choice
Fields:
- `id` (short code, e.g. "A", "B", "C")
- `label` (string displayed)
- `input` (typing input type; see below)
- `effects[]` (applied if passed)
- `fail_effects[]` (applied if failed, optional)
- `next_event_id` (branching)

### Typing input types
Support multiple, selectable by accessibility settings:
- `code`: player types the choice id (A/B/C)
- `phrase`: player types a phrase (teaches spelling)
- `prompt_burst`: player types 1 to 3 short prompts
- `command`: player types a command string; parser validates

The same event can define multiple input modes so the game can switch modes
based on settings or difficulty.

## LANDMARK: Determinism rules
- Use a single seeded RNG stream for:
  - POI spawn
  - event selection
  - reward variance
- Store RNG state or store seed plus step count.
- Effects must be pure functions of (state, RNG stream, choice result).

## Content authoring rules
- Avoid long bodies. Prefer 2 to 4 sentences.
- Use consistent resource tokens:
  - GOLD, TIMBER, STONE, INK (or your chosen set)
- Use placeholders for numbers: `{n}` `{resource}` for localization.

## Acceptance criteria
- Validator rejects events missing tier or tags.
- Validator rejects typing prompts longer than a configured cap (default 140).
- At least 20 POIs and 40 events in the base content pack (stubs allowed).
- The game can run with no events loaded by falling back to generated generic
  events for testing.
