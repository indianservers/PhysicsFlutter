# Phase 6 validation

## Automated and native checks

Baseline: 147 existing unit/widget tests passed before changes. Final full suite: **181 passing tests**. `flutter analyze --no-pub`: **no issues found**. Coverage includes all earlier scientific/application regressions and the new semiconductor, nonlinear diode, transistor, amplifier, Boolean, sensor, probe, conduction/convection/radiation, ideal-gas, first-law, entropy, Carnot and deterministic-replay checks. Independent checks include a converging P–V work integral, half-step radiation comparison, current balance, ideal-gas state constraints and real sample-time Boolean edges.

All twelve new labs and all five views were walked at 320 logical pixels, 160% text and landscape. Numeric entry, invalid-state suppression, correct distance-sensor seconds, trial recording/reopening, lifecycle pausing and earned completion are checked. Completion requires an input change, a correct prediction, a real trial and nonempty explanation notes. The prior EM painter regression checks that stable state avoids rerasterization while physics/layout/camera/overlay changes still invalidate it.

Native `phase6_test.dart` passed on the dedicated Android emulator in **5 min 22 sec**, covering **33** model/process selections, twelve real observations, session reopening and actual CSV serialization. All **106** previously loaded trial objects compared equal. Machine evidence: `screenshots/phase6Validation.json` and `phase6-verified-results.csv`. There are no seeded observations in the app.

Native `phase6_modes_test.dart` passed in **2 min 7 sec**. It exercises doped neutrality, zero/reverse diode supply, all three NPN regions, inverting clipping, a live Boolean event, no-echo rejection, a finite cooling sample/probe, invalid Biot number, radiative conservation, derived isobaric state, an adiabatic process ledger saved/reopened, free expansion, finite-body contact, and all four Carnot stage boundaries. `phase6Modes.json` retains the actual checked states.

Native `phase6_storage_test.dart` passed. It creates a separate actual SQLite v2 fixture, retains an existing earlier trial's raw JSON and session note/parameters, upgrades to v3, verifies the challenge table and integrity, and round-trips a Phase 6 S/m trial. The user's main database is not replaced. `phase6Storage.json` reports 118 main-database trials loaded without a recovery warning.

The before/after native audit passed, with earlier labs, home/studios, all twelve new apparatus screens and explicit amplifier, logic-timing and Carnot plots. Original screenshots are retained; contact sheets are QA derivatives. The final ordinary APK install and independent raw SQLite comparison are reported by `phase6-preservation.json` and `phase6-validation-summary.json` after packaging.

## Environment and performance

Dedicated `emulator-5556`, AVD Physics_Phase3, Android 17 / API 37 x86_64 with 16 KB pages, 720×1280 at 320 dpi, 2 virtual cores and 2048 MB. Host Windows with RTX 3050; Flutter 3.47.8 / Dart 3.13.7. The unrelated shared emulator-5554 was left alone. Debug functional runs used software rendering with Impeller disabled. Frame measurements used **profile** mode and Skia/OpenGL, not debug/software-render timing. The normal delivered app uses its ordinary entry and default renderer.

`phase6-profile.json` contains the final measured live amplifier, radiation and Carnot cases: 90 actively pumped frames each, physical tick advancement asserted, bounded history sizes reported. `phase6-profile-initial.json` retains the earlier run; `phase6-profile-before-cache.json` records the explicit before-cache comparison. These measurements exhibit substantial raster/total-frame jank; they are **not a 60 fps claim**. Small Dart build times do not establish smooth rendering. Host scheduling, emulator graphics and app raster work have not been isolated. Physical Android GPU, memory and thermal profiling remain necessary; the earlier Phase 5 field/Boris performance problem is not claimed resolved by the redundant-paint fix.

`phase6-numerics.json` separately measures host pure-Dart cost, including allocations, after 10 warmups over 100 iterations. It also exports all 33 calculated model endpoints. These numbers are not Android frame measurements and do not negate observed emulator jank.

## Reproduction

```powershell
flutter analyze --no-pub
flutter test --no-pub
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/phase6_test.dart -d emulator-5556 --enable-software-rendering --no-enable-impeller --keep-app-running
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/phase6_modes_test.dart -d emulator-5556 --enable-software-rendering --no-enable-impeller --keep-app-running
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/phase6_storage_test.dart -d emulator-5556 --enable-software-rendering --no-enable-impeller --keep-app-running
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/phase6_audit_test.dart --dart-define=AUDIT_STAGE=after -d emulator-5556 --enable-software-rendering --no-enable-impeller --keep-app-running
flutter drive --profile --no-dds --driver=test_driver/integration_test.dart --target=integration_test/phase6_profile_test.dart -d emulator-5556 --no-enable-impeller --keep-app-running
dart run tool/phase6_specs.dart
dart run tool/phase6_numerics.dart
flutter build apk --debug --target lib/main.dart
python tool/phase6_preservation.py
```

The existing README short-temp/JDK settings apply on this Windows host. API 37 Flutter drive can wait after install until MainActivity is explicitly started with matching renderer extras. These are test-runner launch settings, not extra requirements for launching the ordinary APK. Use a dedicated device: native targets intentionally create QA observations and modify lab sessions. `--keep-app-running` and final `adb install -r` preserve the notebook.

## Remaining checks

No macOS/Xcode build or iOS device test was performed. Physical Android profiling, TalkBack/VoiceOver user testing, photographic/CAD apparatus parity, production signing and release hardening remain pending. The lab-specific bounded-model limitations are part of Learn/Formulas and the scientific specifications. No Phase 7 work was enabled.

## Recorded final frame observations

- Amplifier: median build/raster 1.203/36.035 ms; p95 build/raster 2.075/60.524 ms; p95 total 99.588 ms; 89/90 frames above 16.67 ms.
- Radiation: median build/raster 1.282/34.686 ms; p95 build/raster 3.7/53.976 ms; p95 total 90.904 ms; 89/90 frames above 16.67 ms.
- Carnot: median build/raster 1.242/35.662 ms; p95 build/raster 1.952/49.093 ms; p95 total 87.797 ms; 89/90 frames above 16.67 ms.

The before-cache medians were 75.007, 74.323 and 45.107 ms raster respectively. The cached-layer run is lower, but these are separate host/emulator runs, not an isolated causal estimate. All three still exhibit jank. The unchanged scientific calculations were not simplified to obtain these results.

## Final installed package and preservation

Ordinary APK: **210,406,059 bytes**, versionName **1.5.0**, versionCode **6**. SHA256 `92cf86134dcd0af3e7686e5ec2249f9812c8103b83f25d9a3cb4adf1418f7b1b`. Installed with `adb install -r`, force-stopped, then launched through the ordinary MainActivity without test renderer extras while airplane mode was enabled. The device's installed base.apk SHA256 exactly matches the delivered file. The offline home screen was visually inspected.

Independent SQLite comparison after this install preserved all **106 original trial JSON bodies byte-for-byte**, all **88 original challenge bodies**, and notes/parameters in all **66 original sessions**. Current main notebook: **118 trials**; schema **3**; integrity **ok**. The v2 fixture upgrade and final native visual audit also passed together. The unchanged background layers were captured in the final all-lab audit.
