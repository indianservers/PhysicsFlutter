# Phase 5 apparatus provenance and earlier-module audit

## Original apparatus

`lib/features/electromagnetism/scene.dart` is original project Flutter Canvas geometry created for Phase 5. Intended uses: signed conducting spheres and insulating stands; source/probe field boards; shaded battery terminals and copper wiring; resistor bodies/bands; switch contacts; ohmic lamp bulb/filament and power-driven brightness; framed analogue ammeter/EMF instruments; parallel plates/dielectric; bar-magnet and compass; projected particle chamber/trajectory; straight-wire section; copper-wound solenoid; coaxial induction source/receiver; and wound core/return path/air-gap armature.

Materials are procedural gradients, metal/insulator strokes, contact shadows, glass outlines, copper windings and original geometry. These use the existing shared `LabMaterials` renderer; no new raster texture, AI image, downloaded apparatus image or third-party 3-D model is introduced. Geometry and controls consume the actual model state; numbers, needles, force directions, particle path and source motion are not decorative. Meter full scales are explicit. Core dimensions/air gap and marker size can be schematic/exaggerated where labeled; solenoid length/radius/probe share one physical mapping. No sparks, smoke, unsupported levitation or audio was added.

Apparatus and optional educational representations are separate: normalized electric vectors/force directions, qualitative field lines, equipotential contours, phase-space projection and the electron-drift inset. Field normalization does not change readouts. Source spheres/bar magnets remain declared representations of their point/dipole/finite-loop scientific approximations. The induction source’s bar shape is not claimed to make the finite-loop model an exact real bar-magnet near field.

No external asset attribution is invented. Material Icons remain Flutter’s bundled Apache 2.0 glyphs; system fonts are OS supplied. Earlier Phase 3 generated Earth/material textures and the Phase 4 record plugin retain their existing provenance/licenses; neither is regenerated or relicensed. Flutter dependencies remain as pinned in `pubspec.lock`; Phase 5 adds no dependency or platform permission.

User boards `Target UI/11_Electricity.png` and `12_Magnetism.png` were inspected in all twelve panels. They remain unchanged and excluded from both Git and the application bundle. They are not app backgrounds; redistribution rights remain unknown. Numeric corrections include the potential reference (5 μC at .15 m is about 300 kV, not180 V) and wire reference (5 A at .03 m gives33.333 μT, not49.8 μT). The qualitative Lorentz diagram is replaced by a consistent right-handed cross product and actual B-only circle/helix.

## Prior-module inspection and fixes

Before editing, inspected architecture, Phase 1–4 handovers/science/validation/provenance, the shared 120 Hz clock, current dependency list, catalogue/routes, notebook schema and tests. The native baseline was run on the dedicated emulator, with an exact binary-safe backup. All108 existing unit/widget tests passed. Native before captures include home, studios1/2/6/7/8/9/10/11 and representative vernier, mechanics, kinematics, Newton, orbit, pendulum, resonance, coherent waves and refraction. They are `screenshots/phase5-before-*.png`; matching after captures are retained.

Two inherited shared-renderer defects relevant to this phase were corrected:

1. **Unit-dependent graph thresholds:** `features/advanced/scene.dart` previously flattened amplitudes below10⁻¹² to a unit-height axis and forced x spans to at least10⁻⁶. This made small electromagnetic forces and early microsecond trajectories misleading. `core/physics/plot_range.dart` now preserves any nonzero finite span, independently of units. A meaningful scale-invariance test covers femtonewtons and nanosecond spans; old scientific calculations remain unchanged. Native Lorentz graphs show their actual tiny SI values. Invalid-channel gaps remain gaps.
2. **Magnetism studio icon:** `core/rendering/studio_vignette.dart` had gap arrows from the blue pole toward the red pole. It now explicitly labels blue S/red N and directs the field N→S. Compare `phase5-before-studio-11.png` and `phase5-after-studio-11.png`. The original U-magnet geometry/material motif is retained; the physics direction is corrected.

Phase 4’s bounded globe mesh/shader cache is retained and its orbit screen is checked again. Existing microphone capture/lifecycle implementation is unchanged. No valid earlier scientific model was replaced to change appearance.

The shared Dynamics/Advanced/Waves Canvas label path now reuses at most192 native TextPainter paragraphs, disposing evicted entries, rather than laying out every unchanged string on every paint. Layout coordinates remain live, so labels do not detach from moving apparatus. Phase5 contours are batched into cached paths. Both changes were followed by the full regression suite and native earlier-module screenshots; measured profile results, including remaining jank, are reported without an unmeasured speed claim.

Within Phase 5, final visual verification also corrected the initial coil support/probe mapping, induction coil orientation/source-size mapping, circuit layout propagation and contextual units on the current-drive housing. The final all-twelve screenshot set is captured after those fixes, not passed off as the initial render. The circuit workbench supports actual electrical topology; moving parts preserves coherent endpoint connections and reuses the solved graph.

## Evidence and honest visual limits

All twelve final scenes: `phase5-s10-e00`…`phase5-s10-e05` and `phase5-s11-e00`…`phase5-s11-e05`, with graphs/mode screenshots alongside. The contact sheet is a QA-only derivative of actual native PNGs, not a shipped asset. Native advanced cases include floating/shorted circuits, actual changed wiring, RC and isolated-capacitor behavior, source exclusions, Boris helix/charge reversal, finite solenoid, induction polarity and core validity limits.

These are shaded, dimensional procedural teaching apparatus, not photographic/photorealistic parity with the supplied boards. Some scientific objects are small in a wide field viewport; pinch/zoom and precise numeric readouts provide inspection. Real-world instrument calibration, full TalkBack/VoiceOver user testing, iOS build/device QA, physical mid-range Android profiling, final icon branding and photographic art polish remain separate product/release work. Approximate material/core models are identified in the science report, not hidden by realistic-looking art.
