"""Dedicated API37 emulator workaround and real OS lifecycle automation.
Run alongside flutter drive with its output redirected to a NEW log file.
Only operates on the explicitly dedicated emulator-5556.
"""
import argparse, os, re, subprocess, time, json
from pathlib import Path
parser=argparse.ArgumentParser();parser.add_argument('log');parser.add_argument('--profile',action='store_true');parser.add_argument('--default-renderer',action='store_true');args=parser.parse_args()
adb=str(Path(os.environ['LOCALAPPDATA'])/'Android/Sdk/platform-tools/adb.exe')
base=[adb,'-s','emulator-5556'];component='com.indianservers.physics_atelier/.MainActivity'
launched=False;background=False;shared=False
for _ in range(6000):
 text=Path(args.log).read_text(encoding='utf-8',errors='replace') if Path(args.log).exists() else ''
 if not launched and re.search(r'Installing [^\r\n]*\d[\d,.]*(?:ms|s)\s*(?:\r?\n|$)',text):
  command=base+['shell','am','start','-W','-n',component]
  if not args.default_renderer:command+=['--ez','enable-impeller','false']
  if not args.profile:command+=['--ez','enable-software-rendering','true']
  subprocess.run(command,check=True);launched=True;print('HOST_EXPLICIT_LAUNCH_DONE',flush=True)
 if not background and 'PHASE9_READY_FOR_OS_BACKGROUND' in text:
  subprocess.run(base+['shell','input','keyevent','KEYCODE_HOME'],check=True);time.sleep(1.2)
  subprocess.run(base+['shell','am','start','-W','-n',component],check=True);background=True;print('HOST_BACKGROUND_RESUME_DONE',flush=True)
 if not shared and 'PHASE9_READY_FOR_SHARE' in text:
  time.sleep(1.0)
  activity=subprocess.check_output(base+['shell','dumpsys','activity','activities']).decode(errors='replace')
  observed='ChooserActivity' in activity or 'ResolverActivity' in activity
  Path('screenshots/phase9-native-share-sheet.png').write_bytes(subprocess.check_output(base+['exec-out','screencap','-p']))
  Path('screenshots/phase9-native-export.json').write_text(json.dumps({'nativeChooserObserved':observed,'qualification':'Explicit CSV export opened OS chooser; returned to the app without choosing any recipient.'},indent=2))
  subprocess.run(base+['shell','am','start','-W','-n',component],check=True);shared=True
 if 'All tests passed.' in text:break
 if 'Oops; flutter has exited unexpectedly' in text:break
 if 'Some tests failed.' in text or 'Failure Details:' in text or 'Gradle task assembleDebug failed' in text or 'Gradle task assembleProfile failed' in text:break
 time.sleep(.2)
else:raise TimeoutError('Native validation did not finish')
