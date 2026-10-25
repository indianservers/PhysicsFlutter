# Phase 4 assets and earlier-module audit

## New apparatus provenance

`lib/features/waves/scene.dart` contains original project procedural geometry created for this phase: glass ripple-tank walls and metal paddles, height-field surface, string supports, tuning fork, shaded microphone grille/stem/base, Doppler source cart and receiver, metal optical rails, plane/spherical mirrors, convex/concave glass lenses, slit plates, light source and intensity screens. Flutter Canvas gradients, paths and strokes supply materials/contact shadows. No new bitmap, external 3-D model, downloaded texture or AI image was introduced. Intended use is the twelve Phase 4 apparatus views. Physical parameters determine geometry and plotted profiles; rays/normals/minima/phase colors are separately switchable instructional overlays. The amplitude/vertical scale exaggerations and illustrative wavelength RGB are labeled.

Existing Phase 3 generated Earth/material assets retain their previous provenance; see [Phase 3](PHASE3_ASSETS_AND_AUDIT.md). Material Icons remain Apache 2.0 and system fonts remain OS supplied. The new code does not assert a third-party asset license for original project drawings.

User boards `Target UI/09_Waves_and_Sound.png` and `10_Optics.png` were inspected in all twelve panels. They remain unchanged, excluded from Git and the APK, and are never used as screen backgrounds. Their redistribution rights are unknown. The reference Doppler example and uncalibrated SPL claims were corrected; standing-wave node counting includes endpoints. Optical interference uses the documented ideal narrow-slit model rather than displaying an unexplained envelope.

`record` 7.1.2 and resolved platform siblings are dependencies, not visual assets. Source: https://pub.dev/packages/record and https://github.com/llfbandit/record . No plugin source modifications. Its locally supplied BSD 3-clause LICENSE (including the actual “Copyright 2022 openapi4j authors” notice) is copied verbatim into `docs/licenses/record-7.1.2-LICENSE.txt`; attribution is not replaced with a guessed author. Resolved versions are pinned by `pubspec.lock`; Flutter's dependency license registry remains available through About. Android requests RECORD_AUDIO and iOS has a contextual usage string; no new network/upload service is introduced.

## Earlier-module audit and change

The running baseline was inspected on the dedicated emulator before editing: home, Measurement/Mechanics/Gravitation/Oscillations and the future Waves/Optics studios, plus vernier `s01-e01`, mechanics `s02-e00`, kinematics `s03-e03`, Newton `s04-e03`, orbital `s06-e03`, pendulum `s07-e01` and resonance `s07-e04`. Actual captures are `screenshots/phase4-before-*.png`; matching `phase4-after-*.png` are the final audit. These show existing materials, scale/overlay placement and touch layout at the supported viewport. No working earlier physical model was replaced.

An inherited rendering cost was fixed in `lib/core/rendering/materials.dart`: each globe sphere paint rebuilt a 625-vertex/1152-triangle mesh and texture shader. The same unit mesh/shader is now cached by image (maximum four entries, disposing evicted native vertices); Canvas translation/scale places it. Existing mesh geometry, texture, illumination and projected silhouette are retained. Before/after `s06-e03` captures are the relevant visual evidence; full earlier numerical/widget regression suites and native representative screens check behavior. The Phase 4 profiling report does not imply a before/after speed measurement for this cache change.

New lower-level scientific functions use a separate model version. Old trial JSONs were not upgraded or rewritten. An exact pre-test backup, old-trial comparison, and native schema fixture separately check preservation.

## Visual limits

These are shaded procedural scientific apparatus, not photorealistic 3-D assets matching every target pixel. The sound source/fork illustrates apparatus; generated mode has no speaker output and no unrelated decorative animation. Lens/mirror rays are instructional paths; clear air has no fake smoke. A real image outside the finite viewport is explicitly indicated. Introductory destinations for later phases remain accessible and accurately labeled. iOS icons, physical-device audio behavior and final photographic art quality remain review items, not completed claims.

The screenshot contact sheets are QA derivatives of unchanged native captures, not application assets. No reference board is bundled in those deliverable sheets.
