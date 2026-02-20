#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_PROJECT="$REPO_ROOT/apps/keyboard-defense-monogame/src/KeyboardDefense.Tests/KeyboardDefense.Tests.csproj"

if [[ ! -f "$TEST_PROJECT" ]]; then
  echo "Missing test project: $TEST_PROJECT" >&2
  exit 1
fi

echo "Running MonoGame scenario regression set (xUnit E2E namespace filter)."
dotnet test "$TEST_PROJECT" --configuration Release --filter "FullyQualifiedName~E2E" "$@"
