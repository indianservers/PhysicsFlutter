# Phase 7 apparatus, provenance and earlier-module audit

Inspected every panel in supplied `Target UI/15_Fluid_Mechanics.png` and `16_Modern_Physics.png` before implementation. Those files are visual references only, remain untouched and excluded from the bundle/repository. Their labels are not evidence for physical values. For example, at ρ=1000 kg/m³ and h=0.3 m the calculated gauge pressure is2941.995 Pa, not24.3 kPa; at f=6×10¹⁴ Hz and φ=2 eV the stopping potential is approximately0.4814 V. No reference-board result was copied into a trial.

## New original apparatus

`lib/features/fluid_modern/scene.dart` uses code-native Canvas geometry with existing original `LabMaterials`, bounded cached `ScientificText` and the cached wood workbench. Glass transparency, menisci, metal highlights, wood faces, contact shadows, rulers, hoses, detector electronics and supports are original procedural drawings. Twelve distinct apparatus scenes are built from actual model geometry/state. No downloaded/AI-generated bitmap, photographic claim, new font, package, permission or network dependency.

- Pressure: submerged probe, hose, calculated gauge, independently sized mass/volume specimen.
- Manometer: circular branch diameters from area, sealed pressure port, volume-conserving liquid/interface levels and datum.
- Buoyancy: exact rectangular body, common length scale, physical waterline, tank bottom/support and signed force vectors.
- Continuity/Venturi: circular cross-section pipe, actual varying radius/elevation, markers advected by cumulative volume, physical open piezometer heads.
- Viscosity: calibrated vessel, true-scale bead and labeled ×12 inset, calculated finite arrival. No animated decorative bubbles.
- Quantum well: stationary signed ψ and density, discrete level ladder and actual seeded positions, explicitly schematic.
- Photoelectric: evacuated emitter/collector tube, light coupling, polarity and current meter, no false below-threshold electron paths.
- Matter waves: schematic gun and exaggerated nanometer slits, conditional probability and individual detector positions; no classical paths.
- Hydrogen: tube/spectroscope, calculated vacuum line positions, energy ladder and reversed absorption transitions. RGB/strength illustrative.
- Nuclei: exact Z/N counts in an explicitly illustrative composition diagram; rotatable view is presentation only.
- Decay: sealed-source/detector apparatus and real simulated counts, independent efficiency/background; no dose or shielding claim.

Incompatible states show a clear model-boundary notice instead of a fabricated apparatus reading. Rendering and model calculations have separate layers; original shared materials avoid full-scene bitmap backgrounds. Graphs show proper histogram bars and discrete isotope points rather than connecting unrelated observations into invented continuous curves.

## Existing-module audit

Before/after Android captures cover the home page; studios1,6,8,10,11,12,13,14,15; representative caliper, torque, kinematics, Newton force, energy, gravitation, oscillation, sound, optics, DC circuits, RC and magnetic induction; and thermal expansion, radiation and Carnot cycle. Files use `screenshots/phase7-before-*` and `phase7-after-*`. Existing thermal surfaces remain unheated-looking at ordinary settings, no unjustified steam or glowing metal. Shared glass/wood/metal rendering remains intact. Prior scientific models and fixed IDs are preserved; the baseline181 tests passed before work.

Significant targeted upgrade: Modern Physics studio preview formerly used literal classical electron orbits. `lib/core/rendering/studio_vignette.dart` now uses a stationary n=2 well probability diagram and discrete levels. Compare `phase7-before-studio-15.png` and `phase7-after-studio-15.png`. The advanced plot component gained opt-in real histogram bars/discrete points without changing old call defaults. No unrelated redesign or new Concept Overview feature.

## Visual limits

These are shaded vector apparatus illustrations, not photorealistic photographs. The overall target-board photographic material richness remains incomplete. Quantum, atomic, detector and nucleus diagrams explicitly identify schematic scales/interpretations. RGB line colors and arbitrary nucleon layouts do not claim measured appearance. Need independent accessibility user testing, physical-device review and final art polish in Phase9. Native screenshots cover all twelve labs and boundary modes, including failed Stokes/pressure regimes; see Phase7 validation. No Phase8 implementation.
