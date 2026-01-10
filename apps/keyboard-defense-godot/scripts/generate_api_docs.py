#!/usr/bin/env python3
"""
API Documentation Generator

Generates documentation from GDScript source code:
- Class documentation from class_name and docstrings
- Function signatures and descriptions
- Signal documentation
- Constant and enum documentation
- Exports and properties

Usage:
    python scripts/generate_api_docs.py              # Generate all docs
    python scripts/generate_api_docs.py --file sim/types.gd  # Single file
    python scripts/generate_api_docs.py --output docs/API.md
    python scripts/generate_api_docs.py --json       # JSON output
    python scripts/generate_api_docs.py --layer sim  # Only sim layer
"""

import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Set, Optional, Tuple

# Project paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent


@dataclass
class Parameter:
    """Function parameter."""
    name: str
    type_hint: str = ""
    default: str = ""


@dataclass
class FunctionDoc:
    """Documentation for a function."""
    name: str
    line: int
    is_static: bool = False
    params: List[Parameter] = field(default_factory=list)
    return_type: str = ""
    description: str = ""
    is_private: bool = False


@dataclass
class SignalDoc:
    """Documentation for a signal."""
    name: str
    line: int
    params: List[Parameter] = field(default_factory=list)
    description: str = ""


@dataclass
class PropertyDoc:
    """Documentation for a property/variable."""
    name: str
    line: int
    type_hint: str = ""
    default: str = ""
    is_export: bool = False
    is_onready: bool = False
    description: str = ""


@dataclass
class ConstantDoc:
    """Documentation for a constant."""
    name: str
    line: int
    value: str = ""
    description: str = ""


@dataclass
class EnumDoc:
    """Documentation for an enum."""
    name: str
    line: int
    values: Dict[str, int] = field(default_factory=dict)
    description: str = ""


@dataclass
class ClassDoc:
    """Documentation for a class/file."""
    path: str
    class_name: str = ""
    extends: str = ""
    description: str = ""
    layer: str = ""  # sim, game, ui
    signals: List[SignalDoc] = field(default_factory=list)
    constants: List[ConstantDoc] = field(default_factory=list)
    enums: List[EnumDoc] = field(default_factory=list)
    properties: List[PropertyDoc] = field(default_factory=list)
    functions: List[FunctionDoc] = field(default_factory=list)


def get_layer(filepath: str) -> str:
    """Determine which architectural layer a file belongs to."""
    if filepath.startswith("sim/"):
        return "sim"
    elif filepath.startswith("game/"):
        return "game"
    elif filepath.startswith("ui/"):
        return "ui"
    elif filepath.startswith("scripts/"):
        return "scripts"
    return "other"


def parse_params(param_str: str) -> List[Parameter]:
    """Parse function parameters."""
    params = []
    if not param_str.strip():
        return params

    # Split by comma, but respect nested parentheses
    depth = 0
    current = ""
    for char in param_str:
        if char == '(':
            depth += 1
            current += char
        elif char == ')':
            depth -= 1
            current += char
        elif char == ',' and depth == 0:
            if current.strip():
                params.append(parse_single_param(current.strip()))
            current = ""
        else:
            current += char

    if current.strip():
        params.append(parse_single_param(current.strip()))

    return params


def parse_single_param(param: str) -> Parameter:
    """Parse a single parameter."""
    # Format: name: Type = default
    p = Parameter(name=param)

    # Check for default value
    if '=' in param:
        parts = param.split('=', 1)
        param = parts[0].strip()
        p.default = parts[1].strip()

    # Check for type hint
    if ':' in param:
        parts = param.split(':', 1)
        p.name = parts[0].strip()
        p.type_hint = parts[1].strip()
    else:
        p.name = param

    return p


def extract_docstring(lines: List[str], start_idx: int) -> str:
    """Extract docstring comment before a definition."""
    docs = []
    idx = start_idx - 1

    # Look for ## comments before the definition
    while idx >= 0:
        line = lines[idx].strip()
        if line.startswith('##'):
            docs.insert(0, line[2:].strip())
            idx -= 1
        elif line.startswith('#'):
            # Single # might be a section separator, skip
            idx -= 1
        elif not line:
            idx -= 1
        else:
            break

    return ' '.join(docs)


