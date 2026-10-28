#!/usr/bin/env bash
set -euo pipefail
MODE="${1:-run}"
APP_NAME="METATRON"
BUNDLE_ID="local.metatron.app"
BUILD_CONFIGURATION="${METATRON_BUILD_CONFIGURATION:-release}"
if [[ "$MODE" == --debug ]]; then BUILD_CONFIGURATION=debug; fi
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
# SDK 27 SwiftUI macros require the full Xcode installation, not the CLT SDK.
if [[ -d /Applications/Xcode.app/Contents/Developer ]]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
case "$MODE" in run|--verify|--build-only|--debug|--logs|--telemetry) ;; *) echo "Uso: $0 [--verify|--build-only|--debug|--logs|--telemetry]" >&2; exit 2;; esac
if [[ "$MODE" != --build-only ]]; then pkill -x "$APP_NAME" >/dev/null 2>&1 || true; fi
xcrun swift build --build-system native --configuration "$BUILD_CONFIGURATION" -j 4
BUILD_DIR="$(xcrun swift build --build-system native --configuration "$BUILD_CONFIGURATION" --show-bin-path)"
PACKAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/metatron-package.XXXXXX")"
trap 'rm -rf "$PACKAGING_DIR"' EXIT
APP_BUNDLE="$PACKAGING_DIR/$APP_NAME.app"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "$BUILD_DIR/metatron-cli" "$APP_BUNDLE/Contents/MacOS/metatron-cli"
cp "$ROOT_DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
cp "$ROOT_DIR/LICENSE" "$APP_BUNDLE/Contents/Resources/LICENSE"
/usr/bin/python3 - "$ROOT_DIR" "$APP_BUNDLE" <<'PY'
import plistlib,sys
from pathlib import Path
root,bundle=map(Path,sys.argv[1:])
p=plistlib.loads((root/'Resources/Info.plist').read_bytes())
for k in ('CFBundleName','CFBundleDisplayName','CFBundleExecutable'): p[k]='METATRON'
p['NSHumanReadableCopyright']='Creado por Sebastián Pastén F. · Base Kumquat © 2026 iandifilippo, MIT'
p.update(CFBundleIdentifier='local.metatron.app',CFBundleShortVersionString='2.0.0',CFBundleVersion='2',LSUIElement=False,NSPrincipalClass='NSApplication',CFBundleDevelopmentRegion='es')
p['NSLocalNetworkUsageDescription']='Comparte el archivo que eliges con otro dispositivo de tu red local.'
p['NSAppleEventsUsageDescription']='Metatron puede leer la selección de Finder cuando usas su atajo.'
p['NSServices'][0]['NSMenuItem']['default']='Convertir con Metatron'
p['NSServices'][0]['NSPortName']='Metatron'
(bundle/'Contents/Info.plist').write_bytes(plistlib.dumps(p))
PY
# Finder/File Provider can attach these non-code attributes to a generated Desktop bundle.
# Remove only signing-prohibited metadata; preserve quarantine/provenance and all other attributes.
/usr/bin/xattr -dr com.apple.FinderInfo "$APP_BUNDLE" 2>/dev/null || true
/usr/bin/xattr -dr com.apple.ResourceFork "$APP_BUNDLE" 2>/dev/null || true
/usr/bin/codesign --force --deep --sign - "$APP_BUNDLE"
/usr/bin/codesign --verify --deep --strict "$APP_BUNDLE"
mkdir -p "$ROOT_DIR/dist"
/usr/bin/ditto -c -k --keepParent --norsrc --noextattr "$APP_BUNDLE" "$ROOT_DIR/dist/$APP_NAME.zip"
/usr/bin/ditto "$APP_BUNDLE" "$ROOT_DIR/dist/$APP_NAME.app"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
/usr/bin/xattr -dr com.apple.FinderInfo "$APP_BUNDLE" 2>/dev/null || true
/usr/bin/xattr -dr com.apple.ResourceFork "$APP_BUNDLE" 2>/dev/null || true
if [[ "$MODE" == --build-only ]]; then echo "$APP_BUNDLE"; exit 0; fi
case "$MODE" in
 --debug) xcrun lldb -- "$APP_BUNDLE/Contents/MacOS/$APP_NAME";;
 --verify) /usr/bin/open -n "$APP_BUNDLE"; sleep 2; pgrep -x "$APP_NAME" >/dev/null; echo "Metatron abierto y en ejecución";;
 --logs) /usr/bin/open -n "$APP_BUNDLE"; /usr/bin/log stream --info --style compact --predicate 'process == "Metatron"';;
 --telemetry) /usr/bin/open -n "$APP_BUNDLE"; /usr/bin/log stream --info --style compact --predicate 'subsystem == "local.metatron.app"';;
 *) /usr/bin/open -n "$APP_BUNDLE";;
esac
