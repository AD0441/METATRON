#!/usr/bin/env bash
# Opt-in integration test: synthetic audio only; never installs models or voices.
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLI="${1:-$ROOT_DIR/dist/METATRON.app/Contents/MacOS/metatron-cli}"
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/metatron-speech-test.XXXXXX")"
trap 'rm -rf "$TEST_DIR"' EXIT
"$CLI" speech-status --locale es-CL > "$TEST_DIR/status.json"
/usr/bin/python3 - "$TEST_DIR/status.json" <<'PY'
import json,sys
state=json.load(open(sys.argv[1]))
if not state['installed']:
    print('SKIP: Apple Speech es-CL is not installed; no download requested')
    raise SystemExit(77)
PY
/usr/bin/say -v '?' > "$TEST_DIR/voices.txt"
if ! /usr/bin/grep -q '^Paulina' "$TEST_DIR/voices.txt"; then echo 'SKIP: synthetic test voice Paulina is not installed'; exit 77; fi
/usr/bin/say -v Paulina -o "$TEST_DIR/source.aiff" 'Hola. Esta es una prueba de transcripción local. La reunión comienza a las diez de la mañana.'
"$CLI" transcribe "$TEST_DIR/source.aiff" --to txt --locale es-CL -o "$TEST_DIR/txt" >/dev/null
"$CLI" transcribe "$TEST_DIR/source.aiff" --to md --locale es-CL -o "$TEST_DIR/md" >/dev/null
/usr/bin/afconvert -f WAVE -d LEI16 "$TEST_DIR/source.aiff" "$TEST_DIR/short.wav"
/usr/bin/python3 - "$CLI" "$TEST_DIR" <<'PY'
import hashlib,json,signal,subprocess,sys,time,wave
from pathlib import Path
cli,root=sys.argv[1],Path(sys.argv[2])
for ext in ('txt','md'):
    paths=list((root/ext).glob('*.'+ext))
    assert len(paths)==1
    text=paths[0].read_text()
    assert 'prueba' in text.lower() and 'reunión' in text.lower()
    assert list((root/ext).glob('metatron-*.json'))
with wave.open(str(root/'short.wav'),'rb') as short:
    frames=short.readframes(short.getnframes());params=short.getparams()
with wave.open(str(root/'long.wav'),'wb') as long:
    long.setparams(params)
    for _ in range(60):long.writeframes(frames)
source=root/'long.wav';before=hashlib.sha256(source.read_bytes()).hexdigest()
p=subprocess.Popen([cli,'transcribe',str(source),'--to','txt','--locale','es-CL','-o',str(root/'cancel')],stdout=subprocess.PIPE,stderr=subprocess.PIPE)
try:
    time.sleep(1);p.send_signal(signal.SIGINT)
    p.communicate(timeout=15)
    assert p.returncode==130
    assert not (root/'cancel').exists() or not list((root/'cancel').iterdir())
    assert hashlib.sha256(source.read_bytes()).hexdigest()==before
finally:
    if p.poll() is None:p.kill();p.wait()
print('Apple Speech: TXT and Markdown verified; cancellation preserved the input and published no partial result')
PY
