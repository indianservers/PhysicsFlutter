param([string]$Flutter='C:\tools\flutter\bin\flutter.bat',[string]$Device='emulator-5556')
$ErrorActionPreference='Stop'
# Short temporary paths avoid this host JDK's Unix-domain socket failure.
New-Item -ItemType Directory -Path C:\tmp -Force | Out-Null
$env:TEMP='C:\tmp'
$env:TMP='C:\tmp'
$env:JAVA_TOOL_OPTIONS='-Djava.io.tmpdir=C:\tmp -Djava.net.preferIPv4Stack=true'
Push-Location (Split-Path $PSScriptRoot -Parent)
try {
  & $Flutter pub get
  if($LASTEXITCODE){throw 'Dependency resolution failed'}
  & $Flutter analyze
  if($LASTEXITCODE){throw 'Analysis failed'}
  & $Flutter test
  if($LASTEXITCODE){throw 'Tests failed'}
  & $Flutter drive --driver=test_driver/integration_test.dart --target=integration_test/phase1_test.dart -d $Device --enable-software-rendering --no-enable-impeller --keep-app-running
  if($LASTEXITCODE){throw 'Device integration failed'}
  foreach($Target in @('phase2_test','phase2_modes_test','phase3_test','phase4_test','phase4_modes_test','phase5_test','phase5_modes_test','phase6_test','phase6_modes_test','phase6_storage_test','phase7_test','phase7_storage_test')) {
    & $Flutter drive --driver=test_driver/integration_test.dart "--target=integration_test/$Target.dart" -d $Device --enable-software-rendering --no-enable-impeller --keep-app-running
    if($LASTEXITCODE){throw "$Target failed"}
  }
  & $Flutter drive --driver=test_driver/integration_test.dart --target=integration_test/phase3_audit_test.dart --dart-define=AUDIT_STAGE=after -d $Device --enable-software-rendering --no-enable-impeller --keep-app-running
  if($LASTEXITCODE){throw 'Phase 3 visual audit failed'}
  & $Flutter drive --driver=test_driver/integration_test.dart --target=integration_test/phase4_audit_test.dart --dart-define=AUDIT_STAGE=after -d $Device --enable-software-rendering --no-enable-impeller --keep-app-running
  if($LASTEXITCODE){throw 'Phase 4 visual audit failed'}
  & $Flutter drive --driver=test_driver/integration_test.dart --target=integration_test/phase5_audit_test.dart --dart-define=AUDIT_STAGE=after -d $Device --enable-software-rendering --no-enable-impeller --keep-app-running
  if($LASTEXITCODE){throw 'Phase 5 visual audit failed'}
  & $Flutter drive --driver=test_driver/integration_test.dart --target=integration_test/phase6_audit_test.dart --dart-define=AUDIT_STAGE=after -d $Device --enable-software-rendering --no-enable-impeller --keep-app-running
  if($LASTEXITCODE){throw 'Phase 6 visual/storage audit failed'}
  & $Flutter drive --driver=test_driver/integration_test.dart --target=integration_test/phase7_audit_test.dart --dart-define=AUDIT_STAGE=after -d $Device --enable-software-rendering --no-enable-impeller --keep-app-running
  if($LASTEXITCODE){throw 'Phase 7 visual/storage audit failed'}
  # phase7_modes_test includes REAL OS background/resume and needs the companion
  # tool/phase7_device_watch.py (dedicated emulator-5556). See PHASE7_VALIDATION.md.
  # Permission tests require deliberate pm grant/revoke; see PHASE4_VALIDATION.md.
  & $Flutter build apk --debug --target lib/main.dart
  if($LASTEXITCODE){throw 'APK build failed'}
} finally {Pop-Location}
