"""Bounded TalkBack service/semantic exposure check on the dedicated emulator only."""
from pathlib import Path
import json,os,re,subprocess,time,xml.etree.ElementTree as ET
root=Path(__file__).resolve().parents[1]
base=[str(Path(os.environ['LOCALAPPDATA'])/'Android/Sdk/platform-tools/adb.exe'),'-s','emulator-5556']
def run(*args):return subprocess.check_output(base+list(args),stderr=subprocess.STDOUT).decode(errors='replace').strip()
def snapshot():
    run('shell','uiautomator','dump','/sdcard/physics_accessibility.xml')
    return ET.fromstring(run('shell','cat','/sdcard/physics_accessibility.xml'))
original={k:run('shell','settings','get','secure',k) for k in ['enabled_accessibility_services','accessibility_enabled']}
# Continue points to the same original last lab, so this check does not replace recent activity.
ui=snapshot();found=False
for node in ui.iter('node'):
    if 'Continue Learning' in (node.get('text','')+' '+node.get('content-desc','')):
        a=list(map(int,re.findall(r'\d+',node.get('bounds',''))));assert len(a)==4
        run('shell','input','tap',str((a[0]+a[2])//2),str((a[1]+a[3])//2));found=True;time.sleep(2);break
service='com.google.android.marvin.talkback/.TalkBackService'
permission_was_granted='android.permission.POST_NOTIFICATIONS: granted=true' in run('shell','dumpsys','package','com.google.android.marvin.talkback')
try:
    run('shell','pm','grant','com.google.android.marvin.talkback','android.permission.POST_NOTIFICATIONS')
    services=original['enabled_accessibility_services']
    enabled=service if services in ['null',''] else services+':'+service
    run('shell','settings','put','secure','enabled_accessibility_services',enabled)
    run('shell','settings','put','secure','accessibility_enabled','1');time.sleep(3)
    state=run('shell','dumpsys','accessibility');ui=snapshot()
    appnodes=[n for n in ui.iter('node') if n.get('package')=='com.indianservers.physics_atelier']
    labels=[n.get('content-desc') or n.get('text') for n in appnodes if n.get('content-desc') or n.get('text')]
    run('shell','input','swipe','150','500','550','500','200');time.sleep(1)
    (root/'screenshots/workspace-talkback-native.png').write_bytes(subprocess.check_output(base+['exec-out','screencap','-p']))
    report={'device':'emulator-5556','service':service,'enabledSettingObserved':service in run('shell','settings','get','secure','enabled_accessibility_services'),'serviceListedInAccessibilityState':'TalkBackService' in state,'continuedIntoOriginalLab':found,'applicationSemanticNodes':len(appnodes),'exposedLabels':labels,'qualification':'Actual Android TalkBack service enabled and service state/native semantic exposure inspected; a screen-reader swipe was delivered. No spoken-output transcription or independent blind-user usability certification. Original accessibility settings restored in finally.'}
    (root/'screenshots/workspace-talkback.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    print(json.dumps({k:v for k,v in report.items() if k!='exposedLabels'},indent=2))
finally:
    if not permission_was_granted:run('shell','pm','revoke','com.google.android.marvin.talkback','android.permission.POST_NOTIFICATIONS')
    for key,value in original.items():
        if value=='null':run('shell','settings','delete','secure',key)
        else:run('shell','settings','put','secure',key,value)
    time.sleep(1)
    if found:run('shell','input','keyevent','KEYCODE_BACK')
