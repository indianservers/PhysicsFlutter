# Phase 4 validation

Validation date: 25–26 October 2026, Windows host. Flutter 3.47.8 stable / Dart 3.13.7. App version 1.3.0+4; scientific model `waves-optics-4.0`. These are implementation checks, not store-release certification.

## Automated checks

Baseline at `b3d2232`: 73 passing unit/widget tests and a clean checkout. Final suite: **108 passing tests** (`flutter test`). This includes the original Measurement/Dynamics/Advanced scientific and workspace tests, 31 new wave/optics numerical tests and four new workspace/isolate tests. `flutter analyze` reports no issues. Final ordinary Android build uses `lib/main.dart`, not a test entry point.

Scientific checks cover wave speed/direction/phase, Gaussian signed cancellation and continuation, coherent path/phase intensity bounds and grid validity, fixed endpoints/nodes/harmonics, FFT sine/two-tone/harmonic/leakage/normalization/silence/Nyquist, PCM split bytes/stereo/ring bounds, Doppler approach/recession and retarded fronts, vector reflection/intersections, normal/equal/critical/TIR Snell cases, conserved refraction frequency, signed lens/mirror real/virtual/focal limits, optical symmetry/normalization/minima/width/spacing, cached detector profile and exact paused-tick replay. All twelve models produce bounded finite snapshots and deterministic replay.

Widget coverage builds all five sections of all twelve labs, scrolls lower controls at 320×568 logical pixels with 160% text, and checks landscape. It exercises real numeric changes, Step, prediction feedback, recorded notes and reopened inputs. A denied microphone test asserts no fabricated live waveform; a separate real isolate test protects the native analysis callback boundary. Earlier phase workspace suites still run.

## Actual Android execution

Dedicated AVD `Physics_Phase3`, adb `emulator-5556`: Android 17/API 37, x86_64, 16 KB pages, 720×1280 at 320 dpi, two virtual cores, 2048 MB. Host GPU RTX 3050. No physical mid-range phone or iOS device was available. Debug journeys use software rendering with Impeller disabled, separately from profile GPU runs. The shared `emulator-5554` was left alone.

`phase4_test.dart` passed its complete 12-lab journey: home search (unique stable IDs distinguish Interference), studio/lab navigation, real parameter edits, playback/pause/Step/time replay where applicable, actual trial/notes, saved configuration reopen paused, prediction feedback, all five sections, actual graphs/formulas and Results. `screenshots/phase4Validation.json` records twelve verified labs and **80 original trials exactly preserved**. `phase4-verified-results.csv` contains the twelve explicit new observations and their full configurations. These are actual computed app values, not seeded demo results.

That native target also created a real SQLite v2 fixture containing an earlier trial and a session note, opened it through LocalNotebook, and verified schema 3 plus the challenge table and exact old JSON/note. The first fixture attempt lacked the existing session envelope; the fixture was corrected before the passing run. Existing application data was never reset or uninstalled. Final independent binary-safe SQLite comparison is in `screenshots/phase4-preservation.json`; the original backup remains outside Git.

The final independent check after ordinary APK installation found **94 current trials**, with all **80 original trial JSON bodies byte-for-byte identical**, all **64 original challenge bodies identical**, and notes/parameters retained in all **42 original sessions**. Schema remains 3 and `PRAGMA integrity_check` returns `ok`.

`phase4_modes_test.dart` additionally exercises coherent phase-π cancellation, n=3 fixed endpoints, two-tone/odd-harmonic FFT, critical-angle and TIR geometry, converging/concave 2f/f/inside-f images, diverging lens/convex mirror and actual cached-profile detector movement. Native captures are `phase4-mode-*.png`; structured assertions are in `phase4Modes.json`. A test-only first attempt failed because its final scene finder remained scrolled below the apparatus; scrolling back was fixed before the passing run.

`phase4_audit_test.dart` captures before/after home, six studios and seven representative earlier labs. The after target also captures the actual generated Hann spectrum. The earlier globe cache preserves geometry and physics; before/after visuals and old tests provide evidence, rather than an invented performance gain.

## Native microphone and privacy

Denial was exercised with Android permission revoked/user-fixed, not a mock platform stream. `phase4MicrophoneDenied.json` confirms the denied state and functioning generated mode. Actual allowed native capture in `phase4Microphone.json`: **15 analyzed windows**, **48000 Hz**, **2048 samples**, RMS **0.0001314584 full scale**, strongest bin **187.5 Hz**. This is emulator input, not a known acoustic tone, calibrated SPL or microphone quality measurement. Native PCM came from Android; synthetic test signals are labeled separately.

The actual allowed run proved background/resume leaves capture stopped, explicit analysis recording excludes raw signal/spatial-profile data, saved bins number 1025, and analysis reopens without starting the recorder. The first native analysis attempt exposed an isolate closure capturing surrounding recorder state; changing to a top-level compute callback fixed it and the real-isolate regression test now passes. Raw PCM and waveform were not stored or uploaded.

