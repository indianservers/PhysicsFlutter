const apparatusNames = [
  'Metric ruler with 1 mm divisions; movable metal block; two endpoint markers.',
  'External-jaw vernier caliper; 1 mm main scale; 10 vernier divisions spanning 9 mm; ideal cylindrical object.',
  '0–25 mm micrometer; frame, anvil, spindle, sleeve, 50-division thimble and simplified ratchet; wire.',
  'Three equidistant outer legs; central screw; plane reference; spherical glass surface.',
  'Simulated digital balance with 0.01 g resolution; ideal one-dimensional track; ball; monotonic stopwatch.',
  'Manual numerical readings or compatible saved trials; instrument resolution; independent-input propagation calculator.',
];
const procedures = [
  '1. Position the block on the ruler.\n2. Align A and B to its endpoints using the handles or precise inputs.\n3. Read B − A before revealing the answer.\n4. Record several independent placements. Pinch zoom changes only the view.',
  '1. Set the signed zero error from a closed-jaw calibration.\n2. Open the external jaws.\n3. Read the main scale just before the vernier zero.\n4. Find the coincident vernier division.\n5. Add the contributions, subtract the signed zero error, then record.',
  '1. Set the simulated wire thickness.\n2. Drag or rotate the thimble; one revolution advances 0.5 mm.\n3. Use the contact button to close gently onto the wire.\n4. Read sleeve and thimble, including half-millimetre marks.\n5. Subtract signed zero error and record. Force is not simulated.',
  '1. Select Plane reference and zero the screw.\n2. Adjust the screw reading on the spherical surface.\n3. Set centre-to-outer-leg distance r.\n4. Compute h = screw − reference.\n5. Record the signed radius. Positive h denotes a convex rise; negative h denotes a concave depression.',
  '1. Choose the defined mass parameter; the phone does not weigh anything.\n2. Tare to subtract the current mass indication.\n3. Set track distance, initial speed and constant acceleration.\n4. Start the stopwatch and observe the ball.\n5. Pause or wait for the finish, then record distance travelled / elapsed time.',
  '1. Select a quantity and SI unit.\n2. Set the instrument resolution q.\n3. Add independent readings manually or import compatible saved trials.\n4. Compare sample standard deviation s with standard error s/√n.\n5. Combine independent Type A and quantization components in quadrature.\n6. Record the mean with its configuration.',
];
const mistakes = [
  'Do not assume an object begins at zero. Avoid parallax by viewing normal to the ruler. Do not confuse centimetres with millimetres.',
  'Read just left of the vernier zero, not the closest main tick. A negative zero error must be subtracted as a negative number.',
  'Do not miss a sleeve half-millimetre mark. Do not confuse pitch with least count. Excessive contact force is not represented in this ideal model.',
  'Do not substitute leg-to-leg spacing l for the centre radius r: l = √3 r. Near-flat readings amplify radius uncertainty strongly.',
  'Mass in kg differs from weight in N. Never divide the full track distance by a partial-run time. This track ignores rolling inertia, drag and friction.',
  'Spread is not uncertainty of the mean. Half the range is not a universal uncertainty estimate. Unit compatibility does not establish that two measurements are of the same object.',
];
const errors = [
  'Resolution: 1 mm. Each endpoint is modeled as rounded within ±0.5 mm, uniformly distributed. Length standard uncertainty = √2 × 1 mm / √12. Alignment and parallax are discussed but not randomized.',
  'Least count: 0.1 mm. The ideal vernier scale has 10 divisions across 9 mm. Quantization standard uncertainty q/√12; zero calibration uncertainty is assumed negligible unless discussed separately.',
  'Pitch: 0.5 mm/revolution. Divisions: 50. Least count: 0.01 mm. The sleeve and circular scale share one integer tick count. Contact deformation, backlash and temperature expansion are excluded.',
  'Screw resolution: 0.01 mm. r is an exact defined parameter in this model. R is undefined at h = 0; a flat plane has infinite curvature radius. Uncertainty in h becomes dominant near zero.',
  'Monotonic elapsed time is accumulated only while running. Navigating away or backgrounding pauses the experiment; restored sessions remain paused. Track motion follows x = v₀t + ½at² with constant positive v₀ and a ≥ 0.',
  'Quantization is modeled as uniform in ±q/2, so uᵢ = q/√12. Combined uncertainty of the mean is √(SEM² + uᵢ²), assuming independent components. With fewer than two readings the sample spread and combined estimate are unavailable.',
];
const questions = [
  'Why does subtracting two endpoint positions remove the need to align the object to zero?',
  'If the observed reading is 23.6 mm and the signed zero error is +0.2 mm, why is the corrected reading 23.4 mm?',
  'How far does the spindle move in two turns? Why does that differ from two thimble divisions?',
  'What happens to the inferred radius when the signed sagitta approaches zero?',
  'Why is final speed different from average speed for an accelerating ball?',
  'Why can more readings reduce the standard error without changing the instrument resolution?',
];
const substitutions = [
  'Example: A = 12 mm, B = 66 mm → L = 54 mm. Standard uncertainty from two rounded endpoints is 0.408 mm.',
  'Example: M = 23 mm; n = 6; LC = 0.1 mm; e₀ = +0.2 mm → x = 23 + 0.6 − 0.2 = 23.4 mm.',
  'Example: sleeve = 0.50 mm, n = 2, LC = 0.01 mm, zero error = 0 → x = 0.52 mm.',
  'Example: r = 50 mm, h = 0.44 mm → R = (2500 + 0.1936) / 0.88 = 2841.129 mm. Here l = 86.603 mm.',
  'Example: d = 0.5 m, v₀ = 0.2 m/s, a = 0.3 m/s² → t = 1.27698 s; average speed ≈ 0.39155 m/s.',
  'Example: [1, 2, 3] m, q = 0.1 m → mean = 2 m; s = 1 m; SEM = 0.57735 m; uᵢ = 0.02887 m; u꜀ = 0.57807 m.',
];
const symbols = [
  'A, B: endpoint positions (m). L: positive length (m). Resolution q = 0.001 m. Range: 0–0.1 m.',
  'M: main-scale contribution (m). n: vernier coincidence index, 0–9. LC = 0.0001 m. e₀: signed zero error (m). External measurements only, 0–50 mm.',
  'p: pitch (0.0005 m per turn). N: 50 divisions per turn. LC: 0.00001 m. Observed x = sleeve + n LC. Corrected x = observed − e₀. Range 0–25 mm.',
  'r: centre-to-outer-leg distance (m), 10–100 mm. l = √3 r: equilateral leg-to-leg distance. h: signed sagitta (m), ±3 mm. R: signed curvature radius (m). Spherical surface assumed.',
  'x,d: distance (m). v₀: initial speed (m/s). a: constant acceleration (m/s²). t: elapsed time (s). Average speed = x(t)/t. Weight = mg with g = 9.80665 m/s² (conventional standard gravity).',
  'n: count. q: instrument resolution (same SI unit as data). s: sample standard deviation using n−1. SEM = s/√n. uᵢ = q/√12. u꜀: combined standard uncertainty, coverage factor k = 1. Percentage = 100u꜀/|mean|, undefined at zero mean.',
];
