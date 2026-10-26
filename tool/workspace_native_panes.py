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
        if label in (n.get('content-desc','')+' '+n.get('text','')):
            a=list(map(int,re.findall(r'\d+',n.get('bounds',''))));assert len(a)==4
            run('shell','input','tap',str((a[0]+a[2])//2),str((a[1]+a[3])//2));time.sleep(1);return
    raise AssertionError('Native accessible action missing: '+label)
tap_label('Continue Learning')
for menu,label,name in [('View','Scene + Graph','comparison-split'),('View','Full-screen Scene','comparison-full-scene'),('Full','Full-screen Graph','comparison-full-graph')]:
    tap_label(menu);tap_label(label);time.sleep(1)
    (root/f'screenshots/workspace-after-{name}.png').write_bytes(subprocess.check_output(base+['exec-out','screencap','-p']))
tap_label('Graph');tap_label('Scene')
run('shell','input','keyevent','KEYCODE_BACK')
print('Captured ordinary-APK split scene/graph and both fullscreen modes; restored Scene and Home without playback.')
