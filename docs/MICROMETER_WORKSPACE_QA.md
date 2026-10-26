# Micrometer reference workspace — 1.8.1+10

The Micrometer is now an apparatus-first instrument with a floating, draggable scale lens, a full-screen precision-reading view, millimetre controls, signed zero correction, a 0.01 mm fine step, and Record/Reset actions. The permanent five-destination bar is removed from all 96 physical labs and their contextual readers. Learn, Formulas, Visualize, Results and Save are available from the compact toolbar menu. Graph/visualization uses the existing shared pane rather than an additional article page. Home and all 17 compact studio launchers are retained and were captured again.

## Scientific review

Reference: [Mitutoyo, Quick Guide to Measurement: Micrometers, page 8](https://www2.mitutoyo.co.jp/eng/useful/E11003/pdf/10.pdf). Its standard-scale example is 7.00 mm sleeve +0.37 mm thimble =7.37 mm, with 0.01 mm graduations. The implementation and tests use that example, half-millimetre boundaries, rollover, signed zero errors and the existing defined 0.5 mm/revolution, 50-division model. The drawing is original procedural geometry; no manufacturer image was copied.

`MicrometerGeometry` is shared by apparatus rendering, lens focus and hit mapping. Fixed anvil and moving spindle faces oppose on one measurement axis. Their separation is the existing physical opening, and the object remains between them. The existing rigid-object stop prevents penetration; this does not model ratchet torque, contact-force deformation, thermal expansion, wear or a professional instrument's full uncertainty budget. The ratchet is a distinguishable mechanical part, not a simulated force sensor. An Open gap/Contact cue distinguishes an open instrument from object contact.

The sleeve half-millimetre marks and rotating thimble's50 divisions are derived from the same measurement state as the readout. Pitch and resolution remain 0.5 mm/revolution and0.01 mm/division. Fine input uses the existing model's quantization; no new sub-division measurement mode is claimed. Existing object-contact constraints and full SI configuration are retained. The drawing/readouts depict the model's quantized indication; optional full calculated correction values remain available in Formulas and saved SI data. Display rounding does not change stored values or the model identifier `measurement-1.0`.

The lens paints a crop of the same scale renderer, not a second independently drawn scale. Its position is UI state only. A full-screen precision reader shares the original Experiment instance and includes fine controls and actual sleeve/thimble values.

## Gesture and layout corrections

- The normal portrait workflow uses the standard compact app bar, scientific viewport, observed/zero/corrected strip, two-row control dock and fixed safe-area action strip. No page-level scroll is required for the typical portrait Micrometer workflow. Larger text may scroll the bounded dock.
- Explicit camera mode owns pan/pinch; apparatus mode leaves the apparatus gesture arena unobstructed. Passive transforms replace competing camera recognizers in all eight working apparatus families. Real Micrometer thimble drags now change the model; camera and lens movement do not.
- Lens controls and precise entry are normal accessible widgets; no accessibility text scaling was disabled. Numeric buttons have bounded wrapping widths instead of overflowing narrow landscape panels.
- Record feedback no longer blocks Reset: the compact action row occupies a fixed safe-area slot, so snackbar feedback appears above it.
- Direct lab routes have a Back fallback to their studio. Full-screen Back returns to the working scene without resetting the experiment.
- Secondary Micrometer controls retain object settings, notes and investigation functions; the obsolete separate apparatus/readout/magnification cards are omitted from that sheet. The previous complete theory and formulas remain accessible.
- Astronomy graph panes no longer duplicate an apparatus card; legend labels wrap at large text sizes. Existing cursor-to-physical-state and observational-error-bar checks still pass.

## Actual evidence

- 295 unit/widget tests passed, including the existing scientific suite and five new Micrometer geometry/interaction cases. All102 default destinations were checked at 200% text on small portrait and landscape surfaces; existing studio/tablet and keyboard checks also remain in the suite.
- Clean full Flutter analysis was run. Final native rendering and interaction checks use the dedicated Physics_Phase3 emulator, **emulator-5556**, Android17/API37 x86_64, 16 KB pages, 720×1280 at 320 dpi,2 cores/2048MB RAM. Captures use debug/software rendering; they are actual application frames, not mockups.
- Native Micrometer checks cover real thimble dragging, camera-only pan, lens movement, full-screen return, the 7.37 mm scale example, precise zero entry, positive and negative zero correction, record/reset, trial reopen, CSV encoding and one preserved model instance.
- Home, all 17 studios and all 102 entry destinations were captured. Every physical entry exposes Record and has no permanent section NavigationBar. Native inventory capture proves rendering/action visibility; it does not claim a new human drag test for every individual apparatus.
- The optional Android instrumentation reporting channel prints a post-teardown warning on this SDK. The Dart VM integration driver still returned the capture inventory and baseline-restoration results successfully; Android instrumentation reporting is not claimed.
- Current APK installation hashes, offline launch checks and preservation counts are recorded in `screenshots/micrometer-build-verification.json` and `screenshots/micrometer-preservation.json`. Original trial/attempt JSON bodies and original session states/preferences are compared against a private baseline taken before this request. Explicitly recorded simulated QA trials remain labeled and are not deleted.

The supplied attachment directory contained the written brief but no image file. `micrometer-before.png` is the existing saved running-app capture from the previous compact-workspace build; it does not reproduce every older Phase1 label described in the brief. Before/after and all-studio links are in [the screenshot index](MICROMETER_SCREENSHOTS.md). Full inventory verification is in [the checklist](MICROMETER_MIGRATION.csv).

## Build and remaining issues

Local artifacts: `deliverables/physics-atelier-micrometer-debug.apk` and `deliverables/physics-atelier-micrometer-release-dev-signed.apk`. Both use the ordinary `lib/main.dart` entrypoint and the existing development/debug signing certificate. They are not production-signed store releases.

```powershell
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --target lib/main.dart --no-pub
flutter build apk --release --target lib/main.dart
```

Flutter3.47.8/Dart3.13.7 were used. Build modes must run sequentially; on this SDK the normal release command regenerates the release plugin registry correctly. Native preservation QA uses a private sandbox file rather than large compiler defines; see the updated native-fixture instructions in WORKSPACE_HANDOVER.md. Neither private fixture form nor the raw baseline is committed or included in ordinary APKs.

Remaining: physical Android performance/thermal and complete human accessibility review; iOS/Xcode/VoiceOver/device validation on a suitable host; production signing and existing source/data redistribution-license review. The procedural materials are improved but are not photographs. No new frame-rate or metrology certification is claimed. Historical Phase9 profiles are not new benchmarks for this revision. Nothing was uploaded or published.
