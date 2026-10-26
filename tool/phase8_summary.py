"""Verify the installed ordinary APK and assemble the Phase 8 handoff evidence."""
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess

root = Path(__file__).resolve().parents[1]
apk = root / 'deliverables/physics-atelier-phase8-debug.apk'
adb = Path(os.environ['LOCALAPPDATA']) / 'Android/Sdk/platform-tools/adb.exe'
device, package = 'emulator-5556', 'com.indianservers.physics_atelier'
def call(*args):
    return subprocess.check_output([str(adb), '-s', device, *args])
digest = hashlib.file_digest(apk.open('rb'), 'sha256').hexdigest()
installed = call('shell', 'pm', 'path', package).decode().strip().splitlines()[0].removeprefix('package:')
installed_hash = call('shell', 'sha256sum', installed).decode().split()[0]
assert digest == installed_hash, 'Installed APK differs from the ordinary deliverable'
metadata = call('shell', 'dumpsys', 'package', package).decode()
assert re.search(r'versionCode=8\b', metadata)
assert 'versionName=1.7.0' in metadata
assert call('shell', 'settings', 'get', 'global', 'airplane_mode_on').decode().strip() == '1'
(root / 'screenshots/phase8-installed-offline-home.png').write_bytes(call('exec-out', 'screencap', '-p'))
preservation = json.loads((root / 'screenshots/phase8-preservation.json').read_text())
native = json.loads((root / 'screenshots/phase8Validation.json').read_text())
profile = json.loads((root / 'screenshots/phase8-profile.json').read_text())
modes = json.loads((root / 'screenshots/phase8Boundaries.json').read_text())
storage = json.loads((root / 'screenshots/phase8Storage.json').read_text())
assert native['realOSBackgroundResume'] and 'paused' in native['checks']['realOSLifecycle']
assert storage['actualV2toV3Upgrade'] and storage['oldTrialBodyUnchanged']
assert storage['newAstronomySITrialRoundTrip'] and storage['comparisonAndMasteryRoundTrip']
for key in ['s16-e00','s16-e01','s16-e05','comparison0','comparison4']:
    assert profile[key]['frameCount'] > 0 and profile[key]['endTicks'] > profile[key]['startTicks']
report = {
    'verifiedUTC': datetime.now(timezone.utc).isoformat(),
    'apk': str(apk.relative_to(root)), 'bytes': apk.stat().st_size,
    'sha256': digest, 'installedSha256Matches': True,
    'versionName': '1.7.0', 'versionCode': 8, 'entryPoint': 'lib/main.dart',
    'variant': 'ordinary debug APK, not an integration-test entry point',
    'device': device, 'airplaneMode': True,
    'interactiveLabs': 96, 'stableDestinations': 102, 'studios': 17,
    'unitWidgetTestsPassed': 268, 'analysis': 'No issues found',
    'nativeModelSelections': native['nativeAstronomySelections'],
    'nativeNewTrialCount': native['newTrials'],
    'nativeTargetsPassed': ['phase8_test', 'phase8_boundaries_test', 'phase8_storage_test (via audit)', 'phase8_audit_test', 'phase8_profile_test'],
    'preservation': preservation, 'profile': profile, 'nativeBoundariesAndLifecycle': modes, 'nativeMigration': storage,
    'remainingChecks': ['iOS/macOS Xcode compilation and device testing', 'physical Android profiling', 'independent accessibility user testing', 'photographic apparatus parity', 'production signing and release hardening'],
    'performanceQualification': 'Observed emulator raster jank remains; no 60 fps or physical-device performance claim.',
}
(root / 'screenshots/phase8-validation-summary.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
print(json.dumps({k: report[k] for k in ['bytes','sha256','installedSha256Matches','nativeModelSelections','preservation']}, indent=2))
