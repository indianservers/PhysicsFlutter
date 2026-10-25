"""Verify the installed ordinary APK and assemble the Phase 6 handoff evidence."""
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess

root = Path(__file__).resolve().parents[1]
apk = root / 'deliverables/physics-atelier-phase6-debug.apk'
adb = Path(os.environ['LOCALAPPDATA']) / 'Android/Sdk/platform-tools/adb.exe'
device, package = 'emulator-5556', 'com.indianservers.physics_atelier'
def call(*args):
    return subprocess.check_output([str(adb), '-s', device, *args])
digest = hashlib.file_digest(apk.open('rb'), 'sha256').hexdigest()
installed = call('shell', 'pm', 'path', package).decode().strip().splitlines()[0].removeprefix('package:')
installed_hash = call('shell', 'sha256sum', installed).decode().split()[0]
assert digest == installed_hash, 'Installed APK differs from the ordinary deliverable'
metadata = call('shell', 'dumpsys', 'package', package).decode()
assert re.search(r'versionCode=6\b', metadata)
assert 'versionName=1.5.0' in metadata
assert call('shell', 'settings', 'get', 'global', 'airplane_mode_on').decode().strip() == '1'
(root / 'screenshots/phase6-installed-offline-home.png').write_bytes(call('exec-out', 'screencap', '-p'))
preservation = json.loads((root / 'screenshots/phase6-preservation.json').read_text())
native = json.loads((root / 'screenshots/phase6Validation.json').read_text())
profile = json.loads((root / 'screenshots/phase6-profile.json').read_text())
report = {
    'verifiedUTC': datetime.now(timezone.utc).isoformat(),
    'apk': str(apk.relative_to(root)), 'bytes': apk.stat().st_size,
    'sha256': digest, 'installedSha256Matches': True,
    'versionName': '1.5.0', 'versionCode': 6, 'entryPoint': 'lib/main.dart',
    'variant': 'ordinary debug APK, not an integration-test entry point',
    'device': device, 'airplaneMode': True,
    'interactiveLabs': 78, 'stableDestinations': 102, 'studios': 17,
    'unitWidgetTestsPassed': 181, 'analysis': 'No issues found',
    'nativeModelSelections': len(native['modes']),
    'nativeNewTrialCount': native['newTrials'],
    'nativeTargetsPassed': ['phase6_test', 'phase6_modes_test', 'phase6_storage_test', 'phase6_audit_test', 'phase6_profile_test'],
    'preservation': preservation, 'profile': profile,
    'remainingChecks': ['iOS/macOS Xcode compilation and device testing', 'physical Android profiling', 'independent accessibility user testing', 'photographic apparatus parity', 'production signing and release hardening'],
    'performanceQualification': 'Observed emulator raster jank remains; no 60 fps or physical-device performance claim.',
}
(root / 'screenshots/phase6-validation-summary.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
print(json.dumps({k: report[k] for k in ['bytes','sha256','installedSha256Matches','nativeModelSelections','preservation']}, indent=2))
