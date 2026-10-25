param([string]$Flutter='C:\tools\flutter\bin\flutter.bat',[string]$Device='emulator-5554')
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
  & $Flutter drive --driver=test_driver/integration_test.dart --target=integration_test/phase1_test.dart -d $Device --enable-software-rendering --no-enable-impeller
  if($LASTEXITCODE){throw 'Device integration failed'}
  & $Flutter build apk --debug --target lib/main.dart
  if($LASTEXITCODE){throw 'APK build failed'}
} finally {Pop-Location}
