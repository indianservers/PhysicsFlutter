# Expanded laboratory curriculum — 1.14.0+17

The audit retains all 17 studios and the original 102 destination IDs. Twenty experiments are appended to 12 studios, giving **116 physical labs and six learning tools (122 destinations)**. Existing notebooks and the five required activities per studio in established learning paths keep their original identities and completion criteria. Added activities appear as optional extensions in those paths.

## Studio coverage and additions

- Concept Overview: existing atlas, relationship map, paths, launcher, comparison and mastery tools already cover discovery; the atlas, launcher, paths and counts now include every added lab.
- Measurement: existing ruler, vernier, micrometer, spherometer, mass/time and uncertainty already cover essential instrument work; no duplicate instrument added.
- Mechanics: **Rotational Inertia** (`s02-e06`), **Rolling Motion** (`s02-e07`), **Hooke’s Law** (`s02-e08`), **Young’s Modulus** (`s02-e09`). Existing plane models explicitly omitted rolling and existing spring oscillators did not supply static tensile-wire experiments.
- Motion & Kinematics: **Free Fall** (`s03-e06`), an explicit release-from-rest experiment with variable gravity and first-ground-contact endpoint. Existing projectile motion remains available.
- Force & Newton’s Laws: existing inertia, F=ma, action/reaction, friction, tension/normal and multi-force work cover the core topics. Torque and rotational dynamics are accessible in Mechanics.
- Work, Energy & Power: existing work, kinetic/potential energy, conservation, power and efficiency cover the core sequence. Rolling energy accounting is now available in Mechanics.
- Gravitation: existing force, field, potential, orbit, escape and Kepler experiments already provide the fundamental sequence; no second orbital solver added.
- Oscillations: **Torsional Pendulum** (`s07-e06`), with a twisting suspension and independently adjustable moment of inertia and torsion constant.
- Waves & Sound: **Beats** (`s08-e06`), with two independently specified nearby frequencies, a resolved carrier window and a properly sampled envelope graph. Existing coupled oscillators illustrate mechanical beats; this addition supplies the distinct sound-superposition experiment.
- Optics: **Polarization** (`s09-e06`), with unpolarized incident light, the first-polarizer half-intensity factor and Malus’s law for the analyzer. Existing refraction explicitly omitted polarization intensity.
- Electricity: **Wire Resistivity** (`s10-e06`), **Wheatstone Bridge** (`s10-e07`), **AC RLC Circuits** (`s10-e08`). These supplement the existing DC circuit builder and capacitor/RC experiments with geometry/material resistance, a null measurement and sinusoidal impedance/phase.
- Magnetism: **Transformer** (`s11-e06`), connecting turns ratio and ideal input/output power; existing induction and finite-solenoid experiments remain distinct.
- Electronics: **Full-wave Rectifier** (`s12-e06`), an ideal unsmoothed diode bridge, distinct from the existing series-diode experiment.
- Thermodynamics: **Calorimetry** (`s13-e06`), **Heating Curve & Latent Heat** (`s13-e07`), **Thermal Expansion** (`s13-e08`). Existing cooling, gas laws, thermal contact and material heating remain accessible. The additions explicitly expose mixing with a calorimeter, latent heat plateaus, and unconstrained solid-rod expansion rather than assuming these are covered by a gas-volume control or thermometer illustration.
- Fluid Mechanics: **Capillary Rise** (`s14-e06`), including wetting/nonwetting contact angles and signed rise/depression. Existing pressure, buoyancy, flow and viscosity experiments remain intact.
- Modern Physics: **Rutherford Scattering** (`s15-e06`), **Time Dilation & Length Contraction** (`s15-e07`). Atomic/nuclear structure and a longitudinal spectral Doppler shift did not provide these explicit investigations.
- Astronomy & Astrophysics: **Stellar Parallax** (`s16-e06`), distinguishing orbital radius, half-angle parallax and the full displacement between opposite observer positions.

## Implemented experience

Every addition has adjustable bounded inputs, a model-derived apparatus drawing, a calculated curve, explicit equations and assumptions, a learning prompt, numeric prediction checking, notes, a saveable paused session, and a recordable calculated observation with model version `supplemental-1.0`. The shared apparatus/graph/inspector/results tools, precision input, reset/undo, pinned comparisons, favorites, recorded-trial reopening and CSV export remain available. Drawings are labeled schematics, not photographs or laboratory measurements.

Recorded observations round-trip through the repository’s quantity/unit and model-version validation. User data is not migrated to new experiment IDs. New routes dispatch before the original six-entry model families, preventing an appended index from selecting an unrelated simulation. Added previews bypass the old six-panel reference-image crop and use their own apparatus painter.

