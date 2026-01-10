#!/usr/bin/env python3
"""
Data Migration Helper

Helps manage data file schema migrations:
- Detect schema version changes
- Generate migration scripts
- Apply migrations to data files
- Validate migration results

Usage:
    python scripts/migrate_data.py --check              # Check for needed migrations
    python scripts/migrate_data.py --generate lessons   # Generate migration for file
    python scripts/migrate_data.py --apply lessons      # Apply pending migrations
    python scripts/migrate_data.py --history            # Show migration history
    python scripts/migrate_data.py --rollback lessons   # Rollback last migration
"""

import json
import os
import re
import shutil
import sys
from datetime import datetime
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional, Any, Callable

# Project paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent
DATA_DIR = PROJECT_ROOT / "data"
MIGRATIONS_DIR = PROJECT_ROOT / "data" / "migrations"
BACKUP_DIR = PROJECT_ROOT / "data" / "backups"


@dataclass
class Migration:
    """Represents a data migration."""
    id: str
    file: str
    from_version: int
    to_version: int
    description: str
    created_at: str
    applied_at: Optional[str] = None
    changes: List[Dict[str, Any]] = field(default_factory=list)


def format_version(v: tuple) -> str:
    """Format version tuple as string."""
    return ".".join(str(x) for x in v)


@dataclass
class MigrationStatus:
    """Status of migrations for a file."""
    file: str
    current_version: str
    schema_version: str
    needs_migration: bool = False
    pending_migrations: List[str] = field(default_factory=list)
    applied_migrations: List[str] = field(default_factory=list)


def ensure_dirs():
    """Ensure migration and backup directories exist."""
    MIGRATIONS_DIR.mkdir(parents=True, exist_ok=True)
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)


def get_data_files() -> List[Path]:
    """Get all JSON data files."""
    files = []
    for json_file in DATA_DIR.glob("*.json"):
        if json_file.name != "migrations.json":
            files.append(json_file)
    return files


def parse_version(version) -> tuple:
    """Parse version string or int into comparable tuple."""
    if isinstance(version, int):
        return (version, 0, 0)
    if isinstance(version, str):
        # Handle "1.0.0" style versions
        parts = version.split(".")
        try:
            return tuple(int(p) for p in parts[:3]) + (0,) * (3 - len(parts))
        except ValueError:
            return (1, 0, 0)
    return (1, 0, 0)


def get_file_version(filepath: Path) -> tuple:
    """Get version from a data file."""
    try:
        data = json.loads(filepath.read_text(encoding="utf-8"))
        return parse_version(data.get("version", 1))
    except Exception:
        return (1, 0, 0)


def get_schema_version(filepath: Path) -> tuple:
    """Get expected version from schema file."""
    schema_name = filepath.stem + ".schema.json"
    schema_path = DATA_DIR / "schemas" / schema_name

    if not schema_path.exists():
        return (1, 0, 0)

    try:
        schema = json.loads(schema_path.read_text(encoding="utf-8"))
        # Look for version in properties
        props = schema.get("properties", {})
        version_prop = props.get("version", {})
        if "const" in version_prop:
            return parse_version(version_prop["const"])
        if "minimum" in version_prop:
            return parse_version(version_prop["minimum"])
        return (1, 0, 0)
    except Exception:
        return (1, 0, 0)


def load_migration_history() -> Dict[str, List[Migration]]:
    """Load migration history."""
    history_file = MIGRATIONS_DIR / "history.json"
    if not history_file.exists():
        return {}

    try:
        data = json.loads(history_file.read_text(encoding="utf-8"))
        history = {}
        for file_name, migrations in data.items():
            history[file_name] = [
                Migration(**m) for m in migrations
            ]
        return history
    except Exception:
        return {}


