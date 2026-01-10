#!/usr/bin/env python3
"""
Command Reference Generator

Auto-generates documentation for all game commands by analyzing:
- sim/intents.gd - Command help text and definitions
- sim/parse_command.gd - Command parsing and aliases
- sim/apply_intent.gd - Command implementations

Usage:
    python scripts/generate_command_ref.py              # Markdown output
    python scripts/generate_command_ref.py --json       # JSON output
    python scripts/generate_command_ref.py --html       # HTML output
    python scripts/generate_command_ref.py --output docs/COMMANDS.md
"""

import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional, Set

# Project paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent


@dataclass
class CommandInfo:
    """Information about a single command."""
    name: str
    aliases: List[str] = field(default_factory=list)
    description: str = ""
    usage: str = ""
    parameters: List[Dict[str, str]] = field(default_factory=list)
    examples: List[str] = field(default_factory=list)
    phase: str = ""  # When command can be used
    category: str = ""  # Command category


def parse_intents_file() -> Dict[str, CommandInfo]:
    """Parse sim/intents.gd for command definitions and help text."""
    commands = {}
    intents_file = PROJECT_ROOT / "sim" / "intents.gd"

    if not intents_file.exists():
        return commands

    try:
        content = intents_file.read_text(encoding="utf-8")
    except Exception:
        return commands

    # Find help_lines() function
    help_match = re.search(r"static func help_lines\(\)[^:]*:\s*\n\s*return\s*\[(.*?)\]", content, re.DOTALL)
    if help_match:
        help_content = help_match.group(1)
        # Parse help line entries
        for line_match in re.finditer(r'"([^"]+)"', help_content):
            line = line_match.group(1)
            # Parse format: "command [args] - description"
            parts = line.split(" - ", 1)
            if len(parts) == 2:
                cmd_part = parts[0].strip()
                desc = parts[1].strip()

                # Extract command name and usage
                cmd_match = re.match(r"(\w+)(?:\s+(.+))?", cmd_part)
                if cmd_match:
                    cmd_name = cmd_match.group(1).lower()
                    usage = cmd_match.group(2) or ""

                    if cmd_name not in commands:
                        commands[cmd_name] = CommandInfo(name=cmd_name)

                    commands[cmd_name].description = desc
                    commands[cmd_name].usage = f"{cmd_name} {usage}".strip()

    # Find make() calls for command definitions
    for match in re.finditer(r'static func (\w+)\([^)]*\)[^:]*:\s*\n\s*return\s*\{[^}]*"type":\s*"(\w+)"', content):
        func_name = match.group(1)
        cmd_type = match.group(2)
        if cmd_type not in commands:
            commands[cmd_type] = CommandInfo(name=cmd_type)

    return commands


def parse_command_parser() -> Dict[str, List[str]]:
    """Parse sim/parse_command.gd for command aliases."""
    aliases = {}
    parser_file = PROJECT_ROOT / "sim" / "parse_command.gd"

    if not parser_file.exists():
        return aliases

    try:
        content = parser_file.read_text(encoding="utf-8")
    except Exception:
        return aliases

    # Find match statements with command aliases
    # Pattern: "alias1", "alias2", "alias3":
    current_cmd = None
    for line in content.split("\n"):
        line = line.strip()

        # Look for case with string literals
        if line.startswith('"') and ':' in line:
            # Extract all quoted strings before the colon
            alias_part = line.split(":")[0]
            found_aliases = re.findall(r'"(\w+)"', alias_part)
            if found_aliases:
                # The canonical name is usually the last or most descriptive
                canonical = found_aliases[-1] if len(found_aliases) > 1 else found_aliases[0]
                for alias in found_aliases:
                    if canonical not in aliases:
                        aliases[canonical] = []
                    if alias != canonical and alias not in aliases[canonical]:
                        aliases[canonical].append(alias)

    return aliases


