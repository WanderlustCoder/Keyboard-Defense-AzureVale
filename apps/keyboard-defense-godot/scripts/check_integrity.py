#!/usr/bin/env python3
"""
Data Integrity Checker

Goes beyond schema validation to check logical consistency:
- Reference integrity (all IDs exist)
- Upgrade chain validity
- Balance sanity checks
- Asset completeness
- Lesson progression validity

Usage:
    python scripts/check_integrity.py              # Run all checks
    python scripts/check_integrity.py --category upgrades
    python scripts/check_integrity.py --fix        # Attempt auto-fixes
    python scripts/check_integrity.py --json       # JSON output
"""

import json
import sys
from pathlib import Path
from typing import Dict, List, Any, Set, Optional, Tuple
from dataclasses import dataclass, field

# Project paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent
DATA_DIR = PROJECT_ROOT / "data"


@dataclass
class Issue:
    """Represents an integrity issue."""
    category: str
    severity: str  # "error", "warning", "info"
    message: str
    file: str = ""
    path: str = ""  # JSON path like "lessons[0].id"
    fix_hint: str = ""


@dataclass
class IntegrityReport:
    """Collection of integrity check results."""
    issues: List[Issue] = field(default_factory=list)

    def add(self, category: str, severity: str, message: str,
            file: str = "", path: str = "", fix_hint: str = "") -> None:
        self.issues.append(Issue(category, severity, message, file, path, fix_hint))

    def error(self, category: str, message: str, **kwargs) -> None:
        self.add(category, "error", message, **kwargs)

    def warning(self, category: str, message: str, **kwargs) -> None:
        self.add(category, "warning", message, **kwargs)

    def info(self, category: str, message: str, **kwargs) -> None:
        self.add(category, "info", message, **kwargs)

    @property
    def errors(self) -> List[Issue]:
        return [i for i in self.issues if i.severity == "error"]

    @property
    def warnings(self) -> List[Issue]:
        return [i for i in self.issues if i.severity == "warning"]

    @property
    def has_errors(self) -> bool:
        return len(self.errors) > 0


def load_json(filename: str) -> Optional[Dict[str, Any]]:
    """Load a JSON file from the data directory."""
    filepath = DATA_DIR / filename
    if not filepath.exists():
        return None
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            return json.load(f)
    except json.JSONDecodeError:
        return None


# ============================================================================
# LESSON CHECKS
# ============================================================================

def check_lessons(report: IntegrityReport) -> None:
    """Check lesson data integrity."""
    data = load_json("lessons.json")
    if not data:
        report.error("lessons", "lessons.json not found or invalid")
        return

    lessons = data.get("lessons", [])
    lesson_ids: Set[str] = set()
    graduation_paths = data.get("graduation_paths", {})

    # Check for duplicate IDs
    for i, lesson in enumerate(lessons):
        lesson_id = lesson.get("id", "")
        if not lesson_id:
            report.error("lessons", f"Lesson at index {i} has no ID",
                        file="lessons.json", path=f"lessons[{i}]")
            continue

        if lesson_id in lesson_ids:
            report.error("lessons", f"Duplicate lesson ID: {lesson_id}",
                        file="lessons.json", path=f"lessons[{i}].id",
                        fix_hint="Rename one of the duplicates")
        lesson_ids.add(lesson_id)

        # Check mode-specific requirements
        mode = lesson.get("mode", "")
        if mode == "charset" and not lesson.get("charset"):
            report.error("lessons", f"Charset lesson '{lesson_id}' missing 'charset' field",
                        file="lessons.json")
        elif mode == "wordlist" and not lesson.get("wordlist"):
            report.error("lessons", f"Wordlist lesson '{lesson_id}' missing 'wordlist' field",
                        file="lessons.json")
        elif mode == "sentence" and not lesson.get("sentences"):
            report.error("lessons", f"Sentence lesson '{lesson_id}' missing 'sentences' field",
                        file="lessons.json")

        # Check lengths format
        lengths = lesson.get("lengths", {})
        if lengths and mode != "sentence":
            for enemy_type in ["scout", "raider", "armored"]:
                if enemy_type in lengths:
                    length_range = lengths[enemy_type]
                    if not isinstance(length_range, list) or len(length_range) != 2:
                        report.warning("lessons",
                                      f"Lesson '{lesson_id}' has invalid length range for {enemy_type}",
                                      file="lessons.json")
                    elif length_range[0] > length_range[1]:
                        report.error("lessons",
                                    f"Lesson '{lesson_id}': min length > max length for {enemy_type}",
                                    file="lessons.json")

    # Check graduation paths reference valid lessons
    for path_id, path_data in graduation_paths.items():
        stages = path_data.get("stages", [])
        for stage in stages:
            for ref_lesson in stage.get("lessons", []):
                if ref_lesson not in lesson_ids:
                    report.error("lessons",
                                f"Graduation path '{path_id}' references non-existent lesson: {ref_lesson}",
                                file="lessons.json",
                                fix_hint=f"Add lesson '{ref_lesson}' or remove from path")


