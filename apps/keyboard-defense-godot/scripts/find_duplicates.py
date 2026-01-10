#!/usr/bin/env python3
"""
Code Duplication Finder

Finds duplicate or similar code blocks in GDScript files:
- Exact duplicate lines/blocks
- Similar function implementations
- Copy-paste code patterns
- Repeated logic that could be refactored

Usage:
    python scripts/find_duplicates.py              # Full report
    python scripts/find_duplicates.py --min-lines 5  # Min block size
    python scripts/find_duplicates.py --threshold 0.8  # Similarity threshold
    python scripts/find_duplicates.py --json       # JSON output
"""

import hashlib
import json
import re
import sys
from collections import defaultdict
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Set, Tuple, Optional

# Project paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent


@dataclass
class CodeBlock:
    """A block of code."""
    file: str
    start_line: int
    end_line: int
    content: str
    normalized: str  # Content with whitespace/names normalized
    hash: str


@dataclass
class DuplicateGroup:
    """A group of duplicate code blocks."""
    blocks: List[CodeBlock] = field(default_factory=list)
    line_count: int = 0
    similarity: float = 1.0

    @property
    def instance_count(self) -> int:
        return len(self.blocks)

    @property
    def total_duplicate_lines(self) -> int:
        return self.line_count * (self.instance_count - 1)


@dataclass
class DuplicationReport:
    """Report of code duplication."""
    total_files: int = 0
    total_lines: int = 0
    duplicate_groups: List[DuplicateGroup] = field(default_factory=list)
    duplicate_line_count: int = 0
    duplication_percentage: float = 0.0


def normalize_code(content: str) -> str:
    """Normalize code for comparison (remove variable names, whitespace variations)."""
    lines = []
    for line in content.split('\n'):
        # Strip whitespace
        line = line.strip()
        # Skip empty lines and comments
        if not line or line.startswith('#'):
            continue
        # Normalize variable names to placeholders
        # This is simplified - a real implementation would use AST
        line = re.sub(r'\b[a-z_][a-z0-9_]*\b', 'VAR', line)
        # Normalize string literals
        line = re.sub(r'"[^"]*"', '"STR"', line)
        line = re.sub(r"'[^']*'", "'STR'", line)
        # Normalize numbers
        line = re.sub(r'\b\d+\.?\d*\b', 'NUM', line)
        lines.append(line)
    return '\n'.join(lines)


def hash_block(content: str) -> str:
    """Create hash of normalized code block."""
    return hashlib.md5(content.encode()).hexdigest()


def extract_blocks(filepath: Path, min_lines: int = 4) -> List[CodeBlock]:
    """Extract code blocks from a file."""
    blocks = []
    rel_path = str(filepath.relative_to(PROJECT_ROOT))

    try:
        content = filepath.read_text(encoding="utf-8")
        lines = content.split('\n')
    except Exception:
        return blocks

    # Extract function blocks
    func_pattern = re.compile(r'^(\s*)(static\s+)?func\s+\w+')
    i = 0
    while i < len(lines):
        match = func_pattern.match(lines[i])
        if match:
            start = i
            base_indent = len(match.group(1))

            # Find end of function
            i += 1
            while i < len(lines):
                line = lines[i]
                if line.strip() and not line.strip().startswith('#'):
                    current_indent = len(line) - len(line.lstrip())
                    if current_indent <= base_indent and not line.strip().startswith('@'):
                        # Check if it's a new function or class
                        if func_pattern.match(line) or line.strip().startswith('class '):
                            break
                i += 1

            # Create block if large enough
            block_lines = lines[start:i]
            block_content = '\n'.join(block_lines)
            code_lines = [l for l in block_lines if l.strip() and not l.strip().startswith('#')]

            if len(code_lines) >= min_lines:
                normalized = normalize_code(block_content)
                blocks.append(CodeBlock(
                    file=rel_path,
                    start_line=start + 1,
                    end_line=i,
                    content=block_content,
                    normalized=normalized,
                    hash=hash_block(normalized)
                ))
        else:
            i += 1

    # Also extract standalone code blocks (consecutive non-function lines)
    i = 0
    while i < len(lines):
        # Skip function definitions
        if func_pattern.match(lines[i]):
            # Skip to end of function
            i += 1
            while i < len(lines) and (not lines[i].strip() or lines[i].startswith('\t') or lines[i].startswith(' ')):
                i += 1
            continue

        # Find consecutive code lines at same indent
        if lines[i].strip() and not lines[i].strip().startswith('#'):
            start = i
            start_indent = len(lines[i]) - len(lines[i].lstrip())

            while i < len(lines):
                line = lines[i]
                if not line.strip():
                    i += 1
                    continue
                if line.strip().startswith('#'):
                    i += 1
                    continue
                current_indent = len(line) - len(line.lstrip())
                if current_indent < start_indent:
                    break
                if func_pattern.match(line):
                    break
                i += 1

            block_lines = lines[start:i]
            code_lines = [l for l in block_lines if l.strip() and not l.strip().startswith('#')]

            if len(code_lines) >= min_lines:
                block_content = '\n'.join(block_lines)
                normalized = normalize_code(block_content)
                # Only add if not already covered by a function block
                block_hash = hash_block(normalized)
                if not any(b.hash == block_hash for b in blocks):
                    blocks.append(CodeBlock(
                        file=rel_path,
                        start_line=start + 1,
                        end_line=i,
                        content=block_content,
                        normalized=normalized,
                        hash=block_hash
                    ))
        else:
            i += 1

    return blocks


