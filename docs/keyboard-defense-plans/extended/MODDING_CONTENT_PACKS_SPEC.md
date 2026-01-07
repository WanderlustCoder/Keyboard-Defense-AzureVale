# Modding and Extensibility Spec (Content Packs)

Objective: enable new wordpacks, events, POIs, threat cards, and cosmetics
without touching code.

## LANDMARK: Non-goals
- No remote code execution.
- No arbitrary script mods.
- No workshop integration in MVP.

## Content pack format
A content pack is a folder or zip with:
- `pack.json` (manifest)
- `wordpacks/*.json`
- `events/*.json`
- `pois/*.json`
- `threats/*.json`
- optional `sprites/*.png` or `sprites/*.svg` (cosmetics only)
- optional `audio/*.wav` (cosmetics only)

## pack.json
```json
{
  "id": "community_pack_001",
  "name": "Community Pack 001",
  "version": "1.0.0",
  "author": "Example",
  "min_game_version": "0.1.0",
  "description": "Adds new POIs and a punctuation-heavy wordpack.",
  "dependencies": [],
  "content": {
    "wordpacks": ["wordpacks/punct.json"],
    "events": ["events/*.json"],
    "pois": ["pois/*.json"],
    "threats": ["threats/*.json"]
  }
}
```

## Validation
- All JSON files validated against schemas.
- IDs must be namespaced by pack id or use a prefix convention.
- Asset keys must be declared in the pack manifest (no implicit loads).

## Loading rules
- Base pack loads first from `apps/keyboard-defense-godot/data/`.
- User packs load next in deterministic order from `user://content_packs/`.
- Conflicts:
  - same ID: last pack wins, but emit a warning
  - missing schema: reject pack

## Safety
- Disallow file paths outside pack root.
- Disallow URLs.
- Treat audio and sprites as pure data assets.

## Acceptance criteria
- Player can enable or disable packs in settings (typing-first UI).
- Pack list shows validation errors with file and field path.
- The game remains playable with only the base pack.
