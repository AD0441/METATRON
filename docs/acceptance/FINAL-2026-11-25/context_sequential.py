from pathlib import Path
import subprocess,os,pty,select,json,re,time,statistics
import sys
r=Path(sys.argv[1]);pid=int((r/'app-pid').read_text());files=sorted(str(p) for p in (r/'context-files').glob('*.png'));assert len(files)==50
master,slave=pty.openpty();logs=subprocess.Popen(['/usr/bin/log','stream','--style','ndjson','--predicate',f'processIdentifier == {pid} AND category == "context-timing"'],stdout=slave,stderr=slave);os.close(slave)
values=[];buffer=b'';events=[]
try:
 time.sleep(1)
 for n in range(31):
  subprocess.run(['/usr/bin/open','-a',str(r/'METATRON-Validation.app'),*files],check=True)
  deadline=time.monotonic()+35;found=False
  while time.monotonic()<deadline and not found:
   if not select.select([master],[],[],0.5)[0]:continue
   buffer+=os.read(master,65536)
   while b'\n' in buffer:
    line,buffer=buffer.split(b'\n',1)
    try:event=json.loads(line)
    except (ValueError,UnicodeError):continue
    message=event.get('eventMessage','');match=re.search(r'files=50 milliseconds=([0-9.]+)',message)
    if match:
     value=float(match[1]);values.append(value);events.append(event);print(n,value,flush=True);found=True;break
  if not found:raise RuntimeError('No presentation completion event')
  time.sleep(1)
 warm=sorted(values[1:]);result={'files':50,'repetitions':30,'first_sequential_request_ms':values[0],'p50_ms':statistics.median(warm),'p95_ms':warm[28],'max_ms':max(warm),'samples_ms':values,'endpoint':'RingController entry to presentation request/model reveal, excluding compositor/display latency','sequential':True,'settling_seconds':1}
 (r/'context-sequential-results.json').write_text(json.dumps(result,indent=2));print('COMPLETE',json.dumps(result),flush=True)
finally:
 logs.terminate();logs.wait(timeout=5);os.close(master)
 (r/'context-sequential-events.json').write_text(json.dumps(events,indent=2))