def save_migration_history(history: Dict[str, List[Migration]]):
    """Save migration history."""
    ensure_dirs()
    data = {}
    for file_name, migrations in history.items():
        data[file_name] = [
            {
                "id": m.id,
                "file": m.file,
                "from_version": m.from_version,
                "to_version": m.to_version,
                "description": m.description,
                "created_at": m.created_at,
                "applied_at": m.applied_at,
                "changes": m.changes,
            }
            for m in migrations
        ]

    history_file = MIGRATIONS_DIR / "history.json"
    history_file.write_text(json.dumps(data, indent=2), encoding="utf-8")


def check_migrations() -> List[MigrationStatus]:
    """Check all files for needed migrations."""
    statuses = []

    for filepath in get_data_files():
        current = get_file_version(filepath)
        schema = get_schema_version(filepath)

        needs_migration = current < schema

        status = MigrationStatus(
            file=filepath.name,
            current_version=format_version(current),
            schema_version=format_version(schema),
            needs_migration=needs_migration,
        )

        if needs_migration:
            # Generate pending migration ID
            status.pending_migrations.append(
                f"{filepath.stem}_v{format_version(current)}_to_v{format_version(schema)}"
            )

        # Load applied migrations
        history = load_migration_history()
        if filepath.name in history:
            status.applied_migrations = [m.id for m in history[filepath.name]]

        statuses.append(status)

    return statuses


def create_backup(filepath: Path) -> Path:
    """Create backup of a data file."""
    ensure_dirs()
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_name = f"{filepath.stem}_{timestamp}.json"
    backup_path = BACKUP_DIR / backup_name
    shutil.copy(filepath, backup_path)
    return backup_path


def generate_migration(file_name: str) -> Optional[Migration]:
    """Generate a migration script for a file."""
    filepath = DATA_DIR / file_name
    if not filepath.suffix:
        filepath = filepath.with_suffix(".json")

    if not filepath.exists():
        print(f"File not found: {filepath}")
        return None

    current = get_file_version(filepath)
    schema = get_schema_version(filepath)

    if current >= schema:
        print(f"No migration needed for {file_name} (v{current} >= v{schema})")
        return None

    # Generate migration
    migration_id = f"{filepath.stem}_v{current}_to_v{current+1}"
    timestamp = datetime.now().isoformat()

    migration = Migration(
        id=migration_id,
        file=filepath.name,
        from_version=current,
        to_version=current + 1,
        description=f"Migrate {filepath.name} from v{current} to v{current+1}",
        created_at=timestamp,
        changes=[],
    )

    # Analyze what changes might be needed based on schema diff
    schema_path = DATA_DIR / "schemas" / f"{filepath.stem}.schema.json"
    if schema_path.exists():
        try:
            schema = json.loads(schema_path.read_text(encoding="utf-8"))
            data = json.loads(filepath.read_text(encoding="utf-8"))

            # Check for new required fields
            required = schema.get("required", [])
            props = schema.get("properties", {})

            for field in required:
                if field not in data and field != "version":
                    default = get_default_value(props.get(field, {}))
                    migration.changes.append({
                        "type": "add_field",
                        "field": field,
                        "default": default,
                    })

            # Check for new properties in entries
            if "entries" in props:
                entry_schema = props["entries"]
                if "additionalProperties" in entry_schema:
                    entry_props = entry_schema["additionalProperties"].get("properties", {})
                    entry_required = entry_schema["additionalProperties"].get("required", [])

                    entries = data.get("entries", {})
                    if entries:
                        sample_entry = next(iter(entries.values()))
                        for field in entry_required:
                            if field not in sample_entry:
                                default = get_default_value(entry_props.get(field, {}))
                                migration.changes.append({
                                    "type": "add_entry_field",
                                    "field": field,
                                    "default": default,
                                })

        except Exception as e:
            print(f"Warning: Could not analyze schema: {e}")

    # Always add version bump
    migration.changes.append({
        "type": "set_version",
        "version": current + 1,
    })

    # Save migration script
    ensure_dirs()
    migration_file = MIGRATIONS_DIR / f"{migration_id}.json"
    migration_data = {
        "id": migration.id,
        "file": migration.file,
        "from_version": migration.from_version,
        "to_version": migration.to_version,
        "description": migration.description,
        "created_at": migration.created_at,
        "changes": migration.changes,
    }
    migration_file.write_text(json.dumps(migration_data, indent=2), encoding="utf-8")

    return migration


