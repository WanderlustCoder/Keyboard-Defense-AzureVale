# Taunt Catalog

Episode 1 enemies, elites, and affix variants share a single JSON catalog so
new lore lines stay consistent across the HUD, analytics, and dashboards.

## File Layout

- `catalog.json` – canonical list of taunt entries.

Each entry follows:

```json
{
  "id": "boss_archivist_intro",
  "enemyType": "archivist",
  "rarity": "boss",
  "text": "Archivist Lyra snaps her quill…",
  "tags": ["episode1", "archivist", "phase1"],
  "voiceLineId": "vo.archivist.intro"
}
```

| Field        | Description                                                                    |
| ------------ | ------------------------------------------------------------------------------ |
| `id`         | Stable identifier used by analytics/tests and `tauntId` in wave configs.       |
| `enemyType`  | Tier or special enemy slug (`archivist`, `vanguard`, etc.).                    |
| `rarity`     | `"boss"`, `"elite"`, or `"affix"` – used for linting & dashboards.             |
| `text`       | Player-facing string shown in the HUD/logs.                                    |
| `tags`       | Must include `episode1` plus any lore/affix metadata (e.g., `frost`, `shield`).|
| `voiceLineId`| Optional VO hook for future localization/VO passes.                            |

## Validation

Run `npm run taunts:validate` (or `node scripts/taunts/validateCatalog.mjs`) to
ensure:

- IDs/text are unique.
- Required fields/tags are present.
- Entries map to known rarities.

The CLI exits non-zero when validation fails and prints readable warnings so CI
can catch catalog drift automatically.
