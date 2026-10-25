# Phase 7 validation

Verified 2026-10-25T23:25:09.851851+00:00. Model `fluid-modern-7.0`, app1.6.0+7. See [machine summary](../screenshots/phase7-validation-summary.json), [scientific methods](PHASE7_SCIENCE.md) and [per-lab specifications](PHASE7_LAB_SPECIFICATIONS.md).

## Automated checks

- `flutter analyze --no-pub`: No issues found.
- `flutter test --no-pub`: **223 tests passed**. Baseline181 passed independently before changes; new 36 pure scientific tests and 6 widget tests cover all twelve labs, all five sections, every model selection, 160% text, narrow portrait/landscape, lifecycle/reduced motion, invalid-state recording, replay, graph units and earned completion.
- Scientific tests cover hydrostatic gradients/interfaces/conserved volume; exact immersed geometry; circular continuity and local tracer arclength speed; Bernoulli energy/pressure bounds; Stokes analytic transient, arrival, radius-squared scaling and Re; well normalization/stationarity/analytic-CDF sampling; photoelectric threshold/QE/flux/retarding collection; de Broglie and voltage relations; conditional detector normalization/grid convergence; vacuum hydrogen/series limits; atomic-mass binding convention; half-life/activity; seeded replay at exact endpoints; independent detector streams; billion-atom conservation.
- Stochastic tolerances are statistical: binomial/Poisson ensembles against analytical moments with standard-error bounds, well 20,000-event analytic-CDF goodness-of-fit, deterministic PRNG vector and exact same-seed replay. No requirement that a random histogram exactly match its expectation.
- `phase7_test.dart`: all 12 new labs, all **29** selections, all 5 sections, numeric edits, actual calculated recordings, save/reopen exact scalar equality, CSV with full configuration. **12** explicit integration-test observations added; no preloaded app results.
- `phase7_modes_test.dart`: two-fluid volume/pressure balance, gauge reference invariance, partial held/bottom-supported blocks, actual circular flow, rejected Venturi pressure and Stokes Re, exact finite Stokes arrival, seeded 100-event well replay and matter detections, below-threshold/stopped current, vacuum Hα emission/absorption, sourced carbon-12 and billion-atom decay with zero detected counts at zero efficiency/background.
- Real OS lifecycle companion used Android HOME and resumed the same activity. Observed `inactive→hidden→paused→hidden→inactive→resumed`; no automatic clock restart or time jump. The widget lifecycle test is separate and synthetic.
- `phase7_audit_test.dart --dart-define=AUDIT_STAGE=after`: representative prior studios/labs, all twelve new apparatus scenes, graph captures and unit metadata. Registers `phase7_storage_test.main()` as a separate native test: a real separate SQLite v2 fixture upgrades to v3, retains the original trial JSON byte-for-byte and old note/parameters, creates the attempts table and round-trips an activity/Bq trial. Main notebook is never replaced by the fixture; recovery notice is null.
- `phase7_profile_test.dart --profile --no-dds --no-enable-impeller`: active-clock assertions and actual engine FrameTiming, detailed below.

Two harness issues were corrected during native validation: an offscreen scene finder needed scrolling back to its apparatus, and a dynamic profile control argument needed double 1.0. Final reruns passed; no physical result or tolerance was changed to accommodate those failures.

## Android apparatus and visual audit

Dedicated **emulator-5556**, AVD Physics_Phase3, Android 17/API37, x86_64, 16 KB pages, 720×1280 at 320 dpi, 2 cores / 2048 MB. Shared emulator-5554 untouched. Native correctness/screenshots used software rendering without Impeller; profile used Skia/OpenGL with host RTX3050. Captures are actual Flutter-rendered native app widgets; the final offline image is a binary-safe Android screencap. All new apparatus, graph/contact sheets and representative old modules were visually inspected. See [assets/audit](PHASE7_ASSETS_AND_AUDIT.md).

Evidence: `phase7-s14-e00…05.png`, `phase7-s15-e00…05.png`; `phase7-mode-*.png` for boundaries/alternative states; `phase7-graph-*.png` for real bars/curves; `phase7-before-*`/`phase7-after-*` for earlier-module audit and stationary Modern Physics icon correction. Histogram mode screenshots show apparatus with that graph selected; dedicated graph captures show the actual histograms.

## Actual performance observations