def parse_file(filepath: Path) -> ClassDoc:
    """Parse a GDScript file for documentation."""
    rel_path = str(filepath.relative_to(PROJECT_ROOT))
    doc = ClassDoc(path=rel_path, layer=get_layer(rel_path))

    try:
        content = filepath.read_text(encoding="utf-8")
        lines = content.split('\n')
    except Exception:
        return doc

    # Parse class-level info
    for i, line in enumerate(lines):
        stripped = line.strip()

        # class_name
        match = re.match(r'^class_name\s+(\w+)', stripped)
        if match:
            doc.class_name = match.group(1)
            doc.description = extract_docstring(lines, i)
            continue

        # extends
        match = re.match(r'^extends\s+(\w+)', stripped)
        if match:
            doc.extends = match.group(1)
            continue

        # signals
        match = re.match(r'^signal\s+(\w+)(?:\(([^)]*)\))?', stripped)
        if match:
            sig = SignalDoc(
                name=match.group(1),
                line=i + 1,
                params=parse_params(match.group(2) or ""),
                description=extract_docstring(lines, i)
            )
            doc.signals.append(sig)
            continue

        # constants
        match = re.match(r'^const\s+(\w+)\s*(?::\s*\w+)?\s*=\s*(.+)', stripped)
        if match:
            const = ConstantDoc(
                name=match.group(1),
                line=i + 1,
                value=match.group(2).strip(),
                description=extract_docstring(lines, i)
            )
            doc.constants.append(const)
            continue

        # enums
        match = re.match(r'^enum\s+(\w+)\s*\{', stripped)
        if match:
            enum = EnumDoc(
                name=match.group(1),
                line=i + 1,
                description=extract_docstring(lines, i)
            )
            # Parse enum values
            enum_content = ""
            j = i
            brace_count = 0
            while j < len(lines):
                for char in lines[j]:
                    if char == '{':
                        brace_count += 1
                    elif char == '}':
                        brace_count -= 1
                enum_content += lines[j] + "\n"
                if brace_count == 0 and '{' in enum_content:
                    break
                j += 1

            # Extract values
            values_match = re.findall(r'(\w+)\s*(?:=\s*(\d+))?', enum_content)
            current_val = 0
            for val_name, val_num in values_match:
                if val_name in ['enum', enum.name]:
                    continue
                if val_num:
                    current_val = int(val_num)
                enum.values[val_name] = current_val
                current_val += 1

            doc.enums.append(enum)
            continue

        # exports and properties
        match = re.match(r'^(@export\s+)?(@onready\s+)?var\s+(\w+)\s*(?::\s*(\w+))?\s*(?:=\s*(.+))?', stripped)
        if match:
            prop = PropertyDoc(
                name=match.group(3),
                line=i + 1,
                is_export=bool(match.group(1)),
                is_onready=bool(match.group(2)),
                type_hint=match.group(4) or "",
                default=match.group(5) or "",
                description=extract_docstring(lines, i)
            )
            doc.properties.append(prop)
            continue

        # functions
        match = re.match(r'^(static\s+)?func\s+(\w+)\s*\(([^)]*)\)\s*(?:->\s*(\w+))?', stripped)
        if match:
            func = FunctionDoc(
                name=match.group(2),
                line=i + 1,
                is_static=bool(match.group(1)),
                params=parse_params(match.group(3)),
                return_type=match.group(4) or "",
                description=extract_docstring(lines, i),
                is_private=match.group(2).startswith('_')
            )
            doc.functions.append(func)
            continue

    return doc


def generate_docs(target_file: Optional[str] = None, layer: Optional[str] = None) -> List[ClassDoc]:
    """Generate documentation for all files."""
    docs = []

    if target_file:
        filepath = PROJECT_ROOT / target_file
        if filepath.exists():
            docs.append(parse_file(filepath))
        return docs

    for gd_file in PROJECT_ROOT.glob("**/*.gd"):
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue

        doc = parse_file(gd_file)

        # Filter by layer if specified
        if layer and doc.layer != layer:
            continue

        # Only include files with class_name or significant content
        if doc.class_name or doc.functions or doc.signals:
            docs.append(doc)

    return docs


