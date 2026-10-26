"""Make an ignored, local-only native test restoration define fixture from the exact baseline.
Never commit the generated file. Ordinary lib/main.dart builds do not reference it.
"""
import argparse,base64,json,sqlite3,tarfile,tempfile,subprocess,os
import xml.etree.ElementTree as ET
from pathlib import Path
parser=argparse.ArgumentParser();parser.add_argument('--resume',action='store_true');parser.add_argument('--baseline',default=r'C:\tmp\phase9-baseline-exact.tar');parser.add_argument('--output',default='integration_test/phase9_fixture.local.json');parser.add_argument('--push',action='store_true');parser.add_argument('--device',default='emulator-5556');args=parser.parse_args()
rows={};prefs={};source=Path(args.baseline)
if source.exists():
 with tempfile.TemporaryDirectory(prefix='physics-phase9-fixture-') as directory:
  with tarfile.open(source) as tar:
   pref_name='shared_prefs/FlutterSharedPreferences.xml'
   if pref_name in tar.getnames():
    for node in ET.fromstring(tar.extractfile(pref_name).read()):
     key=node.attrib['name'].removeprefix('flutter.');text=node.text or ''
     if node.tag=='string':prefs[key]=json.loads(text.split('!',1)[1]) if text.startswith('VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3Qu!') else text
     elif node.tag=='boolean':prefs[key]=node.attrib['value']=='true'
     elif node.tag in ['int','long']:prefs[key]=int(node.attrib['value'])
   for suffix in ['','-wal','-shm','-journal']:
    name='databases/physics_notebook.db'+suffix
    if name in tar.getnames():Path(directory,'db'+suffix).write_bytes(tar.extractfile(name).read())
  con=sqlite3.connect(Path(directory,'db'));rows={k:json.loads(v)['state'] for k,v in con.execute('select id,body from sessions')};con.close()
prior = json.loads(Path('screenshots/phase9Inventory.json').read_text())['entries'] if args.resume and Path('screenshots/phase9Inventory.json').exists() else {}
def encoded(value):return base64.b64encode(json.dumps(value).encode()).decode()
Path(args.output).write_text(json.dumps({
 'PHASE9_ORIGINAL_SESSIONS':encoded(rows),
 'PHASE9_ORIGINAL_PREFERENCES':encoded(prefs),
 'PHASE9_PRIOR_EVIDENCE':encoded(prior),
},indent=2),encoding='utf-8')

if args.push:
 adb=Path(os.environ['LOCALAPPDATA'])/'Android/Sdk/platform-tools/adb.exe'
 command="run-as com.indianservers.physics_atelier sh -c 'mkdir -p files; cat > files/physics_qa_fixture.json'"
 subprocess.run([str(adb),'-s',args.device,'shell',command],input=Path(args.output).read_bytes(),check=True)
 print('Private baseline transferred to the test app sandbox; no notebook values printed or compiled.')
else:print('Local-only fixture generated. Use --push for Android native preservation QA; do not commit it.')
