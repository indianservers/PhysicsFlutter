# Compact workspace handover — 1.8.0+9

The application implements compact Home and all 17 studio launchers, apparatus-first workspaces for all 96 physical labs, and purpose-specific layouts for all six overview tools. Stable routes, scientific models, SQLite schema 3 and existing records remain compatible. This is a working development handoff, **not a release candidate**.

## Use the application

Open a lab to manipulate its apparatus immediately. The bounded dock exposes primary controls with precise numeric entry; More exposes model selection, secondary parameters, prediction, notes and original investigation controls. Static investigations omit playback. View selects scene, scene+graph, scene+data, graph focus or full-screen. Drag the divider or use its accessibility adjustments. Pan mode separates camera gestures from apparatus manipulation. Fit resets the presentation transform without changing physical dimensions.

Learn and Formulas retain the complete source content. Formula input chips return to and highlight actual controls. Results lists the latest100 actual recorded trials (10 in the split data preview); full-notebook access and CSV retain older records. Summary/export also retains original challenge-history summaries. Select a row to inspect notes/configuration, compare compatible scalar observations, export selected records, or safely reopen the stored configuration. Recorded comparison is explicitly not synchronized trajectory replay. Existing model-specific graph replay/cursor controls remain available. Guided mode shows one actual-state-gated instruction at a time; final completion still uses the source investigation evidence criteria.

Home uses real activity for Continue Learning. Studio tiles depict each lab's source apparatus at reference inputs. Atlas and Relationship Map are map-first with accessible lists; Guided Path uses actual prerequisite completion; Launcher searches the shared catalog; Compare Phenomena retains one shared-clock model with explicit units/analogy limits; Mastery starts with the current curated question and saves actual attempts.

## Build

Project: `C:\Indian Servers\Android Physics` (short junction `C:\tools\physics`). Flutter **3.47.8 stable**, Dart **3.13.7**. Use the pinned `pubspec.lock`. No new packages were added.

```powershell
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --target lib/main.dart
flutter build apk --release --target lib/main.dart
```

On this Windows host, Gradle required `TEMP`/`TMP=C:\tmp` and `JAVA_TOOL_OPTIONS=-Djava.io.tmpdir=C:\tmp -Djava.net.preferIPv4Stack=true`. Run native builds sequentially; on this SDK use the normal release command without `--no-pub` so Flutter regenerates the release plugin registry. A stale debug registry referenced the integration-test plugin and failed the first release attempt. Android17/API37 on the dedicated emulator requires an explicit `am start` after integration APK installation; `tool/phase9_device_watch.py` automates only emulator-5556.

Final local artifacts and SHA-256/installed verification are listed in `screenshots/phase9-build-verification.json`. The ordinary APK target is **lib/main.dart**, not an integration fixture. Release-mode uses the existing development/debug certificate. A production release requires the owner's signing configuration, application ownership/licensing decisions, device testing and store review. No AAB, upload, publication or push is claimed.

## Evidence

- [QA and performance](PHASE9_QA.md).
- [102-entry CSV checklist](WORKSPACE_MIGRATION.csv) and [full JSON evidence](WORKSPACE_MIGRATION.json).
- [Before/after by studio](WORKSPACE_SCREENSHOTS.md); local screenshot ZIP: `deliverables/phase9-screenshots.zip`.
- [Scientific register](PHASE9_MODEL_REGISTER.json), [scientific review](PHASE9_SCIENTIFIC_REVIEW.md), [asset register](PHASE9_ASSET_REGISTER.json), [privacy and dependencies](PHASE9_PRIVACY_AND_LICENSES.md).
- Original notebook backup and generated restoration fixtures remain local and excluded from Git. `tool/phase9_preservation.py` compares original SQLite record bodies after the ordinary APK installation.

## Remaining release blockers

- Procedural scenes retain material shading, texture, scales and real model-driven geometry, but do not match every target's photographic/premium apparatus fidelity. No target-board image was repackaged as an interactive scene.
- Performance is measured on a host-GPU Android emulator. Physical Android responsiveness, thermals, memory longevity and renderer behavior still require measurement; emulator jank must not be advertised as 60fps performance.
- TalkBack evidence is a bounded device/semantics check, not independent human usability certification. Full blind-user, switch-access and reduced-motion experience reviews remain necessary.
- iOS source/icons exist, but Xcode compilation, signing, VoiceOver, iPad export and actual iOS device QA were unavailable on Windows. There is no validated iOS artifact.
- The repository has no project-level LICENSE. Dataset/image conditions and unresolved provenance in the asset register need owner review before redistribution.
- Models remain bounded educational approximations with the assumptions and input ranges in their scientific documentation. Trials are simulated/calculated observations, not laboratory measurements or independently validated professional instruments.


## Optional private baseline for native QA

Fresh checkout analysis and tests require no private data. For preservation QA, generate an ignored local baseline file and transfer it to the already-installed debug app sandbox:

```powershell
python tool/phase9_make_fixture.py --baseline C:\tmp\phase9-baseline-exact.tar --push --device emulator-5556
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/phase9_inventory_test.dart -d emulator-5556
```

The public fixture loader reads this optional sandbox file only from integration targets. No notebook content belongs in compiler flags or application assets. Large `--dart-define-from-file` baselines exceed Windows Gradle batch command limits and can be echoed by Flutter crash diagnostics; do not use that transport. Remove `files/physics_qa_fixture.json` from this app sandbox after QA. Ordinary `lib/main.dart` builds never import the fixture loader. Both the local JSON file and earlier private Dart fixtures remain excluded from Git.
