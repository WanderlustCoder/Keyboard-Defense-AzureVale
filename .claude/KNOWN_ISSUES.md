# Known Issues and Gotchas

Things that aren't bugs but require awareness during development. Check this before implementing features that might hit these edge cases.

---

## Data Files

### Some JSON Files Lack Schemas
The following files don't have corresponding schemas in `data/schemas/`:
- `building_upgrades.json`
- `buildings.json`
- `research.json`
- `story.json`

These are validated for basic JSON syntax and structure only. Consider adding schemas when modifying these files significantly.

### JSON Version Numbers
All data files should have a `"version": N` field. Increment when schema changes to support migration. Some older files may be missing this.

---

## GDScript Patterns

### Typing Hints in Godot 4
Godot 4's type inference can be fragile. When in doubt, add explicit type hints:
```gdscript
# Prefer this
var enemies: Array[Dictionary] = []

# Over this (may cause issues)
var enemies = []
```

### Static Type Errors with Array Methods
`.filter()` and `.map()` on typed arrays sometimes produce untyped results. You may need explicit casts:
```gdscript
var filtered: Array[Dictionary] = []
for e in enemies:
    if e.hp > 0:
        filtered.append(e)
```

---

## Testing

### Headless Tests Require Display
Some tests that touch rendering may behave differently in headless mode. If a test passes in editor but fails headless, check for:
- Calls to `_draw()` without a canvas
- Accessing `get_viewport()` before node is in tree
- Timer-dependent behavior

### Test Runner Output Truncation
The test runner output can get long. Check the exit code, not just visible output, for pass/fail status.

---

## Platform Specific

### WSL Path Issues
When running from WSL, Windows paths may need conversion. The scripts use relative paths from project root to avoid this.

### Line Endings
Use LF line endings. Git should handle this, but watch for CRLF sneaking into scripts.

---

## Performance

### Large JSON Files
`assets_manifest.json` is ~7000 lines. Avoid loading it every frame. Cache results.

### Deep State Copying
`GameState.copy()` does a full deep copy. Avoid in hot paths. The intent system handles this appropriately.

---

<!-- Add new issues above this line using this format:

## Category

### Issue Name
Description of the issue and how to work around it.

-->
