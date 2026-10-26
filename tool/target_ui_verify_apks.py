"""Install ordinary local APKs without clearing application data; verify bytes and offline launch."""
from pathlib import Path
import hashlib,json,os,subprocess,time
root=Path(__file__).resolve().parents[1]
sdk=Path(os.environ['LOCALAPPDATA'])/'Android/Sdk'
adb=sdk/'platform-tools/adb.exe';base=[str(adb),'-s','emulator-5556']
package='com.indianservers.physics_atelier';component=package+'/.MainActivity'
def adb_text(*args):return subprocess.check_output(base+list(args),stderr=subprocess.STDOUT).decode(errors='replace').strip()
report={'device':'emulator-5556','version':'1.10.0+13','target':'lib/main.dart','artifacts':[]}
original={k:adb_text('shell','settings','get','global',k) for k in ['wifi_on','mobile_data']}
try:
    adb_text('shell','svc','wifi','disable');adb_text('shell','svc','data','disable')
    for mode,name in [('release-development-signed','physics-atelier-target-ui-release-dev-signed.apk'),('debug','physics-atelier-target-ui-debug.apk')]:
        path=root/'deliverables'/name;assert path.exists()
        digest=hashlib.sha256(path.read_bytes()).hexdigest()
        result=adb_text('install','-r',str(path));assert 'Success' in result,result
        adb_text('shell','am','force-stop',package)
        launch=adb_text('shell','am','start','-W','-f','0x10008000','-n',component)
        launch_timed_out='Status: timeout' in launch
        if launch_timed_out:
            # API37 may finish drawing after am's fixed launch-wait limit. Recheck the live activity explicitly.
            launch=adb_text('shell','am','start','-W','-n',component)
        assert 'Status: ok' in launch,launch
        time.sleep(3)
        pid=adb_text('shell','pidof',package);assert pid
        installed=adb_text('shell','pm','path',package).splitlines();assert len(installed)==1
        installed_hash=hashlib.sha256(subprocess.check_output(base+['exec-out','cat',installed[0].removeprefix('package:')])).hexdigest()
        assert digest==installed_hash
        badging=subprocess.check_output([str(sdk/'build-tools/36.0.0/aapt.exe'),'dump','badging',str(path)]).decode(errors='replace')
        assert "versionCode='13'" in badging and "versionName='1.10.0'" in badging
        permissions=subprocess.check_output([str(sdk/'build-tools/36.0.0/aapt.exe'),'dump','permissions',str(path)]).decode(errors='replace')
        fatal=adb_text('logcat','-d',f'--pid={pid}','-s','AndroidRuntime:E')
        assert 'FATAL EXCEPTION' not in fatal
        (root/f'screenshots/target-ui-ordinary-{mode}-home.png').write_bytes(subprocess.check_output(base+['exec-out','screencap','-p']))
        (root/'deliverables'/f'{name}.sha256').write_text(f'{digest}  {name}\n')
        report['artifacts'].append({'mode':mode,'path':'deliverables/'+name,'bytes':path.stat().st_size,'sha256':digest,'installedBytesMatch':True,'offlineProcessAlive':True,'fatalExceptionObserved':False,'launchWaitTimeoutRetried':launch_timed_out,'packageBadging':badging.splitlines()[0],'permissions':permissions.splitlines(),'signing':'Existing local development/debug certificate; not production signing'})
finally:
    adb_text('shell','svc','wifi','enable' if original['wifi_on']=='1' else 'disable')
    adb_text('shell','svc','data','enable' if original['mobile_data']=='1' else 'disable')
report['qualification']='Ordinary main-entrypoint APKs installed with -r, bytes matched installed base APK and processes launched while Wi-Fi/mobile data disabled. No destructive reset, upload or publication. Not exhaustive offline/UI/device certification.'
(root/'screenshots/target-ui-build-verification.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps({a['mode']:a['sha256'] for a in report['artifacts']},indent=2))
