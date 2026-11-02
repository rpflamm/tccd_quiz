#!/usr/bin/env bash
# Export the Windows and Web builds and package them as release assets in dist/:
#   dist/TCCD-Quizz-<version>-windows-portable.exe
#   dist/TCCD-Quizz-<version>-web.zip   (index.html at the top level, ready for itch.io)
#
# Usage: tools/ci/export_release.sh [version]
#   version  e.g. "v1.2.0" or "1.2.0". When given, it is written into project.godot
#            and the Windows file/product version before exporting. Without it the
#            version from project.godot is used and no file is changed.
# Env:   GODOT (default: godot)
set -euo pipefail

GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/../.."

version="${1:-}"
version="${version#v}"
if [[ -n "$version" ]]; then
    if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Version must look like 1.2.3 or v1.2.3, got '$1'" >&2
        exit 1
    fi
    sed -i.bak "s/^config\/version=.*/config\/version=\"$version\"/" project.godot
    sed -i.bak -E "s/^application\/(file|product)_version=.*/application\/\1_version=\"$version.0\"/" export_presets.cfg
    rm -f project.godot.bak export_presets.cfg.bak
else
    version="$(sed -n 's/^config\/version="\(.*\)"/\1/p' project.godot)"
fi
echo "Exporting version $version"

rm -rf export/windows export/web dist
mkdir -p export/windows export/web dist

"$GODOT" --headless --path . --import
"$GODOT" --headless --path . --export-release "Windows Desktop" "export/windows/TCCD Quizz.exe"
"$GODOT" --headless --path . --export-release "Web" export/web/index.html

# Godot can report export errors without a non-zero exit code, so check the results.
for f in "export/windows/TCCD Quizz.exe" export/web/index.html export/web/index.pck export/web/index.wasm; do
    [[ -s "$f" ]] || { echo "Export failed: $f is missing" >&2; exit 1; }
done

cp "export/windows/TCCD Quizz.exe" "dist/TCCD-Quizz-${version}-windows-portable.exe"
(cd export/web && zip -q -9 -r "../../dist/TCCD-Quizz-${version}-web.zip" .)
if command -v sha256sum >/dev/null; then sha="sha256sum"; else sha="shasum -a 256"; fi
(cd dist && $sha TCCD-Quizz-* > SHA256SUMS.txt)
ls -l dist
