# Windows Export (Phase 3)

Prerequisites:
- Godot 4.2.2 installed.
- Godot export templates installed for Windows Desktop.
- Run commands from the repo root or the project root (`apps/keyboard-defense-godot/`).

Repo root wrappers (recommended):
- Dry-run: `powershell -ExecutionPolicy Bypass -File .\scripts\export_windows.ps1`
- Dry-run: `bash ./scripts/export_windows.sh`
- Apply: `powershell -ExecutionPolicy Bypass -File .\scripts\export_windows.ps1 apply`
- Apply: `bash ./scripts/export_windows.sh apply`
- Package: `powershell -ExecutionPolicy Bypass -File .\scripts\export_windows.ps1 package`
- Package: `bash ./scripts/export_windows.sh package`
- Package (versioned): `powershell -ExecutionPolicy Bypass -File .\scripts\export_windows.ps1 package versioned`
- Package (versioned): `bash ./scripts/export_windows.sh package versioned`
- Apply + package: `powershell -ExecutionPolicy Bypass -File .\scripts\export_windows.ps1 apply package`
- Apply + package: `bash ./scripts/export_windows.sh apply package`
- Apply + package (versioned): `powershell -ExecutionPolicy Bypass -File .\scripts\export_windows.ps1 apply package versioned`
- Apply + package (versioned): `bash ./scripts/export_windows.sh apply package versioned`

Project root (direct scripts):
- Dry-run: `powershell -ExecutionPolicy Bypass -File ./scripts/export_windows.ps1`
- Dry-run: `bash ./scripts/export_windows.sh`
- Apply: `powershell -ExecutionPolicy Bypass -File ./scripts/export_windows.ps1 apply`
- Apply: `bash ./scripts/export_windows.sh apply`
- Package: `powershell -ExecutionPolicy Bypass -File ./scripts/export_windows.ps1 package`
- Package: `bash ./scripts/export_windows.sh package`
- Package (versioned): `powershell -ExecutionPolicy Bypass -File ./scripts/export_windows.ps1 package versioned`
- Package (versioned): `bash ./scripts/export_windows.sh package versioned`
- Apply + package: `powershell -ExecutionPolicy Bypass -File ./scripts/export_windows.ps1 apply package`
- Apply + package: `bash ./scripts/export_windows.sh apply package`
- Apply + package (versioned): `powershell -ExecutionPolicy Bypass -File ./scripts/export_windows.ps1 apply package versioned`
- Apply + package (versioned): `bash ./scripts/export_windows.sh apply package versioned`

Output:
- `build/windows/KeyboardDefense.exe`
- `build/windows/KeyboardDefense.pck` (when `embed_pck` is false)
- `build/windows/KeyboardDefense-win64.zip`
- `build/windows/KeyboardDefense-<product_version>-win64.zip` (when using `versioned`)
- `build/windows/export_manifest.json` (included in zips as `export_manifest.json`)

Bumping versions:
- Dry-run plan: `powershell -ExecutionPolicy Bypass -File .\scripts\bump_version.ps1 set 1.0.1`
- Dry-run plan: `bash ./scripts/bump_version.sh set 1.0.1`
- Apply: `powershell -ExecutionPolicy Bypass -File .\scripts\bump_version.ps1 apply 1.0.1`
- Apply: `bash ./scripts/bump_version.sh apply 1.0.1`
- Patch dry-run: `powershell -ExecutionPolicy Bypass -File .\scripts\bump_version.ps1 patch`
- Patch apply: `powershell -ExecutionPolicy Bypass -File .\scripts\bump_version.ps1 apply patch`
- Minor dry-run: `powershell -ExecutionPolicy Bypass -File .\scripts\bump_version.ps1 minor`
- Minor apply: `powershell -ExecutionPolicy Bypass -File .\scripts\bump_version.ps1 apply minor`
- Major dry-run: `powershell -ExecutionPolicy Bypass -File .\scripts\bump_version.ps1 major`
- Major apply: `powershell -ExecutionPolicy Bypass -File .\scripts\bump_version.ps1 apply major`
- Patch dry-run: `bash ./scripts/bump_version.sh patch`
- Patch apply: `bash ./scripts/bump_version.sh apply patch`
- Minor dry-run: `bash ./scripts/bump_version.sh minor`
- Minor apply: `bash ./scripts/bump_version.sh apply minor`
- Major dry-run: `bash ./scripts/bump_version.sh major`
- Major apply: `bash ./scripts/bump_version.sh apply major`

Notes:
- Set `GODOT_BIN` to override the Godot executable path.
- Preset used: `Windows Desktop`.
- Versioned zips use `application/product_version` from `export_presets.cfg` (fallback `0.0.0`).
- VERSION.txt is the version source of truth; scripts warn in dry-run and error in apply/package when it differs from the preset product_version.
- Version consistency additions:
- bump_version updates product_version for every preset options section.
- bump_version updates file_version for every preset options section.
- bump_version treats VERSION.txt as the source of truth.
- bump_version plan output lists VERSION.txt first.
- bump_version plan output lists presets in ascending preset index order.
- bump_version plan output uses one line per preset: product + file.
- bump_version validates product_version exists in each options section.
- bump_version validates file_version exists in each options section.
- bump_version stops with an error if a preset options block is missing keys.
- bump_version does not depend on preset names for updates.
- bump_version updates apply to all export presets, not just Windows.
- bump_version keeps exports deterministic by updating only version keys.
- bump_version avoids partial updates by validating before apply.
- bump_version applies the same target version to product_version.
- bump_version applies the same target version to file_version.
- bump_version output remains concise and deterministic.
- bump_version still writes VERSION.txt with a single-line version.
- export scripts now read preset file_version from export_presets.cfg.
- export scripts print "Preset file_version:" in all modes.
- export scripts warn on preset file_version mismatch in dry-run.
- export scripts error on preset file_version mismatch in apply/package.
- export scripts warn when VERSION.txt differs from preset file_version.
- export scripts error when VERSION.txt differs from preset file_version.
- export scripts still warn on VERSION.txt vs preset product_version.
- export scripts still error on VERSION.txt vs preset product_version.
- export scripts keep product_version as the zip version source.
- export scripts validate file_version equals product_version.
- export scripts validate VERSION.txt equals file_version.
- export scripts checks run before any export or packaging.
- export scripts keep dry-run output deterministic and complete.
- export scripts keep apply/package fail-fast on version mismatches.
- export scripts keep existing product_version warning text unchanged.
- export scripts avoid Godot dependency for parsing/version checks.
- export scripts use preset values even when defaults are used.
- export scripts keep VERSION.txt as the single source of truth.
