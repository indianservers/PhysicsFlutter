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