def get_default_value(prop_schema: Dict) -> Any:
    """Get default value for a schema property."""
    if "default" in prop_schema:
        return prop_schema["default"]

    prop_type = prop_schema.get("type", "string")
    if prop_type == "string":
        return ""
    elif prop_type == "number" or prop_type == "integer":
        return 0
    elif prop_type == "boolean":
        return False
    elif prop_type == "array":
        return []
    elif prop_type == "object":
        return {}
    return None


def apply_migration(file_name: str, dry_run: bool = False) -> bool:
    """Apply pending migrations to a file."""
    filepath = DATA_DIR / file_name
    if not filepath.suffix:
        filepath = filepath.with_suffix(".json")

    if not filepath.exists():
        print(f"File not found: {filepath}")
        return False

    current = get_file_version(filepath)
    schema = get_schema_version(filepath)

    if current >= schema:
        print(f"No migration needed for {file_name}")
        return True

    # Find migration script
    migration_id = f"{filepath.stem}_v{current}_to_v{current+1}"
    migration_file = MIGRATIONS_DIR / f"{migration_id}.json"

    if not migration_file.exists():
        print(f"Migration script not found: {migration_id}")
        print(f"Run: python scripts/migrate_data.py --generate {file_name}")
        return False

    # Load migration
    migration_data = json.loads(migration_file.read_text(encoding="utf-8"))

    # Load data
    data = json.loads(filepath.read_text(encoding="utf-8"))

    print(f"Applying migration: {migration_id}")
    if dry_run:
        print("  [DRY RUN - no changes will be made]")

    # Apply changes
    for change in migration_data.get("changes", []):
        change_type = change.get("type")

        if change_type == "set_version":
            new_version = change.get("version")
            print(f"  - Setting version to {new_version}")
            if not dry_run:
                data["version"] = new_version

        elif change_type == "add_field":
            field = change.get("field")
            default = change.get("default")
            print(f"  - Adding field '{field}' with default: {default}")
            if not dry_run and field not in data:
                data[field] = default

        elif change_type == "add_entry_field":
            field = change.get("field")
            default = change.get("default")
            print(f"  - Adding field '{field}' to all entries with default: {default}")
            if not dry_run:
                entries = data.get("entries", {})
                for entry_id, entry in entries.items():
                    if field not in entry:
                        entry[field] = default

        elif change_type == "rename_field":
            old_name = change.get("old_name")
            new_name = change.get("new_name")
            print(f"  - Renaming field '{old_name}' to '{new_name}'")
            if not dry_run and old_name in data:
                data[new_name] = data.pop(old_name)

        elif change_type == "remove_field":
            field = change.get("field")
            print(f"  - Removing field '{field}'")
            if not dry_run and field in data:
                del data[field]

        elif change_type == "transform":
            # Custom transformation (logged but not executed)
            print(f"  - Custom transform: {change.get('description', 'unknown')}")

    if not dry_run:
        # Create backup
        backup = create_backup(filepath)
        print(f"  Backup created: {backup.name}")

        # Write updated data
        filepath.write_text(json.dumps(data, indent=2), encoding="utf-8")
        print(f"  Migration applied successfully")

        # Update history
        history = load_migration_history()
        if filepath.name not in history:
            history[filepath.name] = []

        history[filepath.name].append(Migration(
            id=migration_id,
            file=filepath.name,
            from_version=migration_data["from_version"],
            to_version=migration_data["to_version"],
            description=migration_data["description"],
            created_at=migration_data["created_at"],
            applied_at=datetime.now().isoformat(),
            changes=migration_data["changes"],
        ))
        save_migration_history(history)

    return True


