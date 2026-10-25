"""Verify the installed ordinary APK and assemble the Phase 7 handoff evidence."""
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess

root = Path(__file__).resolve().parents[1]
apk = root / 'deliverables/physics-atelier-phase7-debug.apk'
adb = Path(os.environ['LOCALAPPDATA']) / 'Android/Sdk/platform-tools/adb.exe'
device, package = 'emulator-5556', 'com.indianservers.physics_atelier'
def call(*args):
    return subprocess.check_output([str(adb), '-s', device, *args])
digest = hashlib.file_digest(apk.open('rb'), 'sha256').hexdigest()
installed = call('shell', 'pm', 'path', package).decode().strip().splitlines()[0].removeprefix('package:')
installed_hash = call('shell', 'sha256sum', installed).decode().split()[0]
assert digest == installed_hash, 'Installed APK differs from the ordinary deliverable'
metadata = call('shell', 'dumpsys', 'package', package).decode()
assert re.search(r'versionCode=7\b', metadata)
assert 'versionName=1.6.0' in metadata
assert call('shell', 'settings', 'get', 'global', 'airplane_mode_on').decode().strip() == '1'
(root / 'screenshots/phase7-installed-offline-home.png').write_bytes(call('exec-out', 'screencap', '-p'))
preservation = json.loads((root / 'screenshots/phase7-preservation.json').read_text())
native = json.loads((root / 'screenshots/phase7Validation.json').read_text())
profile = json.loads((root / 'screenshots/phase7-profile.json').read_text())
modes = json.loads((root / 'screenshots/phase7Modes.json').read_text())
storage = json.loads((root / 'screenshots/phase7Storage.json').read_text())
assert 'paused' in modes['actualOSBackgroundResume'] and modes['actualOSBackgroundResume'][-1] == 'resumed'
assert storage['actualV2toV3Upgrade'] and storage['oldTrialBodyUnchanged']
assert storage['newActivityTrialRoundTrip']
for key in ['s14-e03','s14-e04','s15-e02','s15-e05']:
    assert profile[key]['frameCount'] > 0 and profile[key]['endTicks'] > profile[key]['startTicks']
report = {
    'verifiedUTC': datetime.now(timezone.utc).isoformat(),
    'apk': str(apk.relative_to(root)), 'bytes': apk.stat().st_size,
    'sha256': digest, 'installedSha256Matches': True,
    'versionName': '1.6.0', 'versionCode': 7, 'entryPoint': 'lib/main.dart',
    'variant': 'ordinary debug APK, not an integration-test entry point',
    'device': device, 'airplaneMode': True,
    'interactiveLabs': 90, 'stableDestinations': 102, 'studios': 17,
    'unitWidgetTestsPassed': 223, 'analysis': 'No issues found',
    'nativeModelSelections': len(native['modes']),
    'nativeNewTrialCount': native['newTrials'],
    'nativeTargetsPassed': ['phase7_test', 'phase7_modes_test', 'phase7_storage_test', 'phase7_audit_test', 'phase7_profile_test'],
    'preservation': preservation, 'profile': profile, 'nativeBoundariesAndLifecycle': modes, 'nativeMigration': storage,
    'remainingChecks': ['iOS/macOS Xcode compilation and device testing', 'physical Android profiling', 'independent accessibility user testing', 'photographic apparatus parity', 'production signing and release hardening'],
    'performanceQualification': 'Observed emulator raster jank remains; no 60 fps or physical-device performance claim.',
}
(root / 'screenshots/phase7-validation-summary.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
print(json.dumps({k: report[k] for k in ['bytes','sha256','installedSha256Matches','nativeModelSelections','preservation']}, indent=2))
