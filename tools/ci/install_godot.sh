#!/usr/bin/env bash
# Install a headless-capable Godot (Linux x86_64) for CI, optionally with the
# export templates this project needs (Windows x86_64 + Web without threads).
#
# Usage: tools/ci/install_godot.sh [--templates]
# Env:   GODOT_VERSION (default 4.7.2), GODOT_HOME (default $HOME/.godot-ci),
#        XDG_DATA_HOME (Godot looks for export templates below it)
# The binary ends up at $GODOT_HOME/godot.
set -euo pipefail

GODOT_VERSION="${GODOT_VERSION:-4.7.2}"
GODOT_HOME="${GODOT_HOME:-$HOME/.godot-ci}"
BASE_URL="https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}-stable"
TEMPLATE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/${GODOT_VERSION}.stable"
# Only these files of the ~1 GB template archive are needed by export_presets.cfg.
TEMPLATE_FILES=(version.txt windows_release_x86_64.exe web_nothreads_release.zip)

mkdir -p "$GODOT_HOME"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

if [[ ! -x "$GODOT_HOME/godot" ]]; then
    echo "Downloading Godot ${GODOT_VERSION} ..."
    curl -fsSL -o "$tmp/godot.zip" "$BASE_URL/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip"
    unzip -q -o "$tmp/godot.zip" -d "$tmp"
    mv "$tmp/Godot_v${GODOT_VERSION}-stable_linux.x86_64" "$GODOT_HOME/godot"
    chmod +x "$GODOT_HOME/godot"
fi
"$GODOT_HOME/godot" --headless --version

if [[ "${1:-}" == "--templates" ]]; then
    missing=0
    for f in "${TEMPLATE_FILES[@]}"; do
        [[ -f "$TEMPLATE_DIR/$f" ]] || missing=1
    done
    if [[ $missing == 1 ]]; then
        echo "Downloading export templates ${GODOT_VERSION} ..."
        curl -fsSL -o "$tmp/templates.tpz" "$BASE_URL/Godot_v${GODOT_VERSION}-stable_export_templates.tpz"
        mkdir -p "$TEMPLATE_DIR"
        unzip -q -o -j "$tmp/templates.tpz" "${TEMPLATE_FILES[@]/#/templates/}" -d "$TEMPLATE_DIR"
    fi
    ls -l "$TEMPLATE_DIR"
fi