def rollback_migration(file_name: str) -> bool:
    """Rollback the last migration for a file."""
    filepath = DATA_DIR / file_name
    if not filepath.suffix:
        filepath = filepath.with_suffix(".json")

    # Find most recent backup
    backups = sorted(BACKUP_DIR.glob(f"{filepath.stem}_*.json"), reverse=True)
    if not backups:
        print(f"No backups found for {file_name}")
        return False

    latest_backup = backups[0]
    print(f"Restoring from backup: {latest_backup.name}")

    # Restore backup
    shutil.copy(latest_backup, filepath)
    print(f"Rollback complete")

    return True


def show_history():
    """Show migration history."""
    history = load_migration_history()

    if not history:
        print("No migration history found.")
        return

    print("=" * 60)
    print("MIGRATION HISTORY")
    print("=" * 60)

    for file_name, migrations in sorted(history.items()):
        print(f"\n## {file_name}")
        for m in migrations:
            status = "APPLIED" if m.applied_at else "PENDING"
            print(f"  [{status}] {m.id}")
            print(f"    {m.description}")
            if m.applied_at:
                print(f"    Applied: {m.applied_at}")


def format_check_report(statuses: List[MigrationStatus]) -> str:
    """Format migration check report."""
    lines = []
    lines.append("=" * 60)
    lines.append("MIGRATION STATUS CHECK")
    lines.append("=" * 60)
    lines.append("")

    needs_migration = []
    up_to_date = []

    for status in statuses:
        if status.needs_migration:
            needs_migration.append(status)
        else:
            up_to_date.append(status)

    if needs_migration:
        lines.append("## FILES NEEDING MIGRATION")
        for status in needs_migration:
            lines.append(f"  {status.file}: v{status.current_version} → v{status.schema_version}")
            for pending in status.pending_migrations:
                lines.append(f"    - {pending}")
        lines.append("")

    if up_to_date:
        lines.append("## UP TO DATE")
        for status in up_to_date:
            lines.append(f"  {status.file}: v{status.current_version}")
        lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Total files: {len(statuses)}")
    lines.append(f"  Need migration: {len(needs_migration)}")
    lines.append(f"  Up to date: {len(up_to_date)}")

    return "\n".join(lines)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Data migration helper")
    parser.add_argument("--check", "-c", action="store_true", help="Check for needed migrations")
    parser.add_argument("--generate", "-g", type=str, metavar="FILE", help="Generate migration for file")
    parser.add_argument("--apply", "-a", type=str, metavar="FILE", help="Apply pending migrations")
    parser.add_argument("--dry-run", action="store_true", help="Show what would be done without applying")
    parser.add_argument("--rollback", "-r", type=str, metavar="FILE", help="Rollback last migration")
    parser.add_argument("--history", action="store_true", help="Show migration history")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    args = parser.parse_args()

    if args.check or (not args.generate and not args.apply and not args.rollback and not args.history):
        statuses = check_migrations()
        if args.json:
            data = [
                {
                    "file": s.file,
                    "current_version": s.current_version,
                    "schema_version": s.schema_version,
                    "pending_migrations": s.pending_migrations,
                    "applied_migrations": s.applied_migrations,
                }
                for s in statuses
            ]
            print(json.dumps(data, indent=2))
        else:
            print(format_check_report(statuses))

    elif args.generate:
        migration = generate_migration(args.generate)
        if migration:
            print(f"Generated migration: {migration.id}")
            print(f"Changes to apply:")
            for change in migration.changes:
                print(f"  - {change['type']}: {change}")

    elif args.apply:
        apply_migration(args.apply, args.dry_run)

    elif args.rollback:
        rollback_migration(args.rollback)

    elif args.history:
        show_history()


if __name__ == "__main__":
    main()