# ============================================================================
# UPGRADE CHECKS
# ============================================================================

def check_upgrades(report: IntegrityReport) -> None:
    """Check upgrade data integrity."""
    # Kingdom upgrades
    kingdom = load_json("kingdom_upgrades.json")
    if kingdom:
        _check_upgrade_file(report, kingdom, "kingdom_upgrades.json")

    # Unit upgrades
    unit = load_json("unit_upgrades.json")
    if unit:
        _check_upgrade_file(report, unit, "unit_upgrades.json")


def _check_upgrade_file(report: IntegrityReport, data: Dict, filename: str) -> None:
    """Check a single upgrade file."""
    upgrades = data.get("upgrades", [])
    upgrade_ids: Set[str] = set()

    # Collect all IDs first
    for upgrade in upgrades:
        upgrade_id = upgrade.get("id", "")
        if upgrade_id:
            upgrade_ids.add(upgrade_id)

    # Check each upgrade
    for i, upgrade in enumerate(upgrades):
        upgrade_id = upgrade.get("id", "")

        if not upgrade_id:
            report.error("upgrades", f"Upgrade at index {i} has no ID",
                        file=filename, path=f"upgrades[{i}]")
            continue

        # Check 'requires' references
        requires = upgrade.get("requires", [])
        if isinstance(requires, str):
            requires = [requires]

        for req_id in requires:
            if req_id and req_id not in upgrade_ids:
                report.error("upgrades",
                            f"Upgrade '{upgrade_id}' requires non-existent upgrade: {req_id}",
                            file=filename,
                            fix_hint=f"Add upgrade '{req_id}' or remove requirement")

        # Check cost sanity
        cost = upgrade.get("cost", {})
        if isinstance(cost, dict):
            for resource, amount in cost.items():
                if isinstance(amount, (int, float)) and amount < 0:
                    report.error("upgrades",
                                f"Upgrade '{upgrade_id}' has negative cost for {resource}",
                                file=filename)
                if isinstance(amount, (int, float)) and amount > 10000:
                    report.warning("upgrades",
                                  f"Upgrade '{upgrade_id}' has very high cost ({amount}) for {resource}",
                                  file=filename)

        # Check effects exist
        effects = upgrade.get("effects", {})
        if not effects:
            report.warning("upgrades",
                          f"Upgrade '{upgrade_id}' has no effects",
                          file=filename)


# ============================================================================
# BUILDING CHECKS
# ============================================================================

def check_buildings(report: IntegrityReport) -> None:
    """Check building data integrity."""
    data = load_json("buildings.json")
    if not data:
        report.info("buildings", "buildings.json not found (may be OK)")
        return

    buildings = data.get("buildings", data.get("entries", {}))
    if isinstance(buildings, dict):
        buildings = [{"id": k, **v} for k, v in buildings.items()]

    for building in buildings:
        building_id = building.get("id", building.get("name", "unknown"))

        # Check cost exists
        cost = building.get("cost", {})
        if not cost:
            report.warning("buildings",
                          f"Building '{building_id}' has no cost",
                          file="buildings.json")

        # Check for negative costs
        for resource, amount in cost.items():
            if isinstance(amount, (int, float)) and amount < 0:
                report.error("buildings",
                            f"Building '{building_id}' has negative cost for {resource}",
                            file="buildings.json")

        # Check production if present
        production = building.get("production", {})
        for resource, amount in production.items():
            if isinstance(amount, (int, float)) and amount < 0:
                report.warning("buildings",
                              f"Building '{building_id}' has negative production for {resource}",
                              file="buildings.json")


