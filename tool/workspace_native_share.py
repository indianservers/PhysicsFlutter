"""Exercise ordinary-APK chooser cancellation without selecting a recipient."""
from pathlib import Path
import json,os,re,subprocess,time,xml.etree.ElementTree as ET
base=[str(Path(os.environ['LOCALAPPDATA'])/'Android/Sdk/platform-tools/adb.exe'),'-s','emulator-5556']
root=Path(__file__).resolve().parents[1]
def run(*args):return subprocess.check_output(base+list(args),stderr=subprocess.STDOUT).decode(errors='replace').strip()
def tap_label(label):
    run('shell','uiautomator','dump','/sdcard/physics_share.xml')
    ui=ET.fromstring(run('shell','cat','/sdcard/physics_share.xml'))
    for n in ui.iter('node'):
        if label in (n.get('content-desc',''),n.get('text','')):
            a=list(map(int,re.findall(r'\d+',n.get('bounds',''))));assert len(a)==4
            run('shell','input','tap',str((a[0]+a[2])//2),str((a[1]+a[3])//2));time.sleep(1);return
    raise AssertionError('Native accessible action missing: '+label)
tap_label('Your notebook');tap_label('Export all trials as CSV')
time.sleep(1)
state=run('shell','dumpsys','activity','activities');chooser='ChooserActivity' in state
assert chooser
run('shell','input','keyevent','KEYCODE_BACK');time.sleep(2)
state=run('shell','dumpsys','activity','activities')
resumed=[x.strip() for x in state.splitlines() if 'topResumedActivity=' in x or 'mResumedActivity:' in x]
run('shell','uiautomator','dump','/sdcard/physics_share.xml')
ui=ET.fromstring(run('shell','cat','/sdcard/physics_share.xml'))
labels=[n.get('content-desc') or n.get('text') for n in ui.iter('node') if n.get('package')=='com.indianservers.physics_atelier']
notebook=any('Your notebook' in (v or '') for v in labels)
report={'nativeChooserObserved':chooser,'ordinaryDebugApk':True,'backReturnedToNotebook':notebook,'resumedActivities':resumed,'qualification':'Ordinary lib/main.dart APK: explicit CSV action, OS chooser observed, one native Back, no recipient selected. Does not certify delivery to an external app.'}
(root/'screenshots/phase9-native-export.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
(root/'screenshots/workspace-export-return.png').write_bytes(subprocess.check_output(base+['exec-out','screencap','-p']))
print(json.dumps(report,indent=2));assert notebook
run('shell','input','keyevent','KEYCODE_BACK')