def find_duplicates(blocks: List[CodeBlock], threshold: float = 0.9) -> List[DuplicateGroup]:
    """Find duplicate code blocks."""
    # Group by hash for exact matches
    by_hash: Dict[str, List[CodeBlock]] = defaultdict(list)
    for block in blocks:
        by_hash[block.hash].append(block)

    groups = []

    # Find exact duplicates
    for hash_val, block_list in by_hash.items():
        if len(block_list) > 1:
            # Verify they're from different files or locations
            locations = set((b.file, b.start_line) for b in block_list)
            if len(locations) > 1:
                group = DuplicateGroup(
                    blocks=block_list,
                    line_count=len(block_list[0].normalized.split('\n')),
                    similarity=1.0
                )
                groups.append(group)

    # For similar (not exact) matches, we'd need more sophisticated comparison
    # This is a simplified version that only finds exact normalized matches

    return groups


def analyze_codebase(min_lines: int = 4, threshold: float = 0.9) -> DuplicationReport:
    """Analyze codebase for duplication."""
    report = DuplicationReport()
    all_blocks = []

    for gd_file in PROJECT_ROOT.glob("**/*.gd"):
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue

        try:
            content = gd_file.read_text(encoding="utf-8")
            report.total_lines += len(content.split('\n'))
        except Exception:
            continue

        report.total_files += 1
        blocks = extract_blocks(gd_file, min_lines)
        all_blocks.extend(blocks)

    # Find duplicates
    report.duplicate_groups = find_duplicates(all_blocks, threshold)

    # Calculate statistics
    report.duplicate_line_count = sum(
        g.total_duplicate_lines for g in report.duplicate_groups
    )
    report.duplication_percentage = (
        report.duplicate_line_count * 100 / max(report.total_lines, 1)
    )

    # Sort by impact (total duplicate lines)
    report.duplicate_groups.sort(key=lambda g: g.total_duplicate_lines, reverse=True)

    return report


def format_report(report: DuplicationReport) -> str:
    """Format duplication report."""
    lines = []
    lines.append("=" * 60)
    lines.append("CODE DUPLICATION FINDER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Files analyzed: {report.total_files}")
    lines.append(f"  Total lines: {report.total_lines:,}")
    lines.append(f"  Duplicate groups: {len(report.duplicate_groups)}")
    lines.append(f"  Duplicate lines: {report.duplicate_line_count:,}")
    lines.append(f"  Duplication: {report.duplication_percentage:.1f}%")
    lines.append("")

    if not report.duplicate_groups:
        lines.append("No significant code duplication found!")
        return "\n".join(lines)

    # Top duplicates
    lines.append("## TOP DUPLICATES (by impact)")
    for i, group in enumerate(report.duplicate_groups[:15]):
        lines.append(f"\n### Duplicate #{i+1}")
        lines.append(f"  Instances: {group.instance_count}")
        lines.append(f"  Lines per instance: {group.line_count}")
        lines.append(f"  Total duplicate lines: {group.total_duplicate_lines}")
        lines.append("  Locations:")
        for block in group.blocks[:5]:
            lines.append(f"    - {block.file}:{block.start_line}-{block.end_line}")
        if len(group.blocks) > 5:
            lines.append(f"    ... and {len(group.blocks) - 5} more locations")

        # Show sample code
        if group.blocks:
            sample = group.blocks[0].content.split('\n')[:8]
            lines.append("  Sample:")
            for line in sample:
                lines.append(f"    {line[:70]}")
            if len(group.blocks[0].content.split('\n')) > 8:
                lines.append("    ...")

    # Files with most duplication
    lines.append("\n## FILES WITH MOST DUPLICATION")
    file_dupes: Dict[str, int] = defaultdict(int)
    for group in report.duplicate_groups:
        for block in group.blocks:
            file_dupes[block.file] += group.line_count

    for file, dupe_lines in sorted(file_dupes.items(), key=lambda x: -x[1])[:10]:
        lines.append(f"  {dupe_lines:4} lines  {file}")
    lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    if report.duplication_percentage > 15:
        lines.append(f"  [WARN] High duplication: {report.duplication_percentage:.1f}%")
    elif report.duplication_percentage > 5:
        lines.append(f"  [INFO] Moderate duplication: {report.duplication_percentage:.1f}%")
    else:
        lines.append(f"  [OK] Low duplication: {report.duplication_percentage:.1f}%")

    if len(report.duplicate_groups) > 20:
        lines.append(f"  [WARN] Many duplicate patterns: {len(report.duplicate_groups)}")

    lines.append("")
    lines.append("Consider extracting duplicate code into shared functions or utilities.")

    return "\n".join(lines)


def format_json(report: DuplicationReport) -> str:
    """Format as JSON."""
    data = {
        "summary": {
            "total_files": report.total_files,
            "total_lines": report.total_lines,
            "duplicate_groups": len(report.duplicate_groups),
            "duplicate_lines": report.duplicate_line_count,
            "duplication_percentage": report.duplication_percentage,
        },
        "duplicates": [
            {
                "instances": group.instance_count,
                "lines_per_instance": group.line_count,
                "total_duplicate_lines": group.total_duplicate_lines,
                "similarity": group.similarity,
                "locations": [
                    {
                        "file": b.file,
                        "start_line": b.start_line,
                        "end_line": b.end_line,
                    }
                    for b in group.blocks
                ],
            }
            for group in report.duplicate_groups[:50]
        ],
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Find code duplication")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--min-lines", "-m", type=int, default=4, help="Min lines for block")
    parser.add_argument("--threshold", "-t", type=float, default=0.9, help="Similarity threshold")
    args = parser.parse_args()

    report = analyze_codebase(args.min_lines, args.threshold)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report))


if __name__ == "__main__":
    main()
