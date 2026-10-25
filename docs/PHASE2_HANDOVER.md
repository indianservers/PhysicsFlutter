# Phase 2 handover

Version 1.1.0+2 adds all eighteen requested labs across Mechanics, Motion & Kinematics, and Force & Newton’s Laws. The six Measurement labs remain functional. The catalog retains seventeen studios and 102 stable entries, with 24 interactive experiments. No Phase 3 experiments are implemented.

Each new workspace includes specific lessons, adjustable apparatus, actual physics readouts, bounded recorded graphs, formulas, prediction practice, notes, persisted trials, session replay and CSV sharing. A 120 Hz fixed simulation clock separates physics from rendering; replay restores the model configuration and pauses. Trial snapshots are detached from later edits. SQLite schema 3 preserves existing trials and sessions and adds challenge attempts.

Install `deliverables/physics-atelier-phase2-debug.apk`. This is an ordinary Android application build from `lib/main.dart`, not an integration-test runner. It was installed over the previous app with data preservation. Source is under `lib/features/dynamics/` and `lib/core/physics/dynamics.dart`.

See [science and references](PHASE2_SCIENCE.md), [validation](PHASE2_VALIDATION.md), and [asset provenance](ASSETS.md). Eighteen per-lab screenshots and five alternative-mode screenshots are in `screenshots/phase2-*.png`; actual trial exports are in `screenshots/phase2-verified-results.csv`.

Known limits: apparatus uses original procedural drawings with material shading and remains schematic rather than photorealistic. Models deliberately restrict contact, topology and dimensionality as documented. Android emulator performance does not establish smooth 60 fps on physical midrange hardware. iOS build/device checks require macOS/Xcode and remain pending. This handover is not store-release certification.
