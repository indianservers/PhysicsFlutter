# Phase 2 validation — 25 October 2026

## Environment and artifacts

Windows host; Flutter 3.47.8 stable, Dart 3.13.7. Android emulator `emulator-5554`, AVD Physics_Phase1, Android 17/API 37, x86_64 16 KB image, 720×1280 at 320 dpi, four virtual cores and 4096 MB RAM. Host GPU: RTX 3050. No physical Android device or macOS/Xcode was available.

Ordinary debug and profile APK builds from `lib/main.dart` succeeded. The debug deliverable is `deliverables/physics-atelier-phase2-debug.apk` (177,106,083 bytes), version 1.1.0+2. It was installed with `adb install -r` and launched successfully, preserving application data. APK checksum is recorded alongside the deliverable.

## Automated and native checks

- Baseline: all 17 Phase 1 tests passed before changes.
- Final `flutter analyze`: no issues found. Final `flutter test`: all 42 tests passed. Scientific tests cover vectors, friction thresholds and dissipation, constraints, torque, COM, collisions, analytical trajectories, relative frames, circular motion, action/reaction, boundary behavior, deterministic replay and bounded history. A detached-trial snapshot regression protects saved observations from later parameter edits.
- Widget checks exercise every section of all eighteen new labs at 320×568 with 160% text, scroll through controls, check landscape, and perform an actual parameter edit, single step, prediction, recording and reopening.
- `integration_test/phase2_test.dart`: passed on the Android emulator (8m35s). All eighteen labs were opened via search, edited, played/paused, stepped, replayed, recorded, read through a fresh repository, challenged and reopened. Actual CSV and eighteen native screenshots were captured.
- `integration_test/phase1_test.dart`: passed on the new application (1m51s), exercising all six Measurement labs and recording eight observations.
- `integration_test/phase2_modes_test.dart`: passed (5m30s), including movable-pulley topology, suspended COM, piecewise graphs, relative-frame time preservation, table-contact mode and lifecycle pause/resume. The initial lifecycle harness awaited a frame while paused; an actual Home/resume cycle released it. The harness now resumes before pumping.
- Migration uses an isolated real version-2 SQLite fixture containing a Measurement trial; schema-3 upgrade preserves it and creates the attempts table. The original installed baseline notebook contained zero trials, so preservation of pre-existing real user observations cannot be claimed. Subsequent native runs preserved the newly recorded trials.

## Performance evidence

`integration_test/phase2_profile_test.dart` passed in profile mode, sampling ninety frames each for free-body forces, circular motion and multiple forces. Results in `screenshots/phase2-profile.json`:

- Free-body: median build 1.700 ms, p95 build 5.010 ms; median raster 1.786 ms, p95 raster 6.943 ms; p95 total 34.538 ms; 47/90 totals exceeded 16.67 ms.
- Circular: median build 0.990 ms, p95 build 2.890 ms; median raster 1.480 ms, p95 raster 3.986 ms; p95 total 35.003 ms; 31/90 totals exceeded 16.67 ms.
- Multiple forces: median build 1.186 ms, p95 build 3.833 ms; median raster 2.268 ms, p95 raster 7.729 ms; p95 total 33.056 ms; 36/90 totals exceeded 16.67 ms.

These emulator measurements show remaining total-frame jank and do not prove a 60 fps target. Physical midrange-device profiling remains required. Debug/software-rendered workflow timings are separately retained in `phase2-performance.json` and are not a release benchmark. Graph history is capped at 301 samples and graph repaints follow sampled changes.

## Reproduction and outstanding checks

`tool/validate.ps1` runs analysis, unit/widget tests, Measurement regression, Phase 2 native workflows and the ordinary debug build. It retains app installation; native tests add explicitly generated observations to the notebook. Run the profile target separately with `flutter drive --profile --no-dds --no-enable-impeller --keep-app-running --driver=test_driver/integration_test.dart --target=integration_test/phase2_profile_test.dart -d emulator-5554`.

This host uses short-path Flutter/project junctions and short TEMP for JDK 25. Occasionally the Android 17 driver stalled after installation; explicitly starting the installed MainActivity allowed VM-service attachment. Profile capture uses manual FrameTiming callbacks because the initial VM/DDS timeline collector could not connect on this host.

Remaining: physical-device performance/accessibility QA, iOS compilation and device QA (see IOS_VERIFICATION.md), photorealistic visual parity and store-release signing. Android emulator evidence must not be presented as those checks.