def parse_apply_intent() -> Dict[str, Dict[str, str]]:
    """Parse sim/apply_intent.gd for command implementations."""
    implementations = {}
    apply_file = PROJECT_ROOT / "sim" / "apply_intent.gd"

    if not apply_file.exists():
        return implementations

    try:
        content = apply_file.read_text(encoding="utf-8")
    except Exception:
        return implementations

    # Find _apply_* functions and their phase checks
    for match in re.finditer(r'static func _apply_(\w+)\([^)]*\)[^:]*:(.*?)(?=\nstatic func|\Z)', content, re.DOTALL):
        cmd_name = match.group(1)
        func_body = match.group(2)

        impl_info = {"phase": "any", "effects": []}

        # Check for phase restrictions
        if 'phase != "day"' in func_body or 'phase == "night"' in func_body:
            impl_info["phase"] = "night"
        elif 'phase != "night"' in func_body or 'phase == "day"' in func_body:
            impl_info["phase"] = "day"

        # Look for events.append calls to understand effects
        for event_match in re.finditer(r'events\.append\(["\']([^"\']+)["\']', func_body):
            effect = event_match.group(1)
            if "%" not in effect:  # Skip parameterized messages
                impl_info["effects"].append(effect)

        implementations[cmd_name] = impl_info

    return implementations


def categorize_command(name: str) -> str:
    """Categorize a command based on its name."""
    categories = {
        "movement": ["move", "go", "walk", "run", "n", "s", "e", "w", "ne", "nw", "se", "sw"],
        "building": ["build", "construct", "place", "tower", "wall", "upgrade"],
        "combat": ["attack", "fire", "target", "defend"],
        "resource": ["gather", "collect", "chop", "mine", "harvest"],
        "management": ["assign", "worker", "hire", "train"],
        "info": ["look", "examine", "status", "help", "map", "info"],
        "system": ["save", "load", "quit", "pause", "settings"],
        "progression": ["research", "unlock", "learn"],
    }

    name_lower = name.lower()
    for category, keywords in categories.items():
        if name_lower in keywords or any(kw in name_lower for kw in keywords):
            return category
    return "misc"


def gather_commands() -> List[CommandInfo]:
    """Gather all command information from source files."""
    # Start with intents definitions
    commands = parse_intents_file()

    # Add aliases from parser
    aliases = parse_command_parser()
    for cmd_name, cmd_aliases in aliases.items():
        if cmd_name in commands:
            commands[cmd_name].aliases = cmd_aliases
        else:
            commands[cmd_name] = CommandInfo(name=cmd_name, aliases=cmd_aliases)

    # Add implementation details
    implementations = parse_apply_intent()
    for cmd_name, impl_info in implementations.items():
        if cmd_name in commands:
            commands[cmd_name].phase = impl_info.get("phase", "any")
        else:
            commands[cmd_name] = CommandInfo(name=cmd_name, phase=impl_info.get("phase", "any"))

    # Categorize commands
    for cmd in commands.values():
        cmd.category = categorize_command(cmd.name)

    return list(commands.values())


def format_markdown(commands: List[CommandInfo]) -> str:
    """Format commands as Markdown documentation."""
    lines = []
    lines.append("# Command Reference")
    lines.append("")
    lines.append("Auto-generated documentation for all game commands.")
    lines.append("")

    # Group by category
    by_category: Dict[str, List[CommandInfo]] = {}
    for cmd in commands:
        cat = cmd.category or "misc"
        if cat not in by_category:
            by_category[cat] = []
        by_category[cat].append(cmd)

    # Table of contents
    lines.append("## Table of Contents")
    lines.append("")
    for category in sorted(by_category.keys()):
        title = category.title()
        lines.append(f"- [{title}](#{category.lower()})")
    lines.append("")

    # Commands by category
    for category in sorted(by_category.keys()):
        cmds = by_category[category]
        title = category.title()

        lines.append(f"## {title}")
        lines.append("")

        for cmd in sorted(cmds, key=lambda x: x.name):
            lines.append(f"### `{cmd.name}`")
            lines.append("")

            if cmd.description:
                lines.append(cmd.description)
                lines.append("")

            if cmd.usage:
                lines.append(f"**Usage:** `{cmd.usage}`")
                lines.append("")

            if cmd.aliases:
                lines.append(f"**Aliases:** {', '.join(f'`{a}`' for a in cmd.aliases)}")
                lines.append("")

            if cmd.phase and cmd.phase != "any":
                lines.append(f"**Available:** {cmd.phase} phase only")
                lines.append("")

            if cmd.parameters:
                lines.append("**Parameters:**")
                for param in cmd.parameters:
                    lines.append(f"- `{param['name']}`: {param.get('description', '')}")
                lines.append("")

            if cmd.examples:
                lines.append("**Examples:**")
                lines.append("```")
                for ex in cmd.examples:
                    lines.append(ex)
                lines.append("```")
                lines.append("")

            lines.append("---")
            lines.append("")

    # Footer
    lines.append("## Notes")
    lines.append("")
    lines.append("- Commands are case-insensitive")
    lines.append("- Some commands require specific game phases (day/night)")
    lines.append("- Use `help` command in-game for quick reference")
    lines.append("")
    lines.append("*Generated by `scripts/generate_command_ref.py`*")

    return "\n".join(lines)


