"""Generate the Phase 7 handover from verified deliverable evidence."""
import json
from pathlib import Path
root=Path(__file__).resolve().parents[1]
def read(name):return json.loads((root/'screenshots'/name).read_text(encoding='utf-8'))
s=read('phase7-validation-summary.json');p=s['preservation'];b=read('phase7-model-benchmark.json')
lines=[]
for lab in ['s14-e03','s14-e04','s15-e02','s15-e05']:
 f=s['profile'][lab]
 lines.append(f"- `{lab}`: {f['frameCount']} frames, ticks {f['startTicks']}→{f['endTicks']}; build median/p95 {f['medianBuildMs']:.3f}/{f['p95BuildMs']:.3f} ms; raster median/p95 {f['medianRasterMs']:.3f}/{f['p95RasterMs']:.3f} ms; total p95 {f['p95TotalMs']:.3f} ms; {f['framesOver16_67Ms']} frames over 16.67 ms.")
profile='\n'.join(lines)
validation=fr"""# Phase 7 validation

Verified {s['verifiedUTC']}. Model `fluid-modern-7.0`, app1.6.0+7. See [machine summary](../screenshots/phase7-validation-summary.json), [scientific methods](PHASE7_SCIENCE.md) and [per-lab specifications](PHASE7_LAB_SPECIFICATIONS.md).

## Automated checks

- `flutter analyze --no-pub`: No issues found.
- `flutter test --no-pub`: **223 tests passed**. Baseline181 passed independently before changes; new 36 pure scientific tests and 6 widget tests cover all twelve labs, all five sections, every model selection, 160% text, narrow portrait/landscape, lifecycle/reduced motion, invalid-state recording, replay, graph units and earned completion.
- Scientific tests cover hydrostatic gradients/interfaces/conserved volume; exact immersed geometry; circular continuity and local tracer arclength speed; Bernoulli energy/pressure bounds; Stokes analytic transient, arrival, radius-squared scaling and Re; well normalization/stationarity/analytic-CDF sampling; photoelectric threshold/QE/flux/retarding collection; de Broglie and voltage relations; conditional detector normalization/grid convergence; vacuum hydrogen/series limits; atomic-mass binding convention; half-life/activity; seeded replay at exact endpoints; independent detector streams; billion-atom conservation.
- Stochastic tolerances are statistical: binomial/Poisson ensembles against analytical moments with standard-error bounds, well 20,000-event analytic-CDF goodness-of-fit, deterministic PRNG vector and exact same-seed replay. No requirement that a random histogram exactly match its expectation.
- `phase7_test.dart`: all 12 new labs, all **{s['nativeModelSelections']}** selections, all 5 sections, numeric edits, actual calculated recordings, save/reopen exact scalar equality, CSV with full configuration. **{s['nativeNewTrialCount']}** explicit integration-test observations added; no preloaded app results.
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

{profile}

These emulator measurements include raster jank; **no 60 fps or physical-phone performance claim**. A p95 total span includes scheduling/pipeline delay and is not the sum of p95 build/raster. Device/GPU validation remains required. Static nuclear/spectra views are not represented as active-playback benchmarks.

Warmed host Dart JIT microbenchmarks (7 repetitions; not mobile frame timings): matter 4096-grid CDF build median {b['matter4096CdfBuild']['medianMs']:.3f} ms; 100 cached pipe-probe changes median {b['100CachedPipeProbeChanges']['medianMs']:.3f} ms; full 2400-tick billion-atom decay replay median {b['billionAtomsFull2400TickReplay']['medianMs']:.3f} ms. Raw endpoints/method in [benchmark evidence](../screenshots/phase7-model-benchmark.json). Geometry/CDF caches avoid rebuilding for unrelated probe/mass/seed edits; histories/positions/text caches are bounded, hidden tickers stop, reduced motion throttles visual updates and hides moving markers.

## Installed APK and preservation

Ordinary **`lib/main.dart` debug APK**, not an integration target, built with `flutter build apk --debug --target lib/main.dart`. Version 1.6.0+7, {s['bytes']} bytes. Local handoff `deliverables/physics-atelier-phase7-debug.apk`; SHA-256 `{s['sha256']}`. Installed base APK hash independently matches the handoff. Upgrade installation retained the notebook; ordinary launcher starts offline with airplane mode enabled. [Installed screenshot](../screenshots/phase7-installed-offline-home.png).

Exact binary-safe original sandbox backup `C:\tmp\phase7-baseline-exact.tar` stays local. Final comparison: **{p['originalTrialBodiesByteForBytePreserved']} original trial JSON bodies**, **{p['originalChallengeBodiesExactlyPreserved']} challenge bodies**, **{p['oldSessionNotesAndParametersPreserved']} old session notes/parameters** preserved. Current trials {p['currentTrials']}; schema 3 unchanged; integrity `{p['integrity']}`. Baseline had no explicit completion preference; no native test fabricates earned completion. Navigation history may change as labs are visited. Scripts also compare any original non-navigation preferences. [Preservation evidence](../screenshots/phase7-preservation.json).

## Reproduction on this Windows host

Use the short Flutter junction, dedicated emulator and temp/JDK settings from README. Redirect each drive invocation to a fresh log; run `python tool/phase7_device_watch.py C:\tmp\<log>.log` alongside it (`--profile` for the profile target). The watcher explicitly launches after installation for this API37 host's launch issue; in the boundary target it also performs real HOME/resume when the test requests it. It operates only on emulator-5556. Other devices need their own deliberate OS background/resume action. Keep `--keep-app-running`; do not clear data or run preserve tests on a shared/user device without a backup. Profile screenshots/correctness tests and frame measurements are separate runs.

`tool/validate.ps1` includes Phase 7 all-lab/storage/audit checks; real-OS modes and profile commands are separate as documented above. `tool/phase7_specs.dart` regenerates per-lab ranges, `phase7_benchmark.dart` regenerates host model timings; `phase7_preservation.py`, `phase7_summary.py` and `phase7_report.py` verify/assemble final handoff evidence after ordinary installation.

## Remaining checks

No macOS/Xcode available: iOS compilation, signing and device verification not performed. Physical Android profiling, independent accessibility/TalkBack user testing, photographic apparatus parity, production signing/store release hardening remain. Supported models are intentionally bounded; no turbulence, capillarity, real quantum trajectories, nuclear stability prediction, daughter chains, quantitative shielding or dose model. Astronomy and advanced Concept Overview remain Phase 8. No Phase 8 work included.
"""
(root/'docs/PHASE7_VALIDATION.md').write_text(validation,encoding='utf-8')
handover=fr"""# Phase 7 completion report

Implemented **twelve Fluid Mechanics and Modern Physics labs**, bringing the app to **90 interactive labs**, 17 studios and 102 unchanged destinations. Existing 78 labs, notes, trials, attempts and model decoding remain available. Phase 8 has not started.

Fluid Mechanics: Density & Pressure, Hydrostatics, Buoyancy, Continuity, Bernoulli, Viscosity. Modern Physics: Quantum Ideas, Photoelectric Effect, Matter Waves, Atomic Spectra, Nuclear Structure, Radioactivity. Each has Learn, Experiment, Visualize, Formulas and Results with numerical/drag controls, actual calculations, limits, predictions, notes, earned completion, save/reopen and CSV. Seeded distributions/decay include explicit simulation labels, versioned reproducibility and correct units. No fabricated experimental data.

Targeted earlier-module work replaces the misleading classical-orbit Modern Physics icon with a stationary well diagram and extends shared plots with actual histogram bars/discrete points. Prior apparatus and science remain intact. All 12 new apparatus scenes and representative older modules were captured/reviewed before/after.

- **APK:** `deliverables/physics-atelier-phase7-debug.apk`, ordinary offline Android 1.6.0+7, debug signing, {s['bytes']} bytes. APKs are local handoffs excluded from Git; checksum/evidence and source are versioned.
- **Validation:** analysis clean; 223 unit/widget tests; 29 native selections; boundary/seeded replay, actual OS lifecycle, real v2→v3 fixture migration and active profile checks passed.
- **Preservation:** {p['originalTrialBodiesByteForBytePreserved']} old trial bodies, {p['originalChallengeBodiesExactlyPreserved']} challenge bodies and {p['oldSessionNotesAndParametersPreserved']} old session notes/parameters retained; SQLite integrity ok, schema 3.
- **Installed verification:** delivered/installed APK SHA-256 matches; normal launcher works in airplane mode. No push, deployment or Phase 8 implementation.

Read [scientific methods and sources](PHASE7_SCIENCE.md), [per-lab specifications](PHASE7_LAB_SPECIFICATIONS.md), [asset provenance and audit](PHASE7_ASSETS_AND_AUDIT.md), [validation/performance](PHASE7_VALIDATION.md) and [machine evidence](../screenshots/phase7-validation-summary.json).

Remaining gaps: shaded procedural illustrations still fall short of photographic target art; emulator raster jank remains and physical-device performance is unverified. iOS requires macOS/Xcode verification. Independent accessibility user testing and production signing/release hardening remain. The app is a bounded educational simulation, not a radiation-safety/dose calculator or a store-ready release.
"""
(root/'docs/PHASE7_HANDOVER.md').write_text(handover,encoding='utf-8')
print('Generated Phase 7 validation and handover from verified evidence')
