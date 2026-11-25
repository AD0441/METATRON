import sys,time,subprocess,json,shutil,hashlib,statistics,os
from pathlib import Path
from urllib.parse import urlparse,unquote
root=Path(sys.argv[1]);pid=int(sys.argv[2]);span=int(sys.argv[3]) if len(sys.argv)>3 else 1800
sampler=root/'sample'
start=time.monotonic();next_sample=0;batch=0;rows=[];events=[];network=[]
watch={'images':('imagen.png','png'),'office':('form.docx','docx'),'ocr':('escaneado.pdf','pdf'),'audio':('voz.wav','wav')}
originals={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in (root/'input').iterdir() if p.is_file()}
log=(root/'gui-progress.log').open('w',buffering=1)
def progress(msg):print(msg,flush=True);print(msg,file=log,flush=True)
def jobs():
 try:return json.loads((root/'profile/workspace.json').read_text()).get('jobs',[])
 except FileNotFoundError:return []
try:
 while time.monotonic()-start<=span:
  elapsed=time.monotonic()-start
  if batch<10 and elapsed>=30+batch*150:
   batch+=1
   for folder,(name,ext) in watch.items():
    for n in range(5 if folder=='images' else 1):shutil.copyfile(root/'input'/name,root/folder/f'batch-{batch:02}-{n+1}.{ext}')
   events.append({'batch':batch,'elapsed_s':round(elapsed,3)})
   progress(f'Published batch {batch}/10 at {elapsed:.1f}s')
  if elapsed>=next_sample:
   sample=json.loads(subprocess.check_output([str(sampler),str(pid)],text=True));current=jobs()
   sample.update(elapsed_s=round(elapsed,3),jobs=len(current),active=sum(j['state'] in ['running','queued'] for j in current),completed=sum(j['state']=='completed' for j in current),failed=sum(j['state']=='failed' for j in current))
   rows.append(sample);next_sample+=2
   if sample['failed']:raise RuntimeError('Conversion failed: '+str([(j['recipe']['name'],j['message']) for j in current if j['state']=='failed']))
   if batch and elapsed>90 and not current:raise RuntimeError('The isolated app did not receive watched arrivals')
   if len(rows)%15==0:
    progress(f'{elapsed:.0f}s: {sample["completed"]} complete, {sample["active"]} active; RSS {sample["rss_bytes"]/1048576:.1f} MiB, footprint {sample["footprint_bytes"]/1048576:.1f} MiB')
    (root/'gui-samples-live.json').write_text(json.dumps({'pid':pid,'samples':rows,'batches':events},indent=2))
   if len(rows)%5==0:
    sockets=subprocess.run(['/usr/sbin/lsof','-nP','-a','-p',str(pid),'-i'],capture_output=True,text=True)
    if sockets.returncode==0 and sockets.stdout.strip():network.append({'elapsed_s':round(elapsed,3),'sockets':sockets.stdout})
  time.sleep(0.2)
 current=jobs();assert len(current)==80 and all(j['state']=='completed' for j in current),(len(current),'Not all 80 jobs completed')
 count=0
 for job in current:
  for item in job['outputs']:
   p=Path(unquote(urlparse(item['url']).path));assert p.is_file() and hashlib.sha256(p.read_bytes()).hexdigest()==item['digest'];count+=1
 for folder,(name,ext) in watch.items():
  expected=originals[name]
  assert all(hashlib.sha256(p.read_bytes()).hexdigest()==expected for p in (root/folder).iterdir() if p.is_file())
 assert originals=={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in (root/'input').iterdir() if p.is_file()}
 def window(a,b):
  rs=[x for x in rows if a<=x['elapsed_s']<=b]
  return {'samples':len(rs),'rss_median_bytes':statistics.median(x['rss_bytes'] for x in rs),'footprint_median_bytes':statistics.median(x['footprint_bytes'] for x in rs),'cpu_mean_percent':100*(rs[-1]['cpu_ns']-rs[0]['cpu_ns'])/1e9/(rs[-1]['elapsed_s']-rs[0]['elapsed_s'])}
 summary={'duration_s':rows[-1]['elapsed_s'],'batches':batch,'jobs_completed':len(current),'published_files_verified':count,'source_hashes_preserved':True,'lifetime_peak_footprint_bytes':max(x['max_footprint_bytes'] for x in rows),'peak_rss_bytes':max(x['rss_bytes'] for x in rows),'peak_footprint_bytes':max(x['footprint_bytes'] for x in rows),'idle_last_60s':window(span-61,span),'cooldown_after_last_batch':window(1530,1590),'final_cooldown':window(span-121,span),'own_process_network_socket_observations':len(network)}
 (root/'gui-results.json').write_text(json.dumps({'summary':summary,'samples':rows,'batches':events,'network':network},indent=2))
 progress('COMPLETE '+json.dumps(summary))
except BaseException as e:
 (root/'gui-failure.json').write_text(json.dumps({'error':str(e),'samples':rows,'batches':events},indent=2));raise
finally:log.close()
