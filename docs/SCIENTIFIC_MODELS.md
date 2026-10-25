# Scientific models — Phase 1

All calculations use SI internally. UI conversions are explicit. Full precision is retained in stored values; display rounding is separate. Model identifier: `measurement-1.0`. These are virtual apparatus, not sensors. Defined object sizes, masses and initial conditions are inputs, never claimed observations from a phone.

## Measurement models

### Meter scale
The visible range is 0–100 mm with 1 mm engraved divisions. A and B are quantized to that grid. L = |B − A|. Endpoints, block edges and rendered scale use the same model positions. For independent rounding of two endpoints, each uniform within ±q/2, u(L) = sqrt(2) q/sqrt(12) = 0.408248 mm for q = 1 mm. This is a stated standard uncertainty convention, not a claim about every ruler. A magnifiable view uses InteractiveViewer; zoom and pan never enter calculations. Endpoint handles can be dragged or set numerically. No parallax bias is added.

### Vernier caliper
External measurement only. Main divisions: 1 mm. Ten vernier divisions span 9 mm, hence LC = 0.1 mm. Physical jaw opening a and zero bias e₀ produce observed x = a + e₀; quantization gives an integer tick count. Main contribution M = floor(ticks/10) mm; coincidence n = ticks mod 10. Observed = M + n LC. Corrected = observed − e₀. Main-scale origin shifts with the defined zero bias, so scales, jaw position and readout remain connected. Internal and depth modes are intentionally absent.

At the default a = 23.6 mm, e₀ = 0: M = 23 mm, n = 6. Adding a +0.2 mm zero bias gives observed 23.8 mm and corrected 23.6 mm. The lesson's separate worked example of an observed 23.6 mm with +0.2 mm bias gives corrected 23.4 mm. These are different starting conditions, not conflicting readings.

### Micrometer
Pitch p = 0.5 mm/revolution, N = 50, LC = p/N = 0.01 mm. Physical opening a has observed indication a + e₀. Sleeve half-millimetres and thimble division share an integer tick count. Sleeve engraving and rotating thimble are derived from those coordinates. Physical spindle stops at defined wire thickness b; a ≥ b. A one-turn button changes opening by p. The ratchet-to-contact action sets a = b; it does not calculate contact force. Thermal expansion, backlash, compliance and screw manufacturing error are excluded. Range 0–25 mm.

### Spherometer
The parameter r is centre-to-outer-leg distance, not leg separation. Equilateral leg spacing l = sqrt(3) r. With signed sagitta h = screw reading − plane reference:

R = (r² + h²)/(2h) = l²/(6h) + h/2.

Positive h denotes a convex rise and negative h a concave depression. The signed radius follows this convention. For |h| < 1 nm, report a flat/undefined finite radius rather than divide by zero. This guard is far below the instrument's 0.01 mm resolution. r is an exact defined input in this phase. Near-zero h makes inferred R very sensitive to reading error. For uncertainty analysis with independent u(r), u(h), the derivatives are ∂R/∂r = r/h and ∂R/∂h = 1/2 − r²/(2h²). The curve is an exaggerated cross-section, not a scale drawing of the whole sphere.

Default r = 50 mm, h = 0.44 mm gives R = 2841.12909 mm. The target image's conflicting labels/readings are not used as data.

### Mass & Time
Balance mass is a defined simulated parameter in kg. The display rounds to 0.01 g. Tare subtracts the current indicated mass; it does not change the defined object's mass. Weight is m × 9.80665 N/kg, using conventional standard gravity.

The ball follows ideal one-dimensional constant-acceleration translation:
x(t) = v₀t + at²/2, v₀ > 0, a ≥ 0. Friction, drag, rolling inertia and reaction-time noise are omitted. The track angle is illustrative; acceleration is a defined parameter, not derived from that drawn angle. The ball's displayed fraction along the track is x(t)/d. At the finish, time is clamped to the positive root of x(t) = d. Average speed uses distance actually travelled at the captured time, not full distance divided by a partial time. Defaults d = 0.5 m, v₀ = 0.2 m/s, a = 0.3 m/s² give t = 1.27698396495 s and average speed 0.391547594742 m/s.

