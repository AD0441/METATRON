#!/usr/bin/env bash
# Verify the actual ZIP outside Desktop/File Provider metadata, without launching UI.
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZIP_PATH="${1:-$ROOT_DIR/dist/METATRON.zip}"
VERIFY_DIR="$(mktemp -d "${TMPDIR:-/tmp}/metatron-verify.XXXXXX")"
trap 'rm -rf "$VERIFY_DIR"' EXIT
/usr/bin/ditto -x -k "$ZIP_PATH" "$VERIFY_DIR"
APP_BUNDLE="$VERIFY_DIR/METATRON.app"
/usr/bin/codesign --verify --deep --strict "$APP_BUNDLE"
/usr/bin/codesign --verify --strict "$APP_BUNDLE/Contents/MacOS/metatron-cli"
/usr/bin/python3 - "$APP_BUNDLE" "$ROOT_DIR/Resources/Info.plist" <<'CHECK'
import json,plistlib,sys
from pathlib import Path
app=Path(sys.argv[1]);expected=plistlib.loads(Path(sys.argv[2]).read_bytes());info=plistlib.loads((app/'Contents/Info.plist').read_bytes())
for key in ('CFBundleIdentifier','CFBundleShortVersionString','CFBundleVersion','LSMinimumSystemVersion','LSMultipleInstancesProhibited'):
    if info.get(key)!=expected.get(key):raise SystemExit('Package metadata mismatch: '+key)
for name in ('AppIcon.icns','LICENSE'):
    if not (app/'Contents/Resources'/name).is_file():raise SystemExit('Missing resource: '+name)
metadata=app/'Contents/Resources/Metadata.appintents/extract.actionsdata'
if not metadata.is_file():raise SystemExit('Missing extracted App Intents metadata')
actions=json.loads(metadata.read_text()).get('actions',{})
for action in ('OpenMetatronIntent','PrepareFilesIntent','RunRecipeIntent'):
    if action not in actions:raise SystemExit('Missing App Intent: '+action)
print('METATRON '+info['CFBundleShortVersionString']+' build '+info['CFBundleVersion']+'; metadata and three App Intents verified')
CHECK
HOST_ARCH="$(uname -m)"
for executable in METATRON metatron-cli; do
  /usr/bin/lipo "$APP_BUNDLE/Contents/MacOS/$executable" -verify_arch "$HOST_ARCH"
done
# Test a real conversion from the distributed CLI; originals must remain unchanged.
mkdir "$VERIFY_DIR/input" "$VERIFY_DIR/output"
printf 'Nombre,Estado\nMuestra,Listo\n' > "$VERIFY_DIR/input/sample.csv"
"$APP_BUNDLE/Contents/MacOS/metatron-cli" convert "$VERIFY_DIR/input/sample.csv" --to md -o "$VERIFY_DIR/output" >/dev/null
/usr/bin/python3 - "$VERIFY_DIR" <<'CHECK'
import hashlib,json,sys
from urllib.parse import urlparse,unquote
from pathlib import Path
root=Path(sys.argv[1]);outputs=list((root/'output').glob('*.md'));receipts=list((root/'output').glob('metatron-*.json'))
if len(outputs)!=1 or len(receipts)!=1:raise SystemExit('CLI did not publish Markdown and receipt')
if 'Muestra' not in outputs[0].read_text():raise SystemExit('Markdown lost fixture content')
if (root/'input/sample.csv').read_bytes()!=b'Nombre,Estado\nMuestra,Listo\n':raise SystemExit('CLI modified its input')
files=json.loads(receipts[0].read_text())
if not files:raise SystemExit('Empty receipt')
for item in files:
    path=Path(unquote(urlparse(item['url']).path))
    if hashlib.sha256(path.read_bytes()).hexdigest()!=item['digest']:raise SystemExit('Receipt hash mismatch')
print('Distributed CLI: CSV to Markdown; input preserved; receipt generated')
CHECK
# Watch startup must fail, rather than hang, for unavailable inputs.
if "$APP_BUNDLE/Contents/MacOS/metatron-cli" watch "$VERIFY_DIR/missing" --to jpg >/dev/null 2>&1; then
  echo 'CLI accepted a missing watch folder' >&2; exit 1
fi
# A terminal interrupt must cancel the watcher rather than abandon it.
/usr/bin/python3 - "$APP_BUNDLE/Contents/MacOS/metatron-cli" "$VERIFY_DIR/input" <<'CHECK'
import select,signal,subprocess,sys,time
from pathlib import Path
folder=Path(sys.argv[2]);destination=folder.parent/'watch-output'
p=subprocess.Popen([sys.argv[1],'watch',str(folder),'--to','md','-o',str(destination)],stdout=subprocess.PIPE,stderr=subprocess.PIPE)
try:
    if not select.select([p.stdout],[],[],5)[0]:raise SystemExit('Watcher did not become ready')
    if not p.stdout.readline().startswith(b'Vigilando'):raise SystemExit('Watcher startup failed')
    source=folder/'watched.csv';source.write_text('Nombre,Estado\nAutomatizado,Listo\n')
    limit=time.monotonic()+10
    while time.monotonic()<limit and not list(destination.glob('*.md')):time.sleep(0.05)
    result=list(destination.glob('*.md'))
    if len(result)!=1 or 'Automatizado' not in result[0].read_text():raise SystemExit('Distributed watcher did not convert its arrival')
    p.send_signal(signal.SIGINT)
    _,err=p.communicate(timeout=5)
    if p.returncode!=130:raise SystemExit('CLI interrupt failed: '+str(p.returncode)+' '+err.decode())
finally:
    if p.poll() is None:p.kill();p.wait()
print('Distributed CLI: watched CSV converted; Ctrl+C stopped intake cleanly')
CHECK
if [[ "${METATRON_REQUIRE_TEAM_ID:-0}" == 1 ]]; then
  DETAILS="$(/usr/bin/codesign -d --verbose=4 "$APP_BUNDLE" 2>&1)"
  if ! /usr/bin/grep -Eq '^TeamIdentifier=[A-Z0-9]{10}$' <<< "$DETAILS"; then
    echo 'Apple signing identity/Team ID required for native Shortcuts validation' >&2; exit 1
  fi
fi
/usr/bin/shasum -a 256 "$ZIP_PATH"
echo 'Package verification passed'
