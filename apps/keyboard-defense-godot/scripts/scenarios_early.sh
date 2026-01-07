#!/usr/bin/env bash
set -euo pipefail

echo "Delegating to scripts/scenarios_early.sh"
REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "${REPO_ROOT}"
set +e
"./scripts/scenarios_early.sh" "$@"
exit_code=$?
set -e
exit "${exit_code}"