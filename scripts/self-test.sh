#!/usr/bin/env bash
set -euo pipefail

# self-test.sh - lightweight wrapper to run the test framework if available
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_RUNNER="$ROOT_DIR/tests/test-framework.sh"

if [[ -x "$TEST_RUNNER" ]]; then
  echo "[SELF-TEST] Running $TEST_RUNNER"
  bash "$TEST_RUNNER"
else
  echo "[SELF-TEST] Test framework not found at $TEST_RUNNER; skipping"
fi