def format_markdown(docs: List[ClassDoc]) -> str:
    """Format documentation as Markdown."""
    lines = []
    lines.append("# API Documentation")
    lines.append("")
    lines.append("Auto-generated documentation for Keyboard Defense GDScript code.")
    lines.append("")

    # Group by layer
    by_layer: Dict[str, List[ClassDoc]] = {}
    for doc in docs:
        if doc.layer not in by_layer:
            by_layer[doc.layer] = []
        by_layer[doc.layer].append(doc)

    # Table of contents
    lines.append("## Table of Contents")
    lines.append("")
    for layer in ["sim", "game", "ui", "scripts", "other"]:
        if layer in by_layer:
            lines.append(f"- [{layer.upper()} Layer](#{layer}-layer)")
            for doc in sorted(by_layer[layer], key=lambda d: d.class_name or d.path):
                name = doc.class_name or Path(doc.path).stem
                anchor = name.lower().replace("_", "-")
                lines.append(f"  - [{name}](#{anchor})")
    lines.append("")

    # Documentation by layer
    for layer in ["sim", "game", "ui", "scripts", "other"]:
        if layer not in by_layer:
            continue

        lines.append(f"## {layer.upper()} Layer")
        lines.append("")

        for doc in sorted(by_layer[layer], key=lambda d: d.class_name or d.path):
            name = doc.class_name or Path(doc.path).stem

            lines.append(f"### {name}")
            lines.append("")
            lines.append(f"**File:** `{doc.path}`")
            if doc.extends:
                lines.append(f"**Extends:** `{doc.extends}`")
            lines.append("")

            if doc.description:
                lines.append(doc.description)
                lines.append("")

            # Signals
            if doc.signals:
                lines.append("#### Signals")
                lines.append("")
                for sig in doc.signals:
                    params = ", ".join(
                        f"{p.name}: {p.type_hint}" if p.type_hint else p.name
                        for p in sig.params
                    )
                    lines.append(f"- `signal {sig.name}({params})`")
                    if sig.description:
                        lines.append(f"  - {sig.description}")
                lines.append("")

            # Constants
            public_consts = [c for c in doc.constants if not c.name.startswith('_')]
            if public_consts:
                lines.append("#### Constants")
                lines.append("")
                for const in public_consts[:20]:
                    value = const.value[:50] + "..." if len(const.value) > 50 else const.value
                    lines.append(f"- `{const.name}` = `{value}`")
                    if const.description:
                        lines.append(f"  - {const.description}")
                if len(public_consts) > 20:
                    lines.append(f"- *... and {len(public_consts) - 20} more*")
                lines.append("")

            # Enums
            if doc.enums:
                lines.append("#### Enums")
                lines.append("")
                for enum in doc.enums:
                    lines.append(f"**{enum.name}**")
                    if enum.description:
                        lines.append(f"- {enum.description}")
                    for val_name, val_num in enum.values.items():
                        lines.append(f"- `{val_name}` = {val_num}")
                    lines.append("")

            # Public functions
            public_funcs = [f for f in doc.functions if not f.is_private]
            if public_funcs:
                lines.append("#### Functions")
                lines.append("")
                for func in public_funcs:
                    # Build signature
                    params = ", ".join(
                        f"{p.name}: {p.type_hint}" if p.type_hint else p.name
                        for p in func.params
                    )
                    static = "static " if func.is_static else ""
                    ret = f" -> {func.return_type}" if func.return_type else ""
                    lines.append(f"##### `{static}func {func.name}({params}){ret}`")
                    if func.description:
                        lines.append(f"{func.description}")
                    lines.append("")

            lines.append("---")
            lines.append("")

    lines.append("*Generated by `scripts/generate_api_docs.py`*")

    return "\n".join(lines)


def format_json(docs: List[ClassDoc]) -> str:
    """Format as JSON."""
    data = {
        "classes": [
            {
                "path": doc.path,
                "class_name": doc.class_name,
                "extends": doc.extends,
                "layer": doc.layer,
                "description": doc.description,
                "signals": [
                    {
                        "name": s.name,
                        "params": [{"name": p.name, "type": p.type_hint} for p in s.params],
                        "description": s.description,
                    }
                    for s in doc.signals
                ],
                "constants": [
                    {"name": c.name, "value": c.value, "description": c.description}
                    for c in doc.constants if not c.name.startswith('_')
                ],
                "enums": [
                    {"name": e.name, "values": e.values, "description": e.description}
                    for e in doc.enums
                ],
                "functions": [
                    {
                        "name": f.name,
                        "is_static": f.is_static,
                        "params": [
                            {"name": p.name, "type": p.type_hint, "default": p.default}
                            for p in f.params
                        ],
                        "return_type": f.return_type,
                        "description": f.description,
                    }
                    for f in doc.functions if not f.is_private
                ],
            }
            for doc in docs
        ]
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Generate API documentation")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Document single file")
    parser.add_argument("--output", "-o", type=str, help="Output file path")
    parser.add_argument("--layer", "-l", type=str, choices=["sim", "game", "ui", "scripts"],
                       help="Only document specific layer")
    args = parser.parse_args()

    docs = generate_docs(args.file, args.layer)

    if args.json:
        output = format_json(docs)
    else:
        output = format_markdown(docs)

    if args.output:
        output_path = Path(args.output)
        if not output_path.is_absolute():
            output_path = PROJECT_ROOT / output_path
        output_path.write_text(output, encoding="utf-8")
        print(f"Generated documentation for {len(docs)} classes to {output_path}")
    else:
        print(output)


if __name__ == "__main__":
    main()
