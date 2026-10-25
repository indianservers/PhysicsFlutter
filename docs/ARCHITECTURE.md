# Architecture

`lib/content/catalog.dart` is the runtime source of truth for 17 studios and 102 stable entries. Routes, home, search and studio pages all use it. `tool/generate_catalog.py` records the initial import from the supplied inventory plus original per-entry principles/equations; regeneration takes the original brief path as a command-line argument and must be reviewed. Runtime never needs that generator or attachment.

`lib/core/physics/measurement.dart` contains pure Dart scientific functions, SI conversions, instrument tick decomposition, uncertainty and view transforms. It has no Flutter dependency. `features/measurement/experiment.dart` owns mutable session state and a monotonic timer; scientific formulas remain in the pure layer. `core/rendering/apparatus.dart` converts SI state into canvas geometry. `ScientificScene` establishes a painter and accessible-description contract that future field, particle and celestial renderers can implement.

`features/lab_workspace/workspace.dart` supplies Learn, Experiment, Visualize, Formulas and Results sections. One Experiment instance survives section switches. The route owns its lifetime. Background, hidden Experiment sections and route disposal stop its timer. A cached provider reference makes disposal safe under Riverpod. Precise numeric dialogs supplement touch input; app content scrolls above the keyboard.

`app/app.dart` owns routing and the home/studio/notebook/settings presentation. Riverpod injects the notebook; ListenableBuilder reacts to targeted experiment and notebook changes. Material 3 uses centralized navy/cobalt/teal tokens and white surfaces. Layout constraints produce one, two or three studio columns; text and vertical contents wrap/scroll. Canvas rendering is inside RepaintBoundary. No network resources are needed at runtime.

## Storage

`ExperimentRepository` separates session/trial persistence from the workspace. Android, iOS and macOS use sqflite. Schema v1 has JSON trial bodies keyed by ID; schema v2 adds keyed sessions. Current creation makes both tables and an explicit v1→v2 migration is supplied. The configuration envelope is versioned independently (v1), with a scientific model identifier in each state/result. Preferences hold last lab/studio, completed activities, reduced motion and haptics.

Each trial preserves UTC creation time, SI quantity/unit, reading, optional instrument resolution, notes and complete serialized configuration. Invalid trial bodies are skipped with a visible notebook notice while original stored bodies are preserved. Unknown session versions revert to defaults. A database-open failure preserves the original database and switches new work to preference-backed storage with a recovery notice. Web/other desktop platforms use that fallback intentionally; production-scale desktop data should adopt a dedicated SQLite/IndexedDB adapter.

There is no login, sync, backend, streak generator or fabricated progress. A visit updates Continue Learning; explicit lesson completion or a finished guided activity updates completion. Recording alone does not silently claim mastery.

CSV export shares UTF-8 bytes through share_plus and includes real trial data, SI column labels, model identifier and JSON configuration. Each cell is quoted and embedded quotes escaped. A null instrument resolution exports an empty cell. No external recipient is selected automatically. Share sheet anchoring is provided for iPad.

## Dependencies

Versions are pinned by `pubspec.lock` and were resolved against Flutter 3.47.8 / Dart 3.13.7. flutter_riverpod injects state; go_router supplies stable routes; sqflite supplies structured mobile storage/migrations; shared_preferences holds lightweight settings; flutter_math_fork renders bundled offline equations; share_plus invokes platform file sharing. These packages publish Android/iOS support. Charts are original CustomPainter plots, avoiding an extra chart dependency. No 3D, shader or Android-only scientific plugin is used.
# Phase 2 extension

Current schema is version 3: previous trials and sessions are retained, with a challenge_attempts table added. Trial JSON carries a model identifier and a deep snapshot of configuration. Legacy Measurement records default to measurement-1.0. Dynamics models use dynamics-2.0, replay ticks and actual observations. New code resides in core/physics/dynamics.dart and features/dynamics/{curriculum,scene,workspace}.dart. A 120 Hz fixed clock advances pure Dart models; bounded graph samples and simulation-driven painters consume their state. Route/lifecycle changes pause simulation. The earlier Phase 1 details below remain applicable to Measurement.

## Phase 3 extension

`core/physics/advanced.dart` provides pure Dart energy, gravitation and oscillator calculations. `features/advanced/` provides curriculum, articulated painters and the shared five-section workspace for stable studio IDs 05–07. Earlier model implementations and routes remain intact. The fixed wall clock and route observer are reused. No new rendering dependency is introduced: the original texture is decoded once at 512 px and mapped with Flutter Canvas vertices.

