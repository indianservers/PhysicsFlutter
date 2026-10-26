# Physics Atelier — reference-style workspaces (1.10.0+13)

Offline Flutter physics learning application for Android, with an iOS source foundation.

Repository: https://github.com/indianservers/PhysicsFlutter

Project directory: `C:\Indian Servers\Android Physics`. The supplied `Target UI` folder remains intact and ignored. Runtime copies in `assets/reference_previews` provide static launcher thumbnails; their provenance remains user-supplied.

## Included

- Spherometer with three fixed legs, contact-limited screw, plane-reference subtraction, signed measured curvature, Top/Section views and scale magnification.
- Heat Transfer material bench: 36 named records, with 16 solid-conduction and 13 heating presets enabled where the required sourced properties exist; equal-condition comparison, heating and composite/contact resistance.
- Shared optical bench from Reflection, Refraction, Lenses and Mirrors: 40 named component entries with explicit section/3D scopes, eight material presets, analytic boundary tracing and 12 guided investigations. Geometry, source and actual branch observations can be saved, reopened and exported.

- 17 studio pages, six exact entries each, 102 stable destinations.
- Search across studio names, entry names and principles; real Continue Learning and explicit activity completion.
- All 96 physical labs open directly into a compact apparatus workspace, with bounded primary controls, live readings, meaningful actions and contextual Learn/Formulas/Results. Scene, graph, split data and fullscreen views share the original scientific state.
- Compact Home and 17 studio launchers use distinct model-derived apparatus previews. All six overview tools have purpose-specific working layouts.
- Local pane preferences, camera/interaction modes, resizable splits and selected-trial details, recorded comparison, CSV export and safe configuration reopening.
- Six interactive Measurement instruments: ruler, external vernier caliper, micrometer, spherometer, simulated balance/track/stopwatch, and uncertainty analysis.
- Eighteen additional interactive Mechanics, Motion & Kinematics, and Force & Newton’s Laws labs, with deterministic simulation, graphs, challenges and saved trials.
- Eighteen Work/Energy/Power, Gravitation and Oscillations labs; shared material upgrades and distinct studio previews. New calculations use model `energy-gravity-oscillation-3.0`; earlier saved models remain supported.
- Twelve Waves & Sound and Optics labs using model `waves-optics-4.0`: analytic waves/pulses/coherent fields, fixed-end modes, generated/native microphone FFT, retarded-time collinear Doppler, vector reflection/Snell, lenses/mirrors and optical interference/diffraction.
- Twelve Electricity and Magnetism labs using `electromagnetism-5.0`, including a real terminal-graph DC circuit builder/MNA solver, connected/isolated plates and RC modes, Boris 3-D trajectories and finite-loop induction flux.
- Twelve Electronics and Thermodynamics labs using `electronics-thermal-6.0`, including diode/transistor/op-amp models, calibrated sensor transfers, thermal expansion, radiation and thermodynamic cycles.
- Twelve Fluid Mechanics and Modern Physics labs using `fluid-modern-7.0`: conserving manometers, exact block immersion, circular continuity/Bernoulli, low-Re Stokes motion, stationary quantum wells, photoelectric current, conditional matter-wave detections, hydrogen spectra, sourced isotope binding energy and seeded aggregate decay.
- Drag and precise numeric controls, magnified scales, signed calibration correction, guided reading practice, recorded trials and notes.
- Local SQLite notebook, versioned sessions, reopen, CSV file sharing; preferences and recovery notices.
- Six Astronomy & Astrophysics labs using `astronomy-8.0`: frozen J2000 Kepler orbits, sourced MIST stellar tracks, synthetic spectra, galaxy rotation with optional SPARC observations, flat FLRW distances, and exact uniform-star transit overlap.
- Six Concept Overview tools: Physics Atlas, Relationship Map, eight Guided Paths, Experiment Launcher, five Compare Phenomena workspaces, and a validated 16-question Mastery Challenge bank covering six task types. One catalog supplies all 96 lab routes, favorites, saved configurations and real completion progress.

Live graphics remain procedural instrument drawings with generated material textures. Studio launchers now use cropped user-supplied reference previews. Live apparatus photography remains a visual quality gap relative to the targets; the application is not pixel-identical. iOS compilation and device QA are pending. See the handover for precise limits; this is not a claim of store-release readiness.

Micrometer now has opposed measuring faces, a state-linked sleeve/thimble, a floating magnifier and precision controls. All physical labs use the reference four-item Learn / Labs / Results / Profile footer, with camera tools and advanced investigation settings in the contextual menu.

Current UI audit: [Target UI audit](docs/TARGET_UI_AUDIT.md), [102-entry checklist](docs/TARGET_UI_SCREEN_AUDIT.csv), [asset provenance](docs/TARGET_UI_ASSETS.json).

Earlier physics feature upgrade: [materials and Spherometer QA](docs/MATERIALS_AND_SPHEROMETER_QA.md), [source/availability inventory](docs/MATERIAL_LIBRARY_INVENTORY.json), [running-app screenshots](docs/LIBRARY_SCREENSHOTS.md). Open Heat Transfer or one of the four optical labs and use the toolbar library icon.

