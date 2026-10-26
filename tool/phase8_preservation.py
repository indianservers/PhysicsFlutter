"""Compare old trial bodies exactly against the Phase 8 binary-safe backup.

Call after the final install. Reads only this app's own sandbox; never resets data.
"""
import argparse
import io
import json
import os
from pathlib import Path
import sqlite3
import subprocess
import tarfile
import tempfile
import xml.etree.ElementTree as ET

parser = argparse.ArgumentParser()
parser.add_argument('--baseline', default=r'C:\tmp\phase8-baseline-exact.tar')
parser.add_argument('--device', default='emulator-5556')
args = parser.parse_args()
adb = Path(os.environ['LOCALAPPDATA']) / 'Android/Sdk/platform-tools/adb.exe'
package = 'com.indianservers.physics_atelier'
current = subprocess.check_output([str(adb), '-s', args.device, 'exec-out', 'run-as', package, 'tar', 'cf', '-', 'databases', 'shared_prefs'])

def read(archive):
    with tempfile.TemporaryDirectory(prefix='physics-phase8-') as directory:
        with tarfile.open(fileobj=io.BytesIO(archive)) as tar:
            prefs = {}
            pref_file = 'shared_prefs/FlutterSharedPreferences.xml'
            if pref_file in tar.getnames():
                prefs = {element.attrib['name']: ET.tostring(element, encoding='unicode') for element in ET.fromstring(tar.extractfile(pref_file).read())}

            # Allowlist only the main database and its SQLite sidecars.
            for suffix in ['', '-wal', '-shm', '-journal']:
                name = 'databases/physics_notebook.db' + suffix
                if name in tar.getnames():
                    Path(directory, 'physics_notebook.db' + suffix).write_bytes(tar.extractfile(name).read())
        con = sqlite3.connect(Path(directory, 'physics_notebook.db'))
        result = {
            'preferences': prefs,
            'trials': dict(con.execute('SELECT id,body FROM trials')),
            'integrity': con.execute('PRAGMA integrity_check').fetchone()[0],
            'schema': con.execute('PRAGMA user_version').fetchone()[0],
            'attempts': dict(con.execute('SELECT id,body FROM challenge_attempts')),
            'sessions': {k: json.loads(v)['state'] for k,v in con.execute('SELECT id,body FROM sessions')},
        }
        con.close()
        return result

before, after = read(Path(args.baseline).read_bytes()), read(current)
assert before['integrity'] == after['integrity'] == 'ok'
assert after['schema'] == before['schema'] == 3
assert all(after['trials'].get(k) == v for k, v in before['trials'].items())
assert all(after['attempts'].get(k) == v for k,v in before['attempts'].items())
old_preferences = {k:v for k,v in before['preferences'].items() if k not in ['flutter.lastLab','flutter.lastStudio']}
assert all(after['preferences'].get(k)==v for k,v in old_preferences.items())
for key,state in before['sessions'].items():
    restored=after['sessions'][key]
    for field in ['notes','note','parameters']:
        if field in state:
            assert restored.get(field)==state[field], (key,field)
report = {
    'originalTrialBodiesByteForBytePreserved': len(before['trials']),
    'currentTrials': len(after['trials']),
    'originalChallengeBodiesExactlyPreserved': len(before['attempts']),
    'oldSessionNotesAndParametersPreserved': len(before['sessions']),
    'originalNonNavigationPreferencesPreserved': len(old_preferences),
    'baselineHasExplicitCompletionPreference': 'flutter.completed' in before['preferences'],
    'originalSchema': before['schema'], 'currentSchema': after['schema'],
    'integrity': after['integrity'], 'device': args.device,
    'qualification': 'Exact SQLite JSON text comparison after final APK installation; original backup remains local and is not committed.',
}
Path('screenshots/phase8-preservation.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
print(json.dumps(report, indent=2))
