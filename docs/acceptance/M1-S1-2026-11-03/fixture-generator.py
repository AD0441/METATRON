from pathlib import Path
import csv, json, uuid, hashlib, zipfile, shutil, subprocess, wave, plistlib, sys
root=Path(sys.argv[1]); inp=root/'input'; inp.mkdir(exist_ok=True)
(inp/'notas.txt').write_text('METATRON: reunión de mañana. Año 2026. Información conservada.\n')
(inp/'tabla.csv').write_text('Nombre,Valor\n"Reunión, mañana",42\nAño,2026\n')
(inp/'danado.png').write_bytes(b'NOT_A_PNG: synthetic corrupt input')
content_types='''<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/></Types>'''
parts={'[Content_Types].xml':content_types,'_rels/.rels':'<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>','xl/workbook.xml':'<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="Datos" sheetId="1" r:id="rId1"/></sheets></workbook>','xl/_rels/workbook.xml.rels':'<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/></Relationships>','xl/worksheets/sheet1.xml':'<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData><row r="1"><c r="A1" t="inlineStr"><is><t>Nombre</t></is></c><c r="B1" t="inlineStr"><is><t>Valor</t></is></c></row><row r="2"><c r="A2" t="inlineStr"><is><t>Reunión</t></is></c><c r="B2"><v>42</v></c></row><row r="3"><c r="A3" t="inlineStr"><is><t>Año</t></is></c><c r="B3"><v>2026</v></c></row></sheetData></worksheet>'}
with zipfile.ZipFile(inp/'tabla.xlsx','w',zipfile.ZIP_DEFLATED) as z:
 for name,text in parts.items():z.writestr(name,text)
def recipe(name,actions,out):
 return {'id':str(uuid.uuid4()),'name':name,'steps':[{'id':str(uuid.uuid4()),'action':a,'number':800,'text':''} for a in actions],'suffix':'-m1','quality':0.85,'preserveMetadata':True,'folderPath':str(root/out)}
for name,actions,out in [('M1 Legacy imagen',['resize','convert.jpg','tool.stripMetadata'],'recipe-output'),('M1 Invalida',['resize'],'invalid-output')]:
 (root/(name+'.json')).write_text(json.dumps(recipe(name,actions,out),ensure_ascii=False,indent=2))
voices=subprocess.check_output(['/usr/bin/say','-v','?'],text=True)
if any(l.startswith('Paulina ') for l in voices.splitlines()):
 subprocess.run(['/usr/bin/say','-v','Paulina','-o',str(inp/'voz.aiff'),'Hola. Esta es una prueba de transcripción local. La reunión comienza a las diez de la mañana. El proyecto Metatron conserva el archivo original.'],check=True)
 subprocess.run(['/usr/bin/afconvert','-f','WAVE','-d','LEI16','-r','16000','-c','1',str(inp/'voz.aiff'),str(inp/'voz.wav')],check=True)
 with wave.open(str(inp/'voz.wav'),'rb') as w:params=w.getparams();frames=w.readframes(w.getnframes())
 with wave.open(str(inp/'voz-larga.wav'),'wb') as w:
  w.setparams(params)
  for _ in range(180):w.writeframes(frames)
if (inp/'voz-larga.wav').exists():shutil.copyfile(inp/'voz-larga.wav',inp/'salida.wav')
manifest=[]
for p in sorted(inp.iterdir()):manifest.append({'name':p.name,'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
(root/'manifest-before.json').write_text(json.dumps(manifest,indent=2))
