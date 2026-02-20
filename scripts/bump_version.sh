#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VERSION_PATH="$REPO_ROOT/apps/keyboard-defense-monogame/VERSION.txt"
DEFAULT_VERSION="0.1.0"

read_version() {
  if [[ -f "$VERSION_PATH" ]]; then
    local value
    value="$(head -n 1 "$VERSION_PATH" | tr -d '\r\n')"
    if [[ -n "$value" ]]; then
      echo "$value"
      return
    fi
  fi
  echo "$DEFAULT_VERSION"
}

parse_semver() {
  local v="$1"
  [[ "$v" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]
}

CURRENT_VERSION="$(read_version)"

if [[ $# -eq 0 ]]; then
  echo "Current version: $CURRENT_VERSION"
  echo "Usage:"
  echo "  bash ./scripts/bump_version.sh set <version>"
  echo "  bash ./scripts/bump_version.sh apply <version>"
  echo "  bash ./scripts/bump_version.sh patch|minor|major"
  echo "  bash ./scripts/bump_version.sh apply patch|minor|major"
  exit 0
fi

MODE="$1"
TARGET_VERSION=""
INCREMENT_MODE=""

if [[ "$MODE" == "set" ]]; then
  [[ $# -ge 2 ]] || { echo "ERROR: Missing version for set." >&2; exit 1; }
  TARGET_VERSION="$2"
elif [[ "$MODE" == "apply" ]]; then
  [[ $# -ge 2 ]] || { echo "ERROR: Missing value for apply." >&2; exit 1; }
  case "$2" in
    patch|minor|major) INCREMENT_MODE="$2" ;;
    *) TARGET_VERSION="$2" ;;
  esac
elif [[ "$MODE" == "patch" || "$MODE" == "minor" || "$MODE" == "major" ]]; then
  INCREMENT_MODE="$MODE"
else
  echo "ERROR: Unknown mode: $MODE" >&2
  exit 1
fi

if [[ -n "$INCREMENT_MODE" ]]; then
  if ! parse_semver "$CURRENT_VERSION"; then
    echo "ERROR: Current version is not semver: $CURRENT_VERSION" >&2
    exit 1
  fi
  MAJOR="${BASH_REMATCH[1]}"
  MINOR="${BASH_REMATCH[2]}"
  PATCH="${BASH_REMATCH[3]}"
  case "$INCREMENT_MODE" in
    patch) PATCH=$((PATCH + 1)) ;;
    minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
    major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
  esac
  TARGET_VERSION="${MAJOR}.${MINOR}.${PATCH}"
fi

if ! parse_semver "$TARGET_VERSION"; then
  echo "ERROR: Invalid semver: $TARGET_VERSION" >&2
  exit 1
fi

if [[ "$MODE" == "set" || "$MODE" == "patch" || "$MODE" == "minor" || "$MODE" == "major" ]]; then
  echo "VERSION.txt: $CURRENT_VERSION -> $TARGET_VERSION"
  echo "Preview only. Use apply to write."
  exit 0
fi

mkdir -p "$(dirname "$VERSION_PATH")"
printf '%s\n' "$TARGET_VERSION" > "$VERSION_PATH"
echo "Updated VERSION.txt to $TARGET_VERSION"