Graphs are analytic model predictions. Dynamic curves explicitly label model time and a ten-second playback duration. Static curves sweep the named independent variable. The beats graph uses the envelope rather than aliasing a 100–520 Hz carrier; the separate carrier drawing resolves a 25 ms window. Original learning-path requirements remain five activities per studio, so adding optional labs cannot invalidate a previously completed path.

Investigation completion requires a changed input, a correct prediction, a trial with matching inputs/time and a written explanation. Merely opening a route, viewing a graph or recording an unrelated old trial does not complete an activity.

## Physics boundaries

Rolling is limited to a uniform solid sphere with sufficient static friction; the solver rejects slipping conditions. Young’s-modulus calculations reject strain above a 0.5% teaching threshold; this is not represented as a measured material yield limit. Disk rotation assumes a fixed axis and no drag. Free fall stops at first contact. Torsion assumes linear restoring torque and no damping.

AC circuits are sinusoidal steady state, not switching-transient simulations. Transformers and bridge rectifiers are ideal; rectifier output is pulsating and unsmoothed. Bridge voltage assumes an infinite-impedance detector. Resistivity stays at its prescribed value without a self-heating feedback model.

Calorimetry is adiabatic with constant heat capacities. Water phase-change temperatures assume approximately 1 atm; approximate specific/latent heats are stated in the inspector. The heating calculation ends after complete vaporization. Rod expansion assumes constant coefficient and no mechanical constraint. Capillary drawings and parallax angles are exaggerated and explicitly labeled.

Rutherford scattering uses a fixed point nucleus with no recoil, screening or nuclear force; the view draws asymptotes rather than pretending to integrate a trajectory. Parameter bounds keep the closest approach outside the typical nuclear-force scale. Relativity is restricted to inertial frames and parallel lengths measured simultaneously in the observer frame. Parallax uses the exact arctangent geometry; the conventional parsec relation is a small-angle expression with a 1 AU radius baseline.

## References

Physics relationships were cross-checked against primary OpenStax textbooks. Per-studio textbook references also appear in each new lab’s learning content.

- [Rotation, elasticity, oscillations and fluids — University Physics Volume 1](https://openstax.org/details/books/university-physics-volume-1)
- [Stress, Strain, and Elastic Modulus](https://openstax.org/books/university-physics-volume-1/pages/12-3-stress-strain-and-elastic-modulus)
- [Torsional pendulums](https://openstax.org/books/university-physics-volume-1/pages/15-4-pendulums)
- [Series RLC with AC](https://openstax.org/books/university-physics-volume-2/pages/15-3-rlc-series-circuits-with-ac)
- [Calorimetry](https://openstax.org/books/university-physics-volume-2/pages/1-4-heat-transfer-specific-heat-and-calorimetry)
- [Thermal expansion](https://openstax.org/books/university-physics-volume-2/pages/1-3-thermal-expansion)
- [Optics, relativity and nuclear physics — University Physics Volume 3](https://openstax.org/details/books/university-physics-volume-3)
- [Surveying the Stars](https://openstax.org/books/astronomy/pages/19-2-surveying-the-stars)

## Verification

- `flutter analyze --no-pub`: no issues.
- Full unit/widget suite: **379 passed**. Focused model, restore, completion and live-view checks after the final malformed-session guard: **37 passed**.
- Native Android: every added apparatus, graph and inspector checked; 12 affected studio pages captured. Final apparatus refresh explicitly verifies that each painter’s inputs and state match the source readings. **72 PNGs** plus two contact sheets are retained locally.
- Diagram, graph and inspector contents subscribe to the source notifier. Control changes and model-time advances update already-open panes. Snapshot review caught and corrected an initial stale-drawing binding; regression tests now exercise the rendered painter and open graph, rather than checking only source variables.
- Ordinary `lib/main.dart` debug APK built, installed on `emulator-5556`, checksum matched to the deliverable, and the default-renderer Home screen visually checked. Integration fixtures and test entry points are absent from its kernel.
- Existing notebook data preserved: **428 trial bodies, 123 challenge attempts, 108 complete session states and all five preference keys/values**; schema 3 and SQLite integrity remain unchanged. The comparison also rejects additional session rows or preference keys after QA cleanup. Raw baselines remain private and outside the repository.

The APK is `deliverables/physics-atelier-expanded-labs-debug.apk` (1.14.0+17), with a SHA-256 sidecar. Native screenshot integration used software rendering on API37; physical-device performance and iOS builds were not tested in this addition.

See [validation results](EXPANDED_LABS_VALIDATION.json), [data preservation](EXPANDED_LABS_PRESERVATION.json), and the [20-lab inventory](EXPANDED_LABS_INVENTORY.csv). Native evidence is saved locally under `Target UI/expandedLabsScreens`; earlier `currentScreens` and `updatedScreens` remain intact. These tests qualify the implemented teaching models and Android debug build; they do not claim comprehensive coverage of every possible physics syllabus or iOS device validation.