# ============================================================================
# ASSET MANIFEST CHECKS
# ============================================================================

def check_assets(report: IntegrityReport) -> None:
    """Check asset manifest integrity."""
    data = load_json("assets_manifest.json")
    if not data:
        report.error("assets", "assets_manifest.json not found or invalid")
        return

    textures = data.get("textures", [])
    texture_ids: Set[str] = set()

    for i, texture in enumerate(textures):
        texture_id = texture.get("id", "")

        if not texture_id:
            report.error("assets", f"Texture at index {i} has no ID",
                        file="assets_manifest.json", path=f"textures[{i}]")
            continue

        if texture_id in texture_ids:
            report.warning("assets", f"Duplicate texture ID: {texture_id}",
                          file="assets_manifest.json")
        texture_ids.add(texture_id)

        # Check path exists
        path = texture.get("path", "")
        if path:
            # Convert res:// path
            if path.startswith("res://"):
                file_path = PROJECT_ROOT / path[6:]
                if not file_path.exists():
                    # Check if source SVG exists
                    source_svg = texture.get("source_svg", "")
                    if source_svg:
                        svg_path = PROJECT_ROOT / source_svg[6:] if source_svg.startswith("res://") else None
                        if svg_path and svg_path.exists():
                            report.info("assets",
                                       f"Texture '{texture_id}' PNG missing but SVG exists",
                                       file="assets_manifest.json")
                        else:
                            report.warning("assets",
                                          f"Texture '{texture_id}' missing and no SVG source",
                                          file="assets_manifest.json")
                    else:
                        report.warning("assets",
                                      f"Texture '{texture_id}' file not found: {path}",
                                      file="assets_manifest.json")

        # Check dimensions
        width = texture.get("expected_width", 0)
        height = texture.get("expected_height", 0)
        if width <= 0 or height <= 0:
            report.warning("assets",
                          f"Texture '{texture_id}' has invalid dimensions: {width}x{height}",
                          file="assets_manifest.json")


# ============================================================================
# STORY CHECKS
# ============================================================================

def check_story(report: IntegrityReport) -> None:
    """Check story data integrity."""
    data = load_json("story.json")
    if not data:
        report.info("story", "story.json not found (may be OK)")
        return

    # Check dialogue IDs are unique
    dialogue = data.get("dialogue", {})
    if isinstance(dialogue, dict):
        for dialogue_id, content in dialogue.items():
            if not content.get("lines"):
                report.warning("story",
                              f"Dialogue '{dialogue_id}' has no lines",
                              file="story.json")

    # Check acts
    acts = data.get("acts", [])
    for i, act in enumerate(acts):
        if not act.get("name"):
            report.warning("story",
                          f"Act at index {i} has no name",
                          file="story.json")


# ============================================================================
# CROSS-REFERENCE CHECKS
# ============================================================================

def check_cross_references(report: IntegrityReport) -> None:
    """Check references between different data files."""
    lessons_data = load_json("lessons.json")
    lesson_ids: Set[str] = set()

    if lessons_data:
        for lesson in lessons_data.get("lessons", []):
            if lesson.get("id"):
                lesson_ids.add(lesson["id"])

    # Check map references (if map.json exists)
    map_data = load_json("map.json")
    if map_data:
        nodes = map_data.get("nodes", [])
        for node in nodes:
            lesson_ref = node.get("lesson_id", "")
            if lesson_ref and lesson_ref not in lesson_ids:
                report.error("cross_ref",
                            f"Map node references non-existent lesson: {lesson_ref}",
                            file="map.json")


# ============================================================================
# BALANCE SANITY CHECKS
# ============================================================================

