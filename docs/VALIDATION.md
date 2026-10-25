# Validation — 25 October 2026

## Executed successfully

- Flutter 3.47.8 stable / Dart 3.13.7 inspected before dependency selection; packages resolved and locked.
- `flutter analyze --no-pub`: no issues found on the final functional source.
- `flutter test`: **17 tests passed** (13 scientific/data tests and four widget/application tests).
- The scientific serialization test was rerun after strengthening it to include non-default propagation inputs, operation and output; all 13 scientific tests passed again.
- `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/phase1_test.dart -d emulator-5554 --enable-software-rendering --no-enable-impeller`: **one end-to-end Android workflow passed**, plus framework teardown. The framework prints two passes because teardown is counted; this is not two separate workflows.
- `flutter build apk --profile --target lib/main.dart`: succeeded. Installed the profile APK and cold-launched its actual MainActivity successfully with Wi-Fi/data disabled. `screenshots/11-profile-offline.png` was captured from the emulator and inspected.
- `flutter build apk --debug --target lib/main.dart`: succeeded. Installed the resulting ordinary app APK, cold-launched it with the default renderer, navigated Home → Measurement and used Android Back successfully while offline. `screenshots/12-debug-studio-offline.png` was captured and inspected.
- All 17 target PNGs remain in `Target UI/`; none was bundled or rendered as a working app screen.

## Test coverage

The catalog test verifies exactly 17 studios, six entries each, 102 unique IDs, six introductory tools and six interactive Measurement labs. A widget test actually builds every studio and every destination, including all 102 equation views. Search opens a matching lab. Fresh home state contains no completed activity or invented history.

Scientific tests cover SI conversions, view-transform inverse and ruler invariance, every vernier tick in range and its coincidence, positive/negative zero bias and corrected geometry, every micrometer tick and pitch/rotation, contact constraints, both equivalent spherometer formulas, signed curvature and flat limits, constant-acceleration timing, empty/single/zero-mean uncertainty datasets, missing resolution, independent propagation including zero inputs and invalid denominators, CSV quoting, trial serialization and paused restoration.

The small-screen test uses 320 × 568 logical pixels with **160% system text scaling**. It opens all five sections in all six Measurement labs with no Flutter overflow/errors. Separate regression tests check finite numeric input validation and controller ownership during dialog dismissal, and safe chart rendering for a single zero reading with unknown resolution.

The Android integration workflow opens each Measurement lab, resets its state, reveals scale answers where relevant, runs/pauses the track timer, enters three uncertainty readings through the native numeric keyboard, records genuine trials, reopens their configurations, and visits current-value formula views. A fresh LocalNotebook instance reads the SQLite records. The exported test CSV contains **eight actual records**: three instrument lengths, one curvature radius, one speed, one balance mass, one elapsed time, and one dataset mean. CSV parsing verified model metadata/configuration JSON. It is not preloaded into the application.

The workflow opened the platform share chooser. An independent `adb dumpsys activity activities` inspection confirmed `com.android.intentresolver/.ChooserActivityLauncher` as resumed, and the app cache listing contained `physics-results.csv`. No recipient was selected or message sent. Saving through every third-party share destination remains unverified. A later attempt to read the native cache raced the test runner's automatic uninstall and did not produce valid evidence; that failed artifact was discarded. The successfully returned `screenshots/verified-results.csv` is the verified CSV evidence.

The final source also retains uncertainty propagation form values and output in serialized experiment state, so those values survive section changes/reopen. This extension is covered by the strengthened serialization test; the earlier full Android workflow passed before that small extension. Final main-entry debug and profile builds include it.

## Android environment

- Windows 11 host; no physical Android device was connected.
- Android Emulator 37.1.11.0, dedicated `Physics_Phase1` AVD, reported model `sdk_gphone16k_x86_64`.
- Android 17 / API 37; x86_64, 16 KB-page system image already available on the host.
- Screen 720 × 1280 px at 320 dpi (360 × 640 logical).
- Emulator raised guest RAM to 4096 MB; four virtual cores requested. This is not a representative physical mid-range benchmark.
- Host GPU NVIDIA GeForce RTX 3050. Behavioral integration used Flutter software rendering; final ordinary debug launch used its normal renderer. Profile launch disabled Impeller explicitly for the local emulator compatibility check.

Early emulator/native screenshot-conversion attempts froze or exited and are **not counted as passes**. The successful workflow captures the actual rendered Flutter RepaintBoundary inside `tester.runAsync`, avoiding the native ImageReader conversion problem. Numeric dialog testing exposed a real controller-lifetime issue, which was fixed by having a dialog State own and dispose its controller after route removal. Tests were rerun successfully.

The installed JDK 25 initially failed to create loopback sockets. A short task-local `java.io.tmpdir=C:\tmp` and IPv4 preference permitted Gradle builds. Short SDK/project junction paths avoid a Windows spaces-in-path native-assets compiler issue. These workarounds are in the README/validation script, not global user configuration.

## APK

File: `deliverables/physics-atelier-phase1-debug.apk`

- Application ID: `com.indianservers.physics_atelier`
- Version: `1.0.0+1`
- Size: 253,560,976 bytes (universal **debug** APK, not optimized release packaging)
- SHA-256: `8A98098B22AA065F881266441287157A20CE15F720C6AA6A2FF6A02DA4E2E2FB`
- Built from `lib/main.dart`, not from the integration-test target.

## Remaining verification and limitations

No iOS compilation, Xcode simulator, signing or iPhone/iPad device test was possible on Windows. Follow `IOS_VERIFICATION.md`. No FPS, memory-use benchmark or physical mid-range Android performance result is claimed. A profile build/launch is a compatibility smoke test, not a performance benchmark. Additional physical-device profiling, vendor export destinations, full TalkBack/VoiceOver audit, tablet/landscape hardware QA and production database recovery/migration stress tests remain.

The visuals are procedural with material shading, not photorealistic apparatus or photographic thumbnails. Non-Measurement physical experiments and advanced Concept Overview tools explicitly remain later-phase work. The broad future curriculum equations have introductory assumptions; they are not validated completed experiment engines. Final product/educator review remains appropriate before commercial release.
