"""Read-only native memory samples during the dedicated Phase9 inventory traversal."""
import json,os,re,subprocess,time,sys
from pathlib import Path
adb=str(Path(os.environ['LOCALAPPDATA'])/'Android/Sdk/platform-tools/adb.exe')
seen=set();rows=[];log=Path(sys.argv[1]);out=Path('screenshots/phase9-navigation-memory.json')
for _ in range(2700):
 text=log.read_text(encoding='utf-8',errors='replace') if log.exists() else ''
 ids=re.findall(r'PHASE9_ENTRY (s\d+)-e\d+',text)
 if ids and ids[-1] not in seen:
  studio=ids[-1];seen.add(studio)
  raw=subprocess.check_output([adb,'-s','emulator-5556','shell','dumpsys','meminfo','com.indianservers.physics_atelier']).decode(errors='replace')
  pss=re.search(r'TOTAL PSS:\s*(\d+)',raw)
  rows.append({'studio':studio,'unixSeconds':time.time(),'totalPssKB':int(pss.group(1)) if pss else None,'raw':raw})
  out.write_text(json.dumps({'qualification':'Debug software-rendered native navigation; process PSS includes VM and screenshot accumulation. Not a leak proof or release memory measurement.','samples':rows},indent=2))
 if 'All tests passed.' in text or 'Some tests failed.' in text:break
 time.sleep(1)
