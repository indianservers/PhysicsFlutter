# Scientific model register and review

[PHASE9_MODEL_REGISTER.json](PHASE9_MODEL_REGISTER.json) contains one entry for each stable destination, generated from the same catalog and curriculum definitions used in the application. For each physical lab it records equations, symbols, SI conventions, input bounds/defaults, procedure, example, assumptions, dataset identity, source documentation and mapped tests. Overview tools instead identify their bounded navigation, assessment and comparison model. Run `dart run tool/phase9_register.dart` to regenerate it.

The register distinguishes implementation and consistency/reference verification from independent experimental validation. The application contains educational models, synthetic observations and a small number of identified reference datasets. It is not calibrated laboratory equipment or an observational inference package.

## Review method

All model families retain their established scientific versions because Phase 9 changes evidence handling, rendering, navigation, labels and export safety rather than their physical equations. Earlier trial interpretation remains supported. Measurement sessions gain additive prediction/evidence signatures; existing completions are retained without inventing replacement history.

The source and test review uses the following independent constraints, in addition to explicit model input bounds:

- Measurement: integer scale divisions, signed zero correction, sagitta geometry, known constant-acceleration solutions and NIST uncertainty rules. Instrument resolution is not falsely treated as experimentally measured accuracy.
- Mechanics and motion: analytic constant-acceleration trajectories, independent vector/torque examples, exact piecewise friction/contact, momentum and restitution, work–energy consistency and reference-frame transformation.
- Energy/gravity/oscillators: work and kinetic/potential ledgers, force versus potential gradient, Kepler periods/energy, escape-speed reference, undamped conservation and damping/passive energy behavior. Pendulum and contact restrictions remain explicit.
- Waves/optics: wavelength–frequency–speed identity, superposition, standing-wave boundary conditions, coherent interference, FFT frequency/calibration/leakage references, Doppler retarded geometry, Snell/TIR, real-is-positive paraxial image conventions and Fraunhofer limits.
- Electricity/magnetism: electrostatic superposition and numerical potential gradients, Kirchhoff residuals and DC source/load power, RC energy accounting, connected/isolated dielectric conventions, nonrelativistic B-only Boris work/energy behavior and Faraday/Lenz polarity.
- Electronics/thermodynamics: neutrality/mass action, circuit residuals, bounded diode/BJT/op-amp behavior, Boolean truth tables, sensor transfer references, Stefan–Boltzmann behavior, ideal-gas states, first-law ledgers, entropy and Carnot restrictions. These are educational device models, not SPICE or calibrated sensors.
- Fluids/modern physics: pressure/volume continuity and equilibrium constraints, Archimedes force, Bernoulli head, explicit low-Re validity, normalized stationary eigenstates and detector probabilities, photoelectric threshold, hydrogen wavelengths, atomic/nuclear mass conventions and seeded decay distributions.
- Astronomy: J2000 reference elements and Kepler conservation/periods, sourced MIST track bounds and same-stage interpolation, Planck B-lambda conventions, signed relativistic line shifts, galaxy potential derivatives, SPARC uncertainties, independently integrated cosmology and exact transit overlap boundaries/symmetry/Kepler consistency.

Tolerances and numerical resolution are specified in the mapped tests and historical science documentation. Numerical agreement with a reference or conservation law is not a claim of experimental validation. The shared fixed-step clock accepts a bounded catch-up interval, explicitly dropping excess wall time so a stalled device slows playback rather than changing the integration step or jumping through background time.

## Corrected scientific navigation

The wave/optical comparison now links to **Optics Interference `s09-e04`**, rather than Diffraction. RC/thermal response now links to **Capacitors `s10-e05`**, rather than Current. Both comparisons already called the appropriate source kernels; the misleading route metadata was corrected and tested. No alternate physics implementation was added.

Measurement completion now requires guided steps, a changed scientific input, a correct current-state prediction, a matching explicitly recorded trial, and explanatory notes. A historical unrelated trial or page visit cannot satisfy the current investigation. This is a learning activity criterion, not a validated mastery score.

## References and limitations

- [Measurement/NIST and introductory sources](SCIENTIFIC_MODELS.md).
- [Dynamics equations and contact/coordinate limits](PHASE2_SCIENCE.md).
- [Energy, gravity and oscillators](PHASE3_SCIENCE.md).
- [Waves, sound, FFT and optics](PHASE4_SCIENCE.md).
- [Electricity, circuits and magnetism](PHASE5_SCIENCE.md).
- [Electronics and thermodynamics](PHASE6_SCIENCE.md).
- [Fluids and modern physics](PHASE7_SCIENCE.md).
- [Astronomy methods, datasets, constants and epochs](PHASE8_SCIENCE.md).
- [Path DAGs, comparisons and challenge configurations/tolerances](PHASE8_TOOLS.md).

Cross-studio conservation and first-law review is consistent with [OpenStax University Physics](https://openstax.org/books/university-physics-volume-1/pages/9-introduction) and its [Volume 2 index](https://openstax.org/books/university-physics-volume-2/pages/index). These sources support the physical principles, while each implementation's restrictive assumptions remain part of its validity. Full independent scientific/editorial review and calibrated physical experiments remain outside the automated evidence supplied here.
