# Recent Changes

This file tracks recent changes for Claude Code context.

---

## 2026-01-10: Development Tools Batch 18

Added code quality and pattern detection tools:

### Variable Shadowing Checker (`scripts/check_variable_shadowing.py`)
- Finds parameters shadowing class variables
- Detects local variables shadowing parameters
- Identifies loop variables shadowing outer scope

### Godot Patterns Checker (`scripts/check_godot_patterns.py`)
- Detects deprecated Godot 4 API usage
- Finds common mistakes (yield vs await, connect syntax)
- Reports performance anti-patterns
- Checks node lifecycle issues

### Error Handling Checker (`scripts/check_error_handling.py`)
- Finds file I/O without null checks
- Detects JSON parsing without error handling
- Reports unsafe dictionary/array access
- Checks resource loading validation

---

## 2026-01-10: Development Tools Batch 17

Added comment, enum, and file organization analysis tools:

### Comment Quality Checker (`scripts/check_comments.py`)
- Analyzes comment density and distribution
- Detects commented-out code
- Distinguishes doc comments (##) from inline (#)
- Reports best/worst commented files

### Enum Analyzer (`scripts/analyze_enums.py`)
- Lists all enum declarations and values
- Tracks usage per enum value
- Finds unused enum values
- Detects enum-like constant patterns

### File Organization Checker (`scripts/check_file_organization.py`)
- Validates file placement by layer
- Checks naming convention compliance
- Detects large files (>500 lines)
- Reports directory structure consistency

---

## 2026-01-10: Development Tools Batch 16

Added code quality and architecture tools:

### String Literal Checker (`scripts/check_string_literals.py`)
- Finds repeated string literals
- Suggests constant names
- Categorizes by type (path, identifier, etc.)

### Coupling Analyzer (`scripts/analyze_coupling.py`)
- Measures afferent/efferent coupling
- Calculates instability metrics
- Detects layer violations

### Match Pattern Checker (`scripts/check_match_patterns.py`)
- Finds missing default cases
- Detects duplicate patterns
- Reports large match statements

---

## 2026-01-10: Development Tools Batch 15

Added code analysis and pattern detection tools:

### Dictionary Key Checker (`scripts/check_dict_keys.py`)
- Finds similar keys (potential typos)
- Detects single-use keys
- Checks naming consistency

### Inheritance Analyzer (`scripts/analyze_inheritance.py`)
- Maps class inheritance hierarchy
- Detects deep inheritance chains
- Reports base class usage statistics

### Await Pattern Checker (`scripts/check_await_patterns.py`)
- Finds await in hot path functions (_process)
- Analyzes signal and timer await patterns
- Reports functions with most awaits

---

## 2026-01-10: Development Tools Batch 14

Added code quality and data validation tools:

### Function Length Checker (`scripts/check_func_length.py`)
- Finds functions exceeding line count threshold
- Identifies refactoring candidates
- Reports average function length

### JSON Reference Validator (`scripts/validate_json_refs.py`)
- Validates cross-references between data files
- Finds broken ID references
- Detects orphan entries (never referenced)

### Node Reference Checker (`scripts/check_node_refs.py`)
- Analyzes $ syntax and get_node() patterns
- Recommends @onready usage
- Warns about deep path fragility

---

## 2026-01-10: Development Tools Batch 13

Added validation tools for code structure:

### Class Name Validator (`scripts/check_class_names.py`)
- Validates class_name matches filename convention
- Detects duplicate class_name declarations
- Reports mismatches and missing class_name

### Scene Validator (`scripts/validate_scenes.py`)
- Validates .tscn scene files
- Detects missing resources and scripts
- Reports deep nesting and large scenes
- Finds duplicate node names

### Signal Signature Checker (`scripts/check_signal_signatures.py`)
- Validates signal declarations and usage
- Checks emission parameter counts
- Detects undeclared signal emissions

---

## 2026-01-10: Development Tools Batch 12

Added final batch of development tooling:

### Autoload Analyzer (`scripts/analyze_autoloads.py`)
- Lists all autoloads from project.godot
- Detects dependencies between autoloads
- Finds circular dependencies
- Reports unused autoloads

### Input Action Validator (`scripts/validate_inputs.py`)
- Lists all input actions from project.godot
- Finds input action usage in code
- Detects undefined action references
- Reports unused actions

### Run All Checks (`scripts/run_all_checks.py`)
- Master script running all code analysis tools
- Pass/fail thresholds for CI integration
- Quick mode for fast checks only
- JSON/Markdown output formats

---

## 2026-01-10: Development Tools Batch 11

### Export Variable Checker (`scripts/check_exports.py`)
- Validates @export type hints
- Checks for missing default values
- Reports type coverage

### Magic Number Detector (`scripts/find_magic_numbers.py`)
- Finds hardcoded numeric values
- Reports repeated numbers
- Suggests constant names

### Code Health Dashboard (`scripts/health_dashboard.py`)
- Aggregates all quality metrics
- Calculates overall grade (A-F)
- Tracks health history

---

## 2026-01-10: Development Tools Batch 10

### Documentation Coverage Checker (`scripts/check_docs.py`)
- Function and class documentation coverage
- Identifies undocumented public functions
- Coverage breakdown by layer

### Performance Linter (`scripts/lint_performance.py`)
- Detects hot path issues
- Finds nested loops and O(n^2) patterns
- String concatenation warnings

### Memory Leak Detector (`scripts/check_memory.py`)
- Signal connect/disconnect imbalance
- Lambda signal handlers
- Tween cleanup detection

---

## 2026-01-10: Development Tools Batch 9

### Signal Analyzer (`scripts/analyze_signals.py`)
- Signal declarations and connections
- Unused signal detection
- Signals by layer

### Type Checker (`scripts/check_types.py`)
- Function return type coverage
- Parameter type coverage
- Untyped variable detection

### Resource Path Validator (`scripts/validate_paths.py`)
- Validates res:// paths in code
- Detects broken references
- Reference type breakdown

---

## 2026-01-10: Development Tools Batch 8

### TODO/FIXME Tracker (`scripts/track_todos.py`)
- Tracks TODO, FIXME, HACK, BUG comments
- Priority detection
- Health indicators

### Test Coverage Analyzer (`scripts/analyze_test_coverage.py`)
- Coverage by layer
- Untested function priorities
- Test inventory

### Build Info Generator (`scripts/generate_build_info.py`)
- Version and git info
- Build metadata export
- Project statistics
