from pathlib import Path
import subprocess,json,threading,http.server,hashlib,time
import sys
r=Path(sys.argv[1]);cli=Path(sys.argv[2]);policy='(version 1)(allow default)(deny network*)'
class Handler(http.server.BaseHTTPRequestHandler):
 def do_GET(self):self.send_response(200);self.end_headers();self.wfile.write(b'local control')
 def log_message(self,*args):pass
server=http.server.ThreadingHTTPServer(('127.0.0.1',0),Handler);threading.Thread(target=server.serve_forever,daemon=True).start()
url=f'http://127.0.0.1:{server.server_port}'
allowed=subprocess.run(['/usr/bin/curl','--noproxy','*','-fsS',url],capture_output=True)
denied=subprocess.run(['/usr/bin/sandbox-exec','-p',policy,'/usr/bin/curl','--noproxy','*','-fsS','--connect-timeout','2',url],capture_output=True)
assert allowed.returncode==0 and denied.returncode!=0,'Network negative control failed'
server.shutdown()
(root:=r/'offline').mkdir(exist_ok=True)
source={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in (r/'input').iterdir() if p.is_file()}
cases=[('image',['convert',str(r/'input/imagen.png'),'--to','jpg']),('table',['convert',str(r/'input/tabla.csv'),'--to','md']),('pdf',['convert',str(r/'input/texto.pdf'),'--to','md']),('office',['convert',str(r/'input/form.docx'),'--to','pdf']),('speech',['transcribe',str(r/'input/voz.wav'),'--locale','es-CL'])]
# Wait for the graphical queue to be idle, keeping independent heavy jobs apart.
for _ in range(180):
 try:jobs=json.loads((r/'profile/workspace.json').read_text()).get('jobs',[])
 except FileNotFoundError:jobs=[]
 if jobs and not any(j['state'] in ['running','queued'] for j in jobs):break
 time.sleep(1)
else:raise RuntimeError('GUI queue did not become idle')
rows=[]
for name,args in cases:
 out=root/name;t=time.monotonic()
 p=subprocess.run(['/usr/bin/sandbox-exec','-p',policy,str(cli),*args,'-o',str(out)],capture_output=True,text=True,timeout=120)
 (root/(name+'.stderr')).write_text(p.stderr)
 row={'case':name,'exit':p.returncode,'seconds':round(time.monotonic()-t,4),'outputs':sorted(f.name for f in out.iterdir()) if out.exists() else []};rows.append(row);print(row,flush=True)
 if name == 'office' and p.returncode != 0 and 'sandbox initialization failed' in p.stderr:
  control=subprocess.run(['/usr/bin/sandbox-exec','-p','(version 1)(allow default)',str(cli),*args,'-o',str(root/'office-control')],capture_output=True,text=True,timeout=120)
  assert control.returncode!=0 and 'sandbox initialization failed' in control.stderr, 'Office needs separate investigation; allow-default control differed'
  row['status']='not_executed_nested_sandbox_unsupported'
  row['allow_default_control_failed']=True
  continue
 assert p.returncode==0,(name,p.stderr)
 for receipt in out.glob('metatron-*.json'):
  from urllib.parse import urlparse,unquote
  for entry in json.loads(receipt.read_text()):assert hashlib.sha256(Path(unquote(urlparse(entry['url']).path)).read_bytes()).hexdigest()==entry['digest']
assert source=={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in (r/'input').iterdir() if p.is_file()}
(root/'results.json').write_text(json.dumps({'network_denial_control':True,'policy':policy,'office_nested_sandbox_control':'qlmanage also fails with allow-default outer policy; see report','cases':rows,'source_hashes_preserved':True},indent=2))
print('Supported offline cases and network-denial control passed; inspect per-case status',flush=True)
