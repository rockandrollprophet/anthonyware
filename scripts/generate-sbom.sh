#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT_DIR/install/lib/repro.sh"

OUT_DIR="${1:-$ROOT_DIR/sbom}"
repro_generate_sbom "$OUT_DIR"
repro_capture_provenance "$OUT_DIR/provenance.txt"

echo "SBOM written to $OUT_DIR"