def format_json(commands: List[CommandInfo]) -> str:
    """Format commands as JSON."""
    data = {
        "commands": [
            {
                "name": cmd.name,
                "aliases": cmd.aliases,
                "description": cmd.description,
                "usage": cmd.usage,
                "phase": cmd.phase,
                "category": cmd.category,
                "parameters": cmd.parameters,
                "examples": cmd.examples,
            }
            for cmd in sorted(commands, key=lambda x: x.name)
        ]
    }
    return json.dumps(data, indent=2)


def format_html(commands: List[CommandInfo]) -> str:
    """Format commands as HTML."""
    lines = []
    lines.append("<!DOCTYPE html>")
    lines.append("<html><head>")
    lines.append("<title>Keyboard Defense - Command Reference</title>")
    lines.append("<style>")
    lines.append("body { font-family: sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }")
    lines.append("code { background: #f4f4f4; padding: 2px 6px; border-radius: 3px; }")
    lines.append(".command { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }")
    lines.append(".command h3 { margin-top: 0; color: #2c3e50; }")
    lines.append(".aliases { color: #666; font-size: 0.9em; }")
    lines.append(".phase { color: #e74c3c; font-weight: bold; }")
    lines.append(".category { display: inline-block; background: #3498db; color: white; padding: 2px 8px; border-radius: 3px; font-size: 0.8em; }")
    lines.append("</style>")
    lines.append("</head><body>")
    lines.append("<h1>Command Reference</h1>")

    # Group by category
    by_category: Dict[str, List[CommandInfo]] = {}
    for cmd in commands:
        cat = cmd.category or "misc"
        if cat not in by_category:
            by_category[cat] = []
        by_category[cat].append(cmd)

    for category in sorted(by_category.keys()):
        cmds = by_category[category]
        lines.append(f"<h2>{category.title()}</h2>")

        for cmd in sorted(cmds, key=lambda x: x.name):
            lines.append('<div class="command">')
            lines.append(f'<h3><code>{cmd.name}</code> <span class="category">{cmd.category}</span></h3>')

            if cmd.description:
                lines.append(f"<p>{cmd.description}</p>")

            if cmd.usage:
                lines.append(f"<p><strong>Usage:</strong> <code>{cmd.usage}</code></p>")

            if cmd.aliases:
                aliases_str = ", ".join(f"<code>{a}</code>" for a in cmd.aliases)
                lines.append(f'<p class="aliases"><strong>Aliases:</strong> {aliases_str}</p>')

            if cmd.phase and cmd.phase != "any":
                lines.append(f'<p class="phase">Available: {cmd.phase} phase only</p>')

            lines.append("</div>")

    lines.append("<hr>")
    lines.append("<p><em>Generated by generate_command_ref.py</em></p>")
    lines.append("</body></html>")

    return "\n".join(lines)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Generate command reference documentation")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--html", action="store_true", help="HTML output")
    parser.add_argument("--output", "-o", type=str, help="Output file path")
    args = parser.parse_args()

    commands = gather_commands()

    if not commands:
        print("No commands found. Check that sim/intents.gd exists.")
        sys.exit(1)

    if args.json:
        output = format_json(commands)
    elif args.html:
        output = format_html(commands)
    else:
        output = format_markdown(commands)

    if args.output:
        output_path = Path(args.output)
        if not output_path.is_absolute():
            output_path = PROJECT_ROOT / output_path
        output_path.write_text(output, encoding="utf-8")
        print(f"Wrote {len(commands)} commands to {output_path}")
    else:
        print(output)


if __name__ == "__main__":
    main()