def check_balance_sanity(report: IntegrityReport) -> None:
    """Check for obvious balance issues."""
    # Check upgrade cost progression
    kingdom = load_json("kingdom_upgrades.json")
    if kingdom:
        upgrades = kingdom.get("upgrades", [])
        tier_costs: Dict[int, List[int]] = {}

        for upgrade in upgrades:
            tier = upgrade.get("tier", 1)
            cost = upgrade.get("cost", {})
            total_cost = sum(int(v) for v in cost.values() if isinstance(v, (int, float)))

            if tier not in tier_costs:
                tier_costs[tier] = []
            tier_costs[tier].append(total_cost)

        # Check tier costs are generally increasing
        prev_avg = 0
        for tier in sorted(tier_costs.keys()):
            costs = tier_costs[tier]
            avg_cost = sum(costs) / len(costs) if costs else 0

            if avg_cost < prev_avg * 0.5 and tier > 1:
                report.warning("balance",
                              f"Tier {tier} upgrades cheaper than tier {tier-1} (avg {avg_cost:.0f} vs {prev_avg:.0f})",
                              file="kingdom_upgrades.json")
            prev_avg = avg_cost


# ============================================================================
# MAIN
# ============================================================================

def run_all_checks(categories: Optional[List[str]] = None) -> IntegrityReport:
    """Run all integrity checks."""
    report = IntegrityReport()

    checks = {
        "lessons": check_lessons,
        "upgrades": check_upgrades,
        "buildings": check_buildings,
        "assets": check_assets,
        "story": check_story,
        "cross_ref": check_cross_references,
        "balance": check_balance_sanity,
    }

    for name, check_func in checks.items():
        if categories is None or name in categories:
            try:
                check_func(report)
            except Exception as e:
                report.error(name, f"Check failed with exception: {e}")

    return report


def format_report(report: IntegrityReport, json_output: bool = False) -> str:
    """Format the report for output."""
    if json_output:
        return json.dumps({
            "errors": [vars(i) for i in report.errors],
            "warnings": [vars(i) for i in report.warnings],
            "info": [vars(i) for i in report.issues if i.severity == "info"],
            "has_errors": report.has_errors,
        }, indent=2)

    lines = []
    lines.append("=" * 60)
    lines.append("DATA INTEGRITY CHECK")
    lines.append("=" * 60)
    lines.append("")

    # Group by category
    categories: Dict[str, List[Issue]] = {}
    for issue in report.issues:
        if issue.category not in categories:
            categories[issue.category] = []
        categories[issue.category].append(issue)

    for category, issues in sorted(categories.items()):
        lines.append(f"--- {category.upper()} ---")
        for issue in issues:
            prefix = {"error": "[ERROR]", "warning": "[WARN]", "info": "[INFO]"}[issue.severity]
            lines.append(f"  {prefix} {issue.message}")
            if issue.fix_hint:
                lines.append(f"         Hint: {issue.fix_hint}")
        lines.append("")

    # Summary
    lines.append("=" * 60)
    lines.append("SUMMARY")
    lines.append("=" * 60)
    lines.append(f"  Errors:   {len(report.errors)}")
    lines.append(f"  Warnings: {len(report.warnings)}")
    lines.append(f"  Info:     {len([i for i in report.issues if i.severity == 'info'])}")
    lines.append("")
    lines.append(f"Result: {'FAIL' if report.has_errors else 'PASS'}")

    return "\n".join(lines)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Check data integrity beyond schema validation")
    parser.add_argument("--category", "-c", type=str,
                        help="Check specific category only")
    parser.add_argument("--json", "-j", action="store_true",
                        help="Output as JSON")
    parser.add_argument("--list", "-l", action="store_true",
                        help="List available categories")
    args = parser.parse_args()

    if args.list:
        print("Available categories:")
        print("  lessons    - Lesson definitions and graduation paths")
        print("  upgrades   - Kingdom and unit upgrades")
        print("  buildings  - Building definitions")
        print("  assets     - Asset manifest")
        print("  story      - Story and dialogue")
        print("  cross_ref  - Cross-file references")
        print("  balance    - Balance sanity checks")
        sys.exit(0)

    categories = [args.category] if args.category else None
    report = run_all_checks(categories)

    print(format_report(report, args.json))
    sys.exit(1 if report.has_errors else 0)


if __name__ == "__main__":
    main()