Four representative scenes, 90 requested playback frames per case after a 2-second warm-up, engine timings collected through a final 1-second flush. Actual advanced ticks are asserted; no idle screenshot benchmark. No heavy host test/build ran concurrently with the measured frames.

- `s14-e03`: 90 frames, ticks 3→542; build median/p95 1.287/3.484 ms; raster median/p95 40.650/65.804 ms; total p95 116.129 ms; 85 frames over 16.67 ms.
- `s14-e04`: 90 frames, ticks 2→480; build median/p95 1.279/3.104 ms; raster median/p95 41.541/55.001 ms; total p95 98.333 ms; 89 frames over 16.67 ms.
- `s15-e02`: 90 frames, ticks 6→549; build median/p95 1.338/3.958 ms; raster median/p95 41.686/73.041 ms; total p95 116.601 ms; 89 frames over 16.67 ms.
- `s15-e05`: 90 frames, ticks 4→601; build median/p95 1.411/8.087 ms; raster median/p95 46.280/92.628 ms; total p95 152.859 ms; 87 frames over 16.67 ms.

These emulator measurements include raster jank; **no 60 fps or physical-phone performance claim**. A p95 total span includes scheduling/pipeline delay and is not the sum of p95 build/raster. Device/GPU validation remains required. Static nuclear/spectra views are not represented as active-playback benchmarks.

Warmed host Dart JIT microbenchmarks (7 repetitions; not mobile frame timings): matter 4096-grid CDF build median 1.167 ms; 100 cached pipe-probe changes median 1.699 ms; full 2400-tick billion-atom decay replay median 16.895 ms. Raw endpoints/method in [benchmark evidence](../screenshots/phase7-model-benchmark.json). Geometry/CDF caches avoid rebuilding for unrelated probe/mass/seed edits; histories/positions/text caches are bounded, hidden tickers stop, reduced motion throttles visual updates and hides moving markers.

## Installed APK and preservation

Ordinary **`lib/main.dart` debug APK**, not an integration target, built with `flutter build apk --debug --target lib/main.dart`. Version 1.6.0+7, 210758318 bytes. Local handoff `deliverables/physics-atelier-phase7-debug.apk`; SHA-256 `109519e335287c959a648081b3bc7ce688f4319c2aa2e0a4fc47b4a9f186bf6e`. Installed base APK hash independently matches the handoff. Upgrade installation retained the notebook; ordinary launcher starts offline with airplane mode enabled. [Installed screenshot](../screenshots/phase7-installed-offline-home.png).

Exact binary-safe original sandbox backup `C:\tmp\phase7-baseline-exact.tar` stays local. Final comparison: **118 original trial JSON bodies**, **88 challenge bodies**, **78 old session notes/parameters** preserved. Current trials 130; schema 3 unchanged; integrity `ok`. Baseline had no explicit completion preference; no native test fabricates earned completion. Navigation history may change as labs are visited. Scripts also compare any original non-navigation preferences. [Preservation evidence](../screenshots/phase7-preservation.json).

## Reproduction on this Windows host

Use the short Flutter junction, dedicated emulator and temp/JDK settings from README. Redirect each drive invocation to a fresh log; run `python tool/phase7_device_watch.py C:\tmp\<log>.log` alongside it (`--profile` for the profile target). The watcher explicitly launches after installation for this API37 host's launch issue; in the boundary target it also performs real HOME/resume when the test requests it. It operates only on emulator-5556. Other devices need their own deliberate OS background/resume action. Keep `--keep-app-running`; do not clear data or run preserve tests on a shared/user device without a backup. Profile screenshots/correctness tests and frame measurements are separate runs.

`tool/validate.ps1` includes Phase 7 all-lab/storage/audit checks; real-OS modes and profile commands are separate as documented above. `tool/phase7_specs.dart` regenerates per-lab ranges, `phase7_benchmark.dart` regenerates host model timings; `phase7_preservation.py`, `phase7_summary.py` and `phase7_report.py` verify/assemble final handoff evidence after ordinary installation.

## Remaining checks

No macOS/Xcode available: iOS compilation, signing and device verification not performed. Physical Android profiling, independent accessibility/TalkBack user testing, photographic apparatus parity, production signing/store release hardening remain. Supported models are intentionally bounded; no turbulence, capillarity, real quantum trajectories, nuclear stability prediction, daughter chains, quantitative shielding or dose model. Astronomy and advanced Concept Overview remain Phase 8. No Phase 8 work included.
