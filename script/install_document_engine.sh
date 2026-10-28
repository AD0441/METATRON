#!/usr/bin/env bash
set -euo pipefail
ENGINE_ID="${1:-markitdown}"
case "$ENGINE_ID" in markitdown) PACKAGE_SPEC='markitdown[pdf,docx,xlsx]==0.1.9';; docling) PACKAGE_SPEC='docling';; *) echo 'Uso: install_document_engine.sh [markitdown|docling]' >&2; exit 2;; esac
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PYTHON_BIN="${METATRON_PYTHON:-/opt/homebrew/bin/python3.11}"
"$PYTHON_BIN" -c 'import sys; assert (3,10) <= sys.version_info[:2] <= (3,14), "Requiere Python 3.10–3.14"'
"$PYTHON_BIN" -m venv "$ROOT_DIR/.engines/$ENGINE_ID"
"$ROOT_DIR/.engines/$ENGINE_ID/bin/python" -m pip install "$PACKAGE_SPEC"
echo "Motor opcional: $ROOT_DIR/.engines/$ENGINE_ID/bin/$ENGINE_ID"