Permission commands for reproduction, on a **dedicated test device only**:

```powershell
adb -s emulator-5556 shell pm revoke com.indianservers.physics_atelier android.permission.RECORD_AUDIO
adb -s emulator-5556 shell pm set-permission-flags com.indianservers.physics_atelier android.permission.RECORD_AUDIO user-fixed
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/phase4_microphone_test.dart -d emulator-5556 --enable-software-rendering --no-enable-impeller --keep-app-running
adb -s emulator-5556 shell pm clear-permission-flags com.indianservers.physics_atelier android.permission.RECORD_AUDIO user-fixed user-set
adb -s emulator-5556 shell pm grant com.indianservers.physics_atelier android.permission.RECORD_AUDIO
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/phase4_microphone_test.dart --dart-define=ALLOW_MIC=true -d emulator-5556 --enable-software-rendering --no-enable-impeller --keep-app-running
```

## Performance evidence and limits

`screenshots/phase4-profile.json` contains actual profile-mode frame build/raster/total percentiles for the animated coherent field, generated FFT and 90 actual diffraction detector-slider updates with the apparatus visible. Profile command:

```powershell
flutter drive --profile --no-dds --driver=test_driver/integration_test.dart --target=integration_test/phase4_profile_test.dart -d emulator-5556 --no-enable-impeller --keep-app-running
```

Emulator profile results are not a claim of 60 fps on a physical mid-range device. FrameTiming includes the emulator/host scheduler and test pumps; all recorded percentiles and over-budget frames are retained in the JSON. Static optical models do not animate arbitrary optical carriers. FFT and parameter curves are outside widget build; numerical/history buffers, jobs, phasor grids and emission history are bounded. Detector-only edits reuse the same 801-sample intensity curve. The earlier globe mesh/shader is cached and bounded.

Actual 90-frame observations per case:

- Coherent field: median build/raster **2.477/4.217 ms**, p95 build/raster **6.436/20.534 ms**, p95 total **40.060 ms**, **51/90** total spans above 16.67 ms. Physical ticks advanced 3→462 during the measured activity.
- Generated FFT: median build/raster **.617/2.541 ms**, p95 build/raster **2.823/11.696 ms**, p95 total **34.967 ms**, **38/90** above 16.67 ms. Ticks advanced 4→418.
- Diffraction detector: median build/raster **1.683/2.588 ms**, p95 build/raster **5.313/10.486 ms**, p95 total **38.658 ms**, **54/90** above 16.67 ms. Ninety actual detector callback edits; static physical clock correctly stayed at zero.

There is measurable emulator frame-time jank, especially the coherent-field raster tail. Further profiling/optimization on a physical mid-range device remains open. The test verifies that animated models are still active during measurement; an initial profiling harness attempt incorrectly waited for animation to settle and was discarded, not reported as an animated performance result.

`phase4-numerics.json` is a separate pure-Dart **host** benchmark, 10 warmups then 100 model constructions: coherent-field median .593 ms/p95 1.030 ms, FFT .232/.484 ms, diffraction .163/.740 ms. These include allocations and are not mobile frame measurements. Reproduce with `dart run tool/phase4_evidence.dart`; reruns naturally differ.

## Installation and remaining checks

The ordinary debug APK is `deliverables/physics-atelier-phase4-debug.apk`, with adjacent SHA256. Final install uses `adb install -r` to preserve the notebook. The final app launches offline from its ordinary entry point. No Phase 5 work or GitHub push is included.

APK: **209,754,116 bytes**, versionName **1.3.0**, versionCode **4**, minimum Android API **24**, target API **36**. SHA256: `a6e301bd1f8abe6532deddb862ead1345572fcadbbe1e0483096a5795bd78e57`. `screenshots/phase4-installed-offline-home.png` is a binary-safe adb capture of the ordinary installed app with airplane mode enabled and the default renderer. The debug APK is intentionally ignored by Git like earlier phase deliverables; its checksum and source/evidence are committed.

On this API37 emulator, Flutter drive can wait after installing until the activity is launched explicitly. Launching `com.indianservers.physics_atelier/.MainActivity` with matching renderer extras allowed the test driver to attach; this is recorded as a host test-runner issue, not hidden as application work. All test installs use `--keep-app-running` to avoid data deletion.

iOS Info.plist parses with one root microphone usage description and dependencies are cross-platform. macOS/Xcode compilation, physical microphone route/interruption/permission QA, real acoustic test tones/calibration, physical-device GPU/thermal/memory profiling, TalkBack/VoiceOver user testing and photographic art parity remain unverified. Model limits include linear constant-amplitude waves, subsonic collinear Doppler, paraxial images, and far-field scalar diffraction. No claim extends beyond them.