Dart Stopwatch supplies a monotonic elapsed source. UI updates are requested about every 33 ms, without claiming a measured frame rate. Leaving Experiment, backgrounding, recording or saving pauses time. Restore is always paused and does not count background wall time. Recording captures speed, balance indication and elapsed time as distinct quantities. Speed is derived and has no independently assigned instrument resolution. The timing display uses 0.001 s resolution; it does not imply millisecond human timing accuracy.

### Uncertainty
Data are user-entered or imported compatible actual saved records. Supported input quantities are length (m), mass (kg), time (s). Units are canonical SI; incompatible quantities cannot be imported. The learner must still confirm that the observations refer to the same object and protocol. Mixed known resolutions use the larger selected resolution conservatively. No automatic deduction of calibration uncertainty is made.

For n independent repeated observations:
- mean = sum(xᵢ)/n;
- sample SD s = sqrt(sum((xᵢ − mean)²)/(n−1)), n ≥ 2;
- SEM = s/sqrt(n), n ≥ 2;
- instrument quantization standard uncertainty uᵢ = q/sqrt(12), when resolution is known;
- combined standard uncertainty of the mean u꜀ = sqrt(SEM² + uᵢ²), with independent components and coverage factor k = 1;
- percentage = 100u꜀/|mean|, undefined at mean = 0.

No readings → no estimate. One reading → mean available; sample SD, SEM and combined estimate unavailable. Missing resolution → instrument and combined estimates unavailable. Zero mean → absolute statistics remain valid, percentage undefined. The chart shows per-observation quantization bars and a mean line; spread, SEM and instrument uncertainty are reported separately. Half-range is never used as a universal uncertainty rule.

The two-input calculator uses first-order independent derivative propagation:
- sum/difference: u² = u(a)² + u(b)²;
- product: u² = b²u(a)² + a²u(b)²;
- quotient: u² = u(a)²/b² + a²u(b)²/b⁴, b ≠ 0.

Derivative forms remain defined when a = 0. Inputs must be finite and uncertainties nonnegative. Correlated inputs, large nonlinear uncertainty, coverage intervals and Monte Carlo propagation are beyond this introductory calculator. The instrument component is retained as a separate contribution; learners must avoid double-counting random rounding already represented by Type A data in a real uncertainty budget.

## Sources and verification

Equations are implemented independently, not copied from screenshots or source illustrations. Lesson prose is original. Numerical examples are calculated from the implemented equations and unit tested.

- NIST Type A evaluation: https://physics.nist.gov/cuu/Uncertainty/typea.html — sample mean and uncertainty of the mean. Retrieved during development.
- NIST Type B evaluation: https://physics.nist.gov/cuu/Uncertainty/typeb.html — rectangular bounds and standard uncertainty. Retrieved during development.
- NIST combining components: https://physics.nist.gov/cuu/Uncertainty/combination.html — first-order propagation and uncorrelated components. Retrieved during development.
- OpenStax University Physics Vol. 1, §3.4: https://openstax.org/books/university-physics-volume-1/pages/3-4-motion-with-constant-acceleration — constant-acceleration motion and average velocity. Retrieved during development.
- NCERT laboratory manual listing: https://ciet.ncert.gov.in/activity/grade11?lang=en — identifies experiments on vernier calipers, screw gauge and spherometer. The linked NCERT manual PDF timed out in this environment; do not treat that PDF as a successfully retrieved validation. Spherometer equivalence is independently derived from (R − h)² + r² = R² and tested.
- Introductory topic bibliography: OpenStax University Physics Volumes 1–3: https://openstax.org/details/books/university-physics-volume-1 , https://openstax.org/details/books/university-physics-volume-2 , https://openstax.org/details/books/university-physics-volume-3 . These are broad curriculum references, not a claim that all 96 future lab models have been validated.

## Future studios

Every non-Measurement destination has its own catalog principle and equation. Domain assumptions identify the limits of those equations. Experiment and Visualization explicitly identify later-phase availability. No results or controls pretend that these later simulations are implemented. Concept Overview provides basic catalog navigation, a recommended path, Measurement launching, a textual precision comparison and one introductory explained question.
