# .claude/ - AI Development Context Directory

This directory contains persistent context files for Claude Code sessions. These files help maintain continuity between development sessions and track important state that should persist.

## Files

### CURRENT_TASK.md
What's currently being worked on. Update this at the start of each session and when switching tasks. Helps Claude Code resume work quickly.

### RECENT_CHANGES.md
Summary of recent changes made by Claude Code. Update after completing significant work. Helps track what was done and provides context for related future work.

### DECISIONS.md
Architecture and design decisions made during development. Record the decision, rationale, and date. Prevents re-debating settled questions.

### KNOWN_ISSUES.md
Known bugs, limitations, quirks, and edge cases. Not a bug tracker, but a place for gotchas that need awareness during development.

### BLOCKED.md
Current blockers and dependencies. Things that can't be done yet and why.

## Usage

Claude Code should:
1. Read relevant files at session start for context
2. Update files after completing significant work
3. Check KNOWN_ISSUES.md before implementing features that might hit known edge cases
4. Record important decisions in DECISIONS.md

The user should:
1. Update CURRENT_TASK.md to direct Claude Code's focus
2. Clear outdated entries periodically
3. Review DECISIONS.md before requesting changes that might conflict
