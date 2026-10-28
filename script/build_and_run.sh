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
python3 "$ROOT_DIR/script/generate_xcode_project.py"
# Build the app with Xcode so App Intents metadata is extracted. Read the project
# outside Desktop/File Provider coordination, keeping the user's sources in place.
XCODE_SOURCE="$(mktemp -d "${TMPDIR:-/tmp}/metatron-xcode.XXXXXX")"
PACKAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/metatron-package.XXXXXX")"
trap 'rm -rf "$PACKAGING_DIR" "$XCODE_SOURCE"' EXIT
for folder in Sources Tests Resources METATRON.xcodeproj; do
  /usr/bin/ditto "$ROOT_DIR/$folder" "$XCODE_SOURCE/$folder"
done
cp "$ROOT_DIR/Package.swift" "$ROOT_DIR/LICENSE" "$XCODE_SOURCE/"
XCODE_CONFIGURATION=Release
if [[ "$BUILD_CONFIGURATION" == debug ]]; then XCODE_CONFIGURATION=Debug; fi
xcodebuild -project "$XCODE_SOURCE/METATRON.xcodeproj" -scheme METATRON -destination "platform=macOS,arch=$(uname -m)" -configuration "$XCODE_CONFIGURATION" -derivedDataPath "$ROOT_DIR/.build/xcode" -jobs 4 CODE_SIGNING_ALLOWED=NO build
xcrun swift build --build-system native --configuration "$BUILD_CONFIGURATION" --product metatron-cli -j 4
BUILD_DIR="$(xcrun swift build --build-system native --configuration "$BUILD_CONFIGURATION" --show-bin-path)"
APP_BUNDLE="$PACKAGING_DIR/$APP_NAME.app"
/usr/bin/ditto "$ROOT_DIR/.build/xcode/Build/Products/$XCODE_CONFIGURATION/$APP_NAME.app" "$APP_BUNDLE"
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
p.update(CFBundleIdentifier='local.metatron.app',LSUIElement=False,NSPrincipalClass='NSApplication',CFBundleDevelopmentRegion='es')
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
SIGN_IDENTITY="${METATRON_SIGN_IDENTITY:--}"
if [[ "$SIGN_IDENTITY" == - ]]; then
  /usr/bin/codesign --force --deep --sign - "$APP_BUNDLE"
else
  /usr/bin/codesign --force --timestamp --options runtime --sign "$SIGN_IDENTITY" "$APP_BUNDLE/Contents/MacOS/metatron-cli"
  /usr/bin/codesign --force --deep --timestamp --options runtime --sign "$SIGN_IDENTITY" "$APP_BUNDLE"
fi
/usr/bin/codesign --verify --deep --strict "$APP_BUNDLE"
mkdir -p "$ROOT_DIR/dist"
/usr/bin/ditto -c -k --keepParent --norsrc --noextattr "$APP_BUNDLE" "$ROOT_DIR/dist/$APP_NAME.zip"
/usr/bin/ditto "$APP_BUNDLE" "$ROOT_DIR/dist/$APP_NAME.app"
"$ROOT_DIR/script/verify_package.sh" "$ROOT_DIR/dist/$APP_NAME.zip"
(cd "$ROOT_DIR/dist" && /usr/bin/shasum -a 256 "$APP_NAME.zip" > SHA256SUMS.txt)
# Xcode's intermediate unsigned copy must not compete with the distributed app
# in Launch Services / Shortcuts discovery after a local build.
LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
"$LSREGISTER" -u "$ROOT_DIR/.build/xcode/Build/Products/$XCODE_CONFIGURATION/$APP_NAME.app" >/dev/null 2>&1 || true
"$LSREGISTER" -f "$ROOT_DIR/dist/$APP_NAME.app" >/dev/null 2>&1 || true
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
/usr/bin/xattr -dr com.apple.FinderInfo "$APP_BUNDLE" 2>/dev/null || true
/usr/bin/xattr -dr com.apple.ResourceFork "$APP_BUNDLE" 2>/dev/null || true
if [[ "$MODE" == --build-only ]]; then echo "$APP_BUNDLE"; exit 0; fi
case "$MODE" in
 --debug) xcrun lldb -- "$APP_BUNDLE/Contents/MacOS/$APP_NAME";;
 --verify) /usr/bin/open "$APP_BUNDLE"; sleep 2; pgrep -x "$APP_NAME" >/dev/null; echo "Metatron abierto y en ejecución";;
 --logs) /usr/bin/open "$APP_BUNDLE"; /usr/bin/log stream --info --style compact --predicate 'process == "METATRON"';;
 --telemetry) /usr/bin/open "$APP_BUNDLE"; /usr/bin/log stream --info --style compact --predicate 'subsystem == "local.metatron.app"';;
 *) /usr/bin/open "$APP_BUNDLE";;
esac
