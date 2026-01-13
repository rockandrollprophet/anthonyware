#!/usr/bin/env bash
set -euo pipefail

echo "=== Anthonyware: Update Everything ==="

bash "$(dirname "$0")/../install/99-update-everything.sh"

echo "=== Update Complete ==="