SQLite stays at schema 3: its JSON payload tables already support additional model versions without destructive migrations. Trial validation adds the Phase 3 model and energy, power, specific-energy, damping, angular-frequency and dimensionless-efficiency quantities. Old model versions remain accepted. Sessions carry model/kind, initial parameters, replay ticks, notes, guided progress, attempts, display preferences and speed. Trial snapshots additionally store actual bounded observations and final state, detached by the existing deep copy. The notebook's CSV still emits each record's own model version and SI unit. No generated prediction curve is inserted as an observation.

## Phase 4

`core/physics/waves_optics.dart` is pure Dart model `waves-optics-4.0`. `features/waves/curriculum.dart` supplies twelve lessons/ranges; `workspace.dart` shares clock, graph, persistence, notes, challenges and accessible numeric controls. `scene.dart` renders computed apparatus with uniform camera coordinates and inverse drag mapping. Studios 8–9 route to this workspace, with stable IDs unchanged. Measurement, Dynamics and Advanced route branches retain their earlier models.

`microphone.dart` lazily acquires the optional native record plugin. A bounded PCM ring and top-level compute callback perform rate-aware FFT analysis; the callback must not capture the recorder/controller. Lifecycle/navigation cancels capture and stale jobs. Raw samples never enter persistent configuration. Only explicit user Record/Save authorizes an analysis snapshot; restored analysis remains stopped. Platform permission metadata covers Android/iOS; platform behavior still needs physical-device and iOS validation.

Current DB schema remains **3**, introduced in Phase 3. New JSON model/quantity support does not rewrite earlier records. The v2→v3 migration is exercised using actual SQLite on Android; old trials are compared by complete serialized body. See PHASE4_SCIENCE.md and PHASE4_VALIDATION.md for configuration/sampling and native evidence. Shared globe material caches a bounded unit mesh instead of allocating the same geometry each paint.

## Phase 5

Pure Dart `core/physics/electromagnetism.dart` adds model `electromagnetism-5.0`: V3 vectors/constants, signed electrostatics, bounded traces/contours, genuine terminal-graph MNA, plates/RC, exterior dipole/wire, finite axial solenoid, nonrelativistic Boris motion, finite-loop flux/EMF and educational reluctance/gap force. `features/electromagnetism/` contains the twelve curricula, state-linked apparatus and common five-view workspace. Studios10–11 route here; all earlier route branches/models remain intact.

The existing FixedClock, route observer, graph, numeric input, preferences and SQLite repository are reused. No new dependency/permission/clock/unit/persistence framework is added. Field geometry is keyed by source configuration, contour vertices are evaluated once and drawing paths are bounded/cached. Circuit solving is separate from painting: moving layout updates terminals but preserves topology/MNA; wiring/value/switch edits rebuild the graph. Boris substeps are internal numerical integration at the shared clock's physical scale. Every dynamic model pauses on navigation/background/disposal; reopen is deterministic and paused.

Current schema remains **3** with trials, sessions and challenge_attempts. New quantity/model validation extends existing JSON without rewriting old records. Full SI inputs, model/kind/mode, initial conditions/ticks, held capacitor charge, circuit parts/wires/layout, probes, notes, attempts and view preferences are stored. Trial snapshots remain deep detached copies. Scientific readout validity is independent of drawing normalization. See PHASE5_SCIENCE.md and PHASE5_VALIDATION.md.

The shared graph now uses unit-independent plot ranges. Repeated Canvas text uses a bounded192-paragraph cache that disposes evictions; positions remain current on every paint. Old scientific computations are unchanged. The Magnetism studio vignette's N/S field direction was corrected.


## Phase 7 extension

`fluid_modern.dart` holds pure scientific models and bounded dataset constants; `stochastic.dart` holds independently seeded samplers and finite-grid distributions. `fluid_modern_run.dart` composes exact analytic state, fixed-tick observations and cached geometries/CDFs. `features/fluid_modern` contains curriculum, workspace/persistence and apparatus painting. Route selection prefers this workspace for studios14/15; stable IDs and old78 models remain. Schema3 is unchanged; activity Bq was added as a scientific quantity. Histograms/discrete plots are optional shared LabPlot features. See PHASE7_SCIENCE.md for units, conventions and replay provenance. Fifteen studios/90 labs are interactive; Astronomy and advanced Concept Overview remain Phase8.