Earlier copy cleanup: [learner-facing text audit](docs/LEARNER_COPY_AUDIT.md).

Micrometer workspace evidence: [Micrometer QA](docs/MICROMETER_WORKSPACE_QA.md), [before/after and every studio](docs/MICROMETER_SCREENSHOTS.md), [102-entry checklist](docs/MICROMETER_MIGRATION.csv).

Earlier implementation, evidence and limitations: [handover](docs/WORKSPACE_HANDOVER.md), [QA](docs/PHASE9_QA.md), [102-entry verification](docs/WORKSPACE_MIGRATION.csv). Historical Phase 1–8 reports describe their corresponding earlier builds.

## Setup and run

Validated SDK: Flutter **3.47.8 stable**, Dart **3.13.7**. Android uses the generated current Flutter Gradle configuration. Resolved dependency versions are in `pubspec.lock`. Run:

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d <android-device-id>
flutter build apk --debug --target lib/main.dart
```

Installable version **1.10.0+13**: [debug APK](deliverables/physics-atelier-target-ui-debug.apk) and [release APK with development signing](deliverables/physics-atelier-target-ui-release-dev-signed.apk). SHA-256 sidecars accompany both. Production signing and physical-device/iOS QA remain pending.

Device integration and screenshot capture:

```powershell
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/phase1_test.dart -d <android-device-id> --enable-software-rendering --no-enable-impeller
```

The driver writes actual rendered screenshots and a CSV of the test's recorded observations to `screenshots/`. Test observations are generated by explicit interactions, not preloaded app results. The integration test opens the native share sheet without choosing a recipient.

## This Windows host

Flutter was already installed at `C:\Users\Sai Satish\.local\share\flutter`, outside PATH. A short-path junction `C:\tools\flutter` avoids a native-assets compiler issue with spaces in the SDK path; `C:\tools\physics` points at this project without moving it. The local JDK 25 needed a short temp directory for Gradle loopback sockets:

```powershell
$env:TEMP='C:\tmp'
$env:TMP='C:\tmp'
$env:JAVA_TOOL_OPTIONS='-Djava.io.tmpdir=C:\tmp -Djava.net.preferIPv4Stack=true'
& C:\tools\flutter\bin\flutter.bat build apk --debug --target lib/main.dart
```

`tool/validate.ps1` runs analysis, unit/widget tests, device integration, and a production-entry debug APK build. Pass `-Flutter` and `-Device` for another installation. The Android SDK is at `%LOCALAPPDATA%\Android\Sdk`; doctor reports missing command-line tools although the installed platforms/build tools build successfully. No global PATH or unrelated Android project was modified.

## Architecture and handover

- [Architecture and storage](docs/ARCHITECTURE.md)
- [Scientific models, assumptions and references](docs/SCIENTIFIC_MODELS.md)
- [Asset provenance and visual gap](docs/ASSETS.md)
- [Test evidence and known limits](docs/VALIDATION.md)
- [iOS verification checklist](docs/IOS_VERIFICATION.md)
- [Phase 1 handover](docs/HANDOVER.md)

Current handoff: [compact workspaces](docs/WORKSPACE_HANDOVER.md), [290-test/native QA](docs/PHASE9_QA.md), [102-entry checklist](docs/WORKSPACE_MIGRATION.csv), [scientific register](docs/PHASE9_MODEL_REGISTER.json) and [before/after screenshots](docs/WORKSPACE_SCREENSHOTS.md). Phase 1–8 reports remain historical. Sixteen subject studios contain 96 interactive lab workspaces within their documented model bounds, alongside six functional overview tools. This inventory is not a blanket claim of release completion; the handover lists evidence-based Phase 9 gaps. No login/network is required after installation. Optional microphone input remains contextual; no raw audio is saved or uploaded.

## Nine-phase roadmap

1. Foundation, inventory, Measurement.
2. Mechanics, Motion/Kinematics, Force/Newton.
3. Earlier-module realism, Work/Energy/Power, Gravitation, Oscillations.
4. Waves/Sound and Optics.
5. Electricity and Magnetism.
6. Electronics and Thermodynamics.
7. Fluid Mechanics and Modern Physics.
8. Astronomy/Astrophysics and cross-studio Concept Overview tools.
9. Full scientific, visual, accessibility, performance and release validation, plus the compact interaction redesign (current development handoff; release blockers documented).

Phase 8 native targets: `phase8_test.dart`, `phase8_boundaries_test.dart`, `phase8_audit_test.dart` (also runs the isolated SQLite migration fixture), and `phase8_profile_test.dart`. Use a dedicated device/emulator and retain the notebook. This host uses `emulator-5556`, AVD Physics_Phase3, separately from the shared emulator. See the validation report for the real OS lifecycle companion `tool/phase8_device_watch.py`, profile commands, and automation limitations. Earlier integration targets remain available.
