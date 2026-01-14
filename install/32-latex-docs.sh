#!/usr/bin/env bash
set -euo pipefail

# 32-latex-docs.sh
# Install LaTeX + PDF + doc tools for academic writing.

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "This script must be run as root (via sudo from run-all.sh)." >&2
  exit 1
fi

TARGET_USER="${TARGET_USER:-${SUDO_USER:-}}"
if [[ -z "${TARGET_USER}" || "${TARGET_USER}" == "root" ]]; then
  echo "ERROR: TARGET_USER is not set or is root. Run via run-all.sh, not as pure root." >&2
  exit 1
fi

echo "[32-latex-docs] Installing LaTeX + doc tools..."

pacman --noconfirm --needed -S \
  texlive-most \
  biber \
  pandoc \
  zathura \
  zathura-pdf-mupdf

echo "[32-latex-docs] LaTeX + doc tools installed."
