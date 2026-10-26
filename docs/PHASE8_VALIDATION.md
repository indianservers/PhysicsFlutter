# Phase 8 validation

Validated on Windows with Flutter 3.47.8 / Dart 3.13.7. Native device: dedicated `emulator-5556`, AVD Physics_Phase3, Android 17/API37 x86_64, 16 KB pages, 720×1280 at 320 dpi, two cores and 2048 MB RAM. Profile rendering uses Skia/OpenGL on host RTX3050. The shared emulator was not used.

## Automated results

Final ordinary APK installed and launched in airplane mode. Version **1.7.0+8**, **211,994,295 bytes**, SHA-256 `8417f3df718495909971ce15ec8b3950df37a7e252b4a73116de042c52701515`; installed base APK hash matches the deliverable. Final analyzer: **No issues found**.

After installation, the original **130 trial bodies**, **88 challenge bodies**, and **90 earlier session notes/parameter sets** match the pre-change archive. SQLite integrity is `ok` and schema stays **3**. Current trial count is **142**, including twelve explicit astronomy observations from native validation runs. No original explicit completion preference existed; no completion history was invented to fill that absence.

- Original baseline: **223 tests passed**. Expanded unit/widget suite: **268 tests passed**, including 34 astronomy/science/content checks and 11 new widget tests. `flutter analyze --no-pub` must report no issues for the final source.
- `phase8_test.dart`: passed all 17 astronomy mode selections, all five lab sections, six calculated trial recordings, CSV/replay, six tools, five comparisons, favorite/default-backup persistence and real OS HOME/resume clock suspension.
- `phase8_boundaries_test.dart`: passed spectral resolution/redshift, FLRW z=0/z=5 and distance relations, no-transit/grazing geometry, deterministic noisy replay, and actual persisted correct attempts for all six challenge task types with full source configuration.
- `phase8_audit_test.dart`: passed screenshots of all 17 studio icons, representative earlier workspaces, all twelve new destinations, all six astronomy graphs, physical orbital scale, late stellar stages and normalized comparison. It also executes the real SQLite v2→v3 isolated fixture in `phase8_storage_test.dart`, preserving old serialized trial body and notes/parameters, then round-tripping astronomy, comparison and mastery data.
- `phase8_profile_test.dart`: passed five active scenes with actual model time/tick advancement and 90 measured frames each. It does not substitute a static screen for playback.

Numerical checks include independent cosmology quadrature, J2000 references, conservation/period consistency, MIST interpolation/bounds, Planck conventions, line shifts/resolution, galaxy force derivatives, SPARC errors, overlap limits, seeded noise, source-model comparison identity, all 16 answer references, catalog uniqueness, link validity and acyclic prerequisites. Widget checks include small screens, 160% text, landscape, state restoration, protected incompatible sessions, backed-up defaults, evidence-based completion and rejected invalid parameter targets.

## Honest performance observations

The five profile cases were orbit, stellar evolution, transit, spring/pendulum comparison and classical/matter-wave comparison. Median build times were **1.604, 1.605, 1.231, 1.512 and 1.631 ms**; median raster times were **49.213, 37.608, 39.514, 37.708 and 33.851 ms**. Raster p95 was **82.181, 65.002, 68.523, 56.631 and 58.267 ms**. Respectively **89, 89, 88, 89 and 81 of 90** total frame spans exceeded 16.67 ms. Emulator raster jank is an open gap; no physical-device or 60 fps claim is made.

`screenshots/phase8-profile.json` holds raw percentiles/ticks. Separately, the warmed host JIT benchmark (seven repeats) measured a complete 121-point/1024-panel cosmology profile at median 5.628 ms, adaptive synthetic spectrum at 4.425 ms, 100 cached orbital time changes at 4.074 ms and 1000 matter detections at 0.180 ms. These are model timings, not mobile frame timings.

## Native automation qualification

Tests drive Flutter controls and record actual computed/persisted results. Android native IME sometimes supplies a stale empty editing update after test text entry and keyboard dismissal. The boundary harness commits the intended response to the same controller immediately before awaiting the actual submit callback; choice/dropdown callbacks are also invoked through their rendered controls. It never seeds attempt/result rows or substitutes precomputed history. This is automated callback/control validation, not a claim of manual physical-keyboard, TalkBack or VoiceOver testing.

Earlier unsuccessful boundary harness runs and one initial audit-selector failure were corrected; only final passing runs are counted. Those runs retain their explicitly recorded practice/trial history. Original user records are never cleared to simplify tests.

## Reproduction

Run host checks with `flutter analyze --no-pub` and `flutter test --no-pub`. Use short host TEMP/TMP paths as described in README. For each native target use a **fresh** redirected log:

```powershell
flutter drive --no-pub --driver=test_driver/integration_test.dart --target=integration_test/phase8_test.dart -d emulator-5556 --enable-software-rendering --no-enable-impeller --keep-app-running *> C:\tmp\phase8-new.log
```

In a second terminal run `python tool/phase8_device_watch.py C:\tmp\phase8-new.log`. This host/API37 needs explicit post-install activity launch; the companion also performs real HOME/resume at the lifecycle sentinel. Repeat for `phase8_boundaries_test` and `phase8_audit_test`. For `phase8_profile_test`, replace software-rendering with `--profile --no-dds`, retain `--no-enable-impeller`, and give the watcher `--profile`. Do not run competing builds/tests during frame measurement.

Finally build `flutter build apk --debug --target lib/main.dart --no-pub`, copy to `deliverables/physics-atelier-phase8-debug.apk`, install with `adb install -r`, and launch the ordinary activity offline. Run `python tool/phase8_preservation.py` and `python tool/phase8_summary.py` to verify the installed hash and original archive preservation. The pre-change binary-safe notebook archive stays local at `C:\tmp\phase8-baseline-exact.tar` and is excluded from Git.

Machine evidence: `phase8Validation.json`, `phase8Boundaries.json`, `phase8Storage.json`, `phase8-profile.json`, `phase8-preservation.json` and `phase8-validation-summary.json` under `screenshots/`. Preservation compares original trial/challenge serialized bodies, old notes and parameters, non-navigation preferences and SQLite integrity/schema. Profile scenes save ordinary sessions but add no fabricated scientific trials.

The [handover](PHASE8_HANDOVER.md) lists remaining scientific, visual, accessibility, iOS, performance and release checks. Phase 9 remains pending.
