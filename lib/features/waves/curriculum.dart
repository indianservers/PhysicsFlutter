import '../dynamics/curriculum.dart' show DynamicsLesson, Parameter;
export '../dynamics/curriculum.dart' show DynamicsLesson, Parameter;

const amp = Parameter('amplitude', 'Displacement amplitude', 'm', 0, .04, .02);
const probe = Parameter('probe', 'Probe x', 'm', 0, 2, .6);
const frequency = Parameter('frequency', 'Source frequency', 'Hz', .5, 5, 2);
const phase = Parameter(
  'phase',
  'Relative / initial phase',
  'rad',
  -3.141592653589793,
  3.141592653589793,
  0,
);
const wavelength = Parameter('wavelength', 'Wavelength', 'm', .15, 1, .4);
const opticalWavelength = Parameter(
  'wavelength',
  'Vacuum wavelength',
  'm',
  380e-9,
  750e-9,
  650e-9,
);
const objectDistance = Parameter('u', 'Object distance u', 'm', .05, 1, .3);
const focal = Parameter('focal', 'Focal-length magnitude', 'm', .05, .3, .1);
const height = Parameter('height', 'Object height', 'm', .001, .02, .004);
const screen = Parameter('screen', 'Screen distance', 'm', .05, 1, .3);
const slitScreen = Parameter(
  'screen',
  'Slit-to-screen distance',
  'm',
  .5,
  3,
  1,
);
const detector = Parameter('probe', 'Detector y', 'm', -.03, .03, 0);

const waveLessons = <DynamicsLesson>[
  DynamicsLesson(
    'Glass ripple tank, driven paddle, surface-height markers and a fixed material probe.',
    'Choose independent amplitude, frequency and wavelength; speed is derived as fλ. Material points oscillate locally while the phase pattern travels. The moving trace is a height field, not water flowing with the crest.',
    'Change A, f and λ; switch travel direction. Drag the probe, compare the same spatial samples with the string/tank profile and inspect the time history at the probe.',
    'Nondispersive linear teaching family with independently selected f and λ (therefore different derived speeds); not a fixed real water dispersion relation or full fluid simulation. 0.1× physical time at 1× selector; 513 spatial samples over 2 m. Height exaggerated.',
    'Wave speed is not the local material-point velocity. Choosing f, λ and v independently would overconstrain this model.',
    'Predict wave speed from the current frequency and wavelength.',
    r'y=A\sin(kx-s\omega t+\phi),\quad k=2\pi/\lambda,\quad \omega=2\pi f,\quad v=f\lambda',
    'x,y,λ m; A m; f Hz; s=+1 right, −1 left; phase radians. Positive y is upward surface displacement.',
    'f=2 Hz and λ=0.4 m gives v=0.8 m/s. A local probe remains at the same x.',
    'waveSpeed',
    'm/s',
    [amp, frequency, wavelength, phase, probe],
  ),
  DynamicsLesson(
    'Long elastic teaching string with two signed Gaussian pulses and end supports outside the displayed interval.',
    'Linear displacements add at every point. Opposite equal pulses can cancel during overlap and continue unchanged afterward; the pulses are not colliding material bodies.',
    'Set signed amplitudes, widths, starting centres and directions. Use common medium speed. Play or scrub through overlap; compare blue/amber components and the navy sum. Try equal/opposite amplitudes.',
    'Infinite ideal linear nondispersive string, shown over x=−1…1 m; no endpoint reflections. Gaussian standard deviations define widths. 513 points, min width 0.04 m gives ≥10 samples per σ. 0.1× physical time. No material collision.',
    'Zero resultant displacement at one instant does not mean the waves have been destroyed.',
    'Predict the current summed probe displacement.',
    r'y_i=A_i\exp[-(x-x_{i0}-s_i ct)^2/(2\sigma_i^2)],\quad y=y_1+y_2',
    'A signed m; σ m; c common m/s; si=±1; x centres m; t s. Individual curves and the string share identical samples.',
    'At coincident centres, amplitudes +0.02 m and −0.02 m sum to zero everywhere when widths agree.',
    'sum',
    'm',
    [
      Parameter('a1', 'Pulse 1 signed amplitude', 'm', -.05, .05, .025),
      Parameter('a2', 'Pulse 2 signed amplitude', 'm', -.05, .05, -.02),
      Parameter('width1', 'Pulse 1 width σ', 'm', .04, .25, .1),
      Parameter('width2', 'Pulse 2 width σ', 'm', .04, .25, .1),
      Parameter('x1', 'Pulse 1 initial centre', 'm', -.8, .8, -.5),
      Parameter('x2', 'Pulse 2 initial centre', 'm', -.8, .8, .5),
      Parameter('d1', 'Pulse 1 direction', '', -1, 1, 1),
      Parameter('d2', 'Pulse 2 direction', '', -1, 1, -1),
      Parameter('speed', 'Common wave speed', 'm/s', .1, 1, .4),
      Parameter('probe', 'Probe x', 'm', -1, 1, 0),
    ],
  ),
  DynamicsLesson(
    'Transparent ripple tank with two coherent driven pins and a movable two-dimensional probe.',
    'The instantaneous height is a sum of two equal-frequency circular phase waves. Complex phasors give resultant amplitude and the time-averaged squared-height proxy. Path difference and relative source phase both matter.',
    'Move the probe in x and z; change spacing, common frequency, phase and amplitude ratio. Compare signed instantaneous displacement with normalized time-averaged intensity. Equal paths cancel for equal amplitudes and phase π.',
    'Constant-amplitude circular waves, no radial decay or source singularity, infinite linear teaching medium; no water dispersion, reflections or fluid dynamics. λ=c/f. 64×32 cached phasors; 257-point probe cross-section. The intensity proxy is normalized mean squared displacement, not optical brightness or calibrated acoustic power.',
    'Bright instantaneous positive height is not the same as time-averaged intensity. No far-field fringe formula is applied to this finite geometry.',
    'Predict the normalized time-averaged intensity at the probe.',
    r'y=A\sin(kr_1-\omega t)+qA\sin(kr_2-\omega t+\phi),\quad I_{rel}=\frac{1+q^2+2q\cos(k\Delta r+\phi)}{(1+q)^2}',
    'r1,r2 centre distances m; q amplitude ratio; Δr=r2−r1 m; φ rad; intensity proxy dimensionless 0–1.',
    'At equal paths q=1: φ=0 gives Irel=1; φ=π gives Irel=0.',
    'intensity',
    '',
    [
      Parameter('spacing', 'Source separation', 'm', .1, 1, .5),
      frequency,
      Parameter('speed', 'Medium wave speed', 'm/s', .5, 2, 1),
      phase,
      Parameter('ratio', 'Source 2 / source 1 amplitude', '', 0, 2, 1),
      Parameter('amplitude', 'Source 1 amplitude', 'm', .005, .03, .015),
      Parameter('probe', 'Probe x', 'm', -1, 1, 0),
      Parameter('z', 'Probe z', 'm', -.5, .5, .25),
    ],
  ),
  DynamicsLesson(
    'Stretched string, two rigid clamps, tensioning weight and marked material probe.',
    'Fixed ends allow harmonics with λn=2L/n and fn=n√(T/μ)/(2L). Nodes including both ends remain at zero; n−1 interior nodes separate n antinodes. Two opposite traveling components of amplitude A/2 give A sin(kx)cosωt.',
    'Choose L, tension, linear density and integer n. Count nodes and antinodes; inspect equal traveling components. Move the probe and compare its time signal with the spatial shape.',
    'Small-amplitude ideal flexible uniform string with fixed endpoints; no stiffness, damping or nonlinear tension. A≤0.02 m and A is further limited to 0.02L/n. 0.001× physical time; 513 spatial points.',
    'A standing wave is not a stationary material shape: antinodes move while nodes do not.',
    'Predict harmonic frequency (node count includes the endpoints).',
    r'v=\sqrt{T/\mu},\quad \lambda_n=2L/n,\quad f_n=nv/(2L),\quad y=A\sin(n\pi x/L)\cos(2\pi f_nt)',
    'T N; μ kg/m; L m; n integer 1–6; A m; f Hz; node positions jL/n for j=0…n.',
    'L=1 m, T=50 N, μ=0.02 kg/m, n=2 gives v=50 m/s and f2=50 Hz.',
    'frequency',
    'Hz',
    [
      Parameter('length', 'String length', 'm', .5, 2, 1),
      Parameter('tension', 'String tension', 'N', 10, 100, 50),
      Parameter('density', 'Linear mass density', 'kg/m', .005, .05, .02),
      Parameter('harmonic', 'Harmonic n', '', 1, 6, 2),
      Parameter('amplitude', 'Standing amplitude', 'm', .001, .02, .008),
      Parameter('probe', 'Probe x', 'm', 0, 2, .25),
    ],
  ),
  DynamicsLesson(
    'Metal microphone on a stable stand and a tuning fork; generated and live input are separate modes.',
    'A sampled waveform can be decomposed into Fourier bins. The one-sided Hann spectrum is normalized by coherent window gain. A frequency between bins leaks into neighbours; a peak bin is an estimate with finite resolution, not a calibrated SPL measurement.',
    'Without permission choose sine, two tones or a band-limited odd-harmonic signal. Predict peaks, inspect waveform and spectrum. Optionally choose microphone, read the explanation and explicitly start listening; Stop ends capture. Record saves analyzed bins/metrics only for microphone input.',
    'Generated: 2048 samples at 16,384 Hz, Δf=8 Hz, Nyquist=8192 Hz; harmonic-rich mode retains odd terms 1,3,5,7 strictly below Nyquist. Microphone: mono PCM16, requested 48 kHz with actual plugin-adjusted output rate honored; 2048 samples, Hann window, no interpolation; no automatic raw audio storage/upload or background capture. Relative full-scale amplitude, not dB SPL. Generated visualization clock is 0.0001×; listening uses real time independently.',
    'More FFT bins are not proof of better physical calibration. A Hann window reduces leakage but does not remove finite-window uncertainty.',
    'Predict the strongest detected frequency bin.',
    r'X_k=\sum_{j=0}^{N-1}(x_j-\bar x)w_j e^{-i2\pi kj/N},\quad \Delta f=f_s/N,\quad A_k=2|X_k|/\sum_jw_j',
    'fs Hz; N=2048; wj Hann; amplitudes relative to full-scale PCM; DC/Nyquist bins use factor 1. Peaks are integer-bin estimates, no interpolation.',
    'At fs=16384 Hz and N=2048, a 440 Hz bin-centred sine has bin 55; a second 880 Hz tone appears at bin 110.',
    'peakFrequency',
    'Hz',
    [
      Parameter('frequency', 'Fundamental frequency', 'Hz', 100, 2000, 440),
      Parameter('amplitude', 'Generated peak scale', 'FS', .05, .8, .6),
      Parameter('frequency2', 'Second tone frequency', 'Hz', 100, 4000, 880),
      Parameter('ratio', 'Second / first amplitude', '', 0, 1, .5),
    ],
  ),
  DynamicsLesson(
    'Moving sound-source cart, stationary microphone and emission-origin spherical wavefront cross-sections.',
    'Reception time t equals emission time τ plus propagation delay. Wavefront centres are the source position at emission, not its current position. Subsonic collinear approach compresses received periods; recession stretches them.',
    'Adjust source Mach fraction, frequency, sound speed, initial position and observer position. Inspect past emission centres and the retarded source. Compare source and received frequencies before/after a pass along the same line.',
    'Stationary medium and observer; constant-speed eternally emitting point source on the x axis; |v|≤0.7c. Both approach/recession use the unique retarded time. Frequency undefined at source-observer coincidence. Circles show every ceil(0.03f)th emitted crest, latest 32 fronts, not all audible cycles. 0.5× physical time; no supersonic controls, atmospheric effects or audio playback.',
    'A 2D circle diagram does not justify applying a collinear formula at an off-axis observer. This observer is restricted to the source axis.',
    'Predict received frequency from the retarded collinear geometry.',
    r't=\tau+|x_o-x_0-v_s\tau|/c,\quad f_o=f_s\frac c{c-v_s\operatorname{sgn}(x_o-x_s(\tau))}',
    'c,vs m/s; source Mach=vs/c; x positions m; t,τ s; f Hz. Positive source velocity points right.',
    'c=343 m/s, vs=30 m/s toward an observer, fs=600 Hz gives 657.51 Hz, not 705 Hz in the reference.',
    'observedFrequency',
    'Hz',
    [
      Parameter('mach', 'Signed source Mach fraction', '', -.7, .7, .1),
      Parameter('frequency', 'Source frequency', 'Hz', 200, 1000, 600),
      Parameter('c', 'Sound speed', 'm/s', 250, 400, 343),
      Parameter('x0', 'Source position at t=0', 'm', -80, 80, -60),
      Parameter('observer', 'Observer x on source axis', 'm', -80, 80, 70),
    ],
  ),
  DynamicsLesson(
    'Plane mirror on an optical bench, adjustable light source and normal at the actual hit point.',
    'The ray-plane intersection determines where reflection occurs. The reflected unit direction is d−2(d·n)n; incident and reflected angles measured from the normal agree.',
    'Drag the source to change incidence or edit angle and hit position. Toggle overlays, inspect the normal and angle arcs, and compare the equality curve.',
    'Ideal plane reflecting surface at y=0, normal +y. Ray paths in clear air are instructional overlays, not visible beams or measured power. Angles 0–85°; finite mirror hit is constrained within its extent.',
    'The angle is measured from the normal, not the mirror surface.',
    'Predict reflected angle from the normal.',
    r'\vec r=\vec d-2(\vec d\cdot\hat n)\hat n,\quad \theta_r=\theta_i',
    'Directions unit vectors; θ degrees displayed; hit x m; normal perpendicular to the actual plane.',
    'At incidence 30° from the normal, reflection is 30° from the normal, or 60° from the surface.',
    'reflectedAngle',
    '°',
    [
      Parameter('angle', 'Incident angle from normal', '°', 0, 85, 30),
      Parameter('hit', 'Mirror hit coordinate', 'm', -.2, .2, 0),
    ],
  ),
  DynamicsLesson(
    'Homogeneous glass boundary, incident light source and exact normal/intersection overlay.',
    'Snell’s law determines transmission direction. Speed and wavelength change while frequency remains continuous. From higher to lower index there is a critical angle and then no ordinary transmitted propagating ray.',
    'Change both indices, angle and vacuum wavelength. Compare normal/equal-index cases, use the critical-angle preset and cross into total internal reflection. Inspect current wavelengths and frequency.',
    'Two semi-infinite homogeneous isotropic nondispersive media with a plane boundary; no Fresnel intensity or polarization percentages. Radicand tolerance 10⁻¹² handles grazing critical transmission. Optical rays are static instructional paths; no optical-frequency motion is faked.',
    'Frequency does not decrease in glass. Total internal reflection does not include a normal transmitted beam into the second medium.',
    'Predict whether an ordinary transmitted ray exists; numeric target is the incident angle.',
    r'n_1\sin\theta_1=n_2\sin\theta_2,\quad v_j=c_0/n_j,\quad \lambda_j=\lambda_0/n_j,\quad f=c_0/\lambda_0',
    'n dimensionless; θ relative to normal; c0=299792458 m/s; vacuum λ0 m; critical angle asin(n2/n1) only if n1>n2.',
    'Air 1.00 to glass 1.50 at 40° gives about 25.374° transmission. Glass to air has critical angle about 41.810°.',
    'incidentAngle',
    '°',
    [
      Parameter('angle', 'Incidence from normal', '°', 0, 85, 40),
      Parameter('hit', 'Boundary hit coordinate', 'm', -.2, .2, 0),
      Parameter('n1', 'Index of incident medium', '', 1, 2.5, 1),
      Parameter('n2', 'Index of second medium', '', 1, 2.5, 1.5),
      opticalWavelength,
    ],
  ),
  DynamicsLesson(
    'Thin converging/diverging glass lens, object, calibrated optical rail and movable screen.',
    'For a real object on the left, signed f is positive for converging and negative for diverging. Real image distance v is positive to the right; virtual v is negative. Magnification −v/u gives orientation. The image vergence 1/v remains finite at the focal limit.',
    'Try beyond 2f, at 2f, between f and 2f, at f and inside f, then diverging mode. Drag the object, align a physical screen only for a real image, and inspect dashed backward extensions for a virtual image.',
    'Thin-lens/paraxial model with real u>0. Object height is limited to 0.08min(u,|f|); vertical display magnification is labeled. At |u−f|≤10⁻¹⁰max(1,u), image is at infinity. Very distant images may be outside the labeled viewport; numerical positions are not clipped. No thick-lens or calibrated blur model.',
    'Virtual images cannot be caught on a screen. At f an arbitrary huge finite image is not a valid substitute for infinity.',
    'Predict image type/orientation and image vergence (1/v).',
    r'1/f=1/u+1/v,\quad m=-v/u,\quad h_i=mh_o,\quad 1/v=1/f-1/u',
    'u>0 m for a real object; signed f m; v>0 real/right, v<0 virtual/left; m dimensionless; vergence m⁻¹. Incident light travels left→right.',
    'f=0.10 m, u=0.25 m gives v=0.166667 m, m=−0.666667. u=f gives image at infinity.',
    'imageVergence',
    'm⁻¹',
    [objectDistance, focal, height, screen],
  ),
  DynamicsLesson(
    'Concave/convex spherical mirror on a rail, object, focal and curvature markers, and optional real-image screen.',
    'The real-is-positive paraxial mirror equation uses f>0 concave and f<0 convex. Real images are in front of the mirror (left); virtual images are behind it. The surface has radius |2f| and its centre/focus agree with the chosen mode.',
    'Change mode, object and focal length. Test centre of curvature u=2f, focal u=f and inside-f cases. Inspect principal rays, virtual extensions and screen eligibility.',
    'Paraxial image equation with real object u>0; small off-axis object height guard as for lenses. The spherical surface intersections and reflection directions are geometrically traced; the predicted image uses the paraxial limit, so small spherical-aberration differences are not claimed exact. At f, image-at-infinity is reported.',
    'A convex mirror has negative focal length in this convention; a virtual image remains upright and cannot be projected.',
    'Predict image classification and image vergence.',
    r'1/f=1/u+1/v,\quad m=-v/u,\quad R=2f',
    'u,v real-positive distances from vertex; world object x=−u, image x=−v, F=−f, C=−2f. Height units m; vergence m⁻¹.',
    'Concave f=0.15 m and u=0.30 m gives real v=0.30 m and m=−1.',
    'imageVergence',
    'm⁻¹',
    [
      objectDistance,
      Parameter('focal', 'Focal-length magnitude', 'm', .05, .3, .15),
      height,
      screen,
    ],
  ),
  DynamicsLesson(
    'Coherent monochromatic source, two narrow slits, physical screen and movable detector.',
    'Fraunhofer double-slit angular intensity is cos²(πd sinθ/λ). Screen coordinates use sinθ=y/√(L²+y²). The small-angle fringe spacing λL/d is labeled approximate; no finite-width envelope is silently invented.',
    'Change wavelength, slit separation, screen distance and detector y. Compare physical-screen brightness, intensity curve and exact detector value. Predict the approximate spacing after changing wavelength.',
    'Ideal narrow equally illuminated coherent slits, far field. Enforce d²/(λL)≤0.1; parameter edits may reduce d. Detector ±0.03 m, L≥0.5 m, so |θ|≤3.44°. 801 spatial samples. Display RGB is illustrative, not a calibrated spectrum. No optical carrier animation or finite-slit envelope.',
    'This optical double-slit lab is distinct from the finite-geometry mechanical two-source field. Far-field formulas cannot describe arbitrary near-field propagation.',
    'Predict the small-angle fringe spacing.',
    r'I/I_{max}=\cos^2(\pi d\sin\theta/\lambda),\quad \sin\theta=y/\sqrt{L^2+y^2},\quad \Delta y\simeq\lambda L/d',
    'Vacuum/air λ m (n=1), d slit-centre separation m, L m, detector y m; normalized intensity 0–1.',
    'λ=650 nm, L=0.5 m, d=0.20 mm gives approximate spacing 1.625 mm; a screen distance must be specified.',
    'spacing',
    'm',
    [
      opticalWavelength,
      Parameter(
        'aperture',
        'Slit centre separation',
        'm',
        50e-6,
        250e-6,
        200e-6,
      ),
      slitScreen,
      detector,
    ],
  ),
  DynamicsLesson(
    'Monochromatic source, single slit plate, intensity screen and detector.',
    'A finite slit produces a normalized sinc-squared Fraunhofer pattern. The β→0 limit is one. The first minima set an exact angular central-maximum width 2L tan(asin(λ/a)); narrower apertures broaden the pattern.',
    'Change wavelength, slit width and screen distance. Move the detector through the central and side lobes. Show minima markers and compare the exact central width with the small-angle approximation.',
    'Single uniform slit in air, Fraunhofer field, a²/(λL)≤0.1, no near-field solver. Finite display span ±30 mm with 801 samples. Nonzero integer minima must satisfy |mλ/a|<1 and lie in the shown screen region. RGB is illustrative.',
    'The central lobe is twice the small-angle width of adjacent lobes between minima. Narrower slits spread light more widely; they do not sharpen the central peak.',
    'Predict the central-maximum width between first minima.',
    r'I/I_0=(\sin\beta/\beta)^2,\quad \beta=\pi a\sin\theta/\lambda,\quad a\sin\theta=m\lambda',
    'a slit width m; λ m; L m; θ from optical axis; m nonzero integer; I relative, dimensionless. Small-angle width ≈2λL/a.',
    'λ=650 nm, a=100 μm and L=1 m gives central width about 13.0003 mm.',
    'centralWidth',
    'm',
    [
      opticalWavelength,
      Parameter('aperture', 'Slit width', 'm', 20e-6, 150e-6, 100e-6),
      slitScreen,
      detector,
    ],
  ),
];

String waveUnit(String k) => switch (k) {
  'sum' ||
  'first' ||
  'second' ||
  'probeAmplitude' ||
  'pathDifference' ||
  'wavelength' ||
  'imageDistance' ||
  'imageHeight' ||
  'focusError' ||
  'focal' ||
  'spacing' ||
  'centralWidth' ||
  'lambda1' ||
  'lambda2' ||
  'sourceX' ||
  'hitX' ||
  'retardedSourceX' => 'm',
  'waveSpeed' || 'speed1' || 'speed2' || 'sourceSpeed' => 'm/s',
  'frequency' ||
  'peakFrequency' ||
  'observedFrequency' ||
  'binWidth' ||
  'sampleRate' ||
  'nyquist' => 'Hz',
  'incidentAngle' ||
  'reflectedAngle' ||
  'transmittedAngle' ||
  'criticalAngle' ||
  'angle' => '°',
  'phase' || 'phaseDifference' => 'rad',
  'imageVergence' => 'm⁻¹',
  'emissionTime' => 's',
  _ => '',
};
String waveLabel(String k) =>
    const {
      'sum': 'Probe displacement',
      'first': 'Component 1',
      'second': 'Component 2',
      'waveSpeed': 'Derived wave speed',
      'frequency': 'Frequency',
      'wavelength': 'Wavelength',
      'phase': 'Phase',
      'probeAmplitude': 'Resultant amplitude',
      'intensity': 'Normalized mean intensity proxy',
      'pathDifference': 'Path difference',
      'phaseDifference': 'Phase difference',
      'nodeCount': 'Nodes including endpoints',
      'peakFrequency': 'Strongest FFT bin',
      'peakAmplitude': 'Relative peak amplitude',
      'rms': 'RMS (full scale)',
      'sampleRate': 'Actual output sample rate',
      'windowSize': 'Analysis samples',
      'binWidth': 'FFT bin spacing',
      'nyquist': 'Nyquist frequency',
      'sourceX': 'Source position now',
      'emissionTime': 'Retarded emission time',
      'retardedSourceX': 'Retarded source position',
      'observedFrequency': 'Received frequency',
      'sourceSpeed': 'Source velocity',
      'frontStride': 'Crest display stride',
      'incidentAngle': 'Incidence from normal',
      'reflectedAngle': 'Reflection from normal',
      'transmittedAngle': 'Transmission from normal',
      'criticalAngle': 'Critical angle',
      'speed1': 'Speed in medium 1',
      'speed2': 'Speed in medium 2',
      'lambda1': 'Wavelength in medium 1',
      'lambda2': 'Wavelength in medium 2',
      'tir': 'Total internal reflection (1=yes)',
      'imageVergence': 'Image vergence (1/v)',
      'imageDistance': 'Signed image distance',
      'magnification': 'Magnification',
      'imageHeight': 'Signed image height',
      'focusError': 'Screen focus-position error',
      'imageType': 'Image type (+1 real, −1 virtual, 0 infinity)',
      'infinity': 'Image at infinity (1=yes)',
      'spacing': 'Approximate fringe spacing',
      'centralWidth': 'Central maximum width',
      'fresnelNumber': 'Far-field aperture number',
    }[k] ??
    k;
List<String> waveMetrics(int k) => switch (k) {
  0 => ['waveSpeed', 'frequency', 'wavelength', 'sum', 'phase'],
  1 => ['first', 'second', 'sum'],
  2 => [
    'sum',
    'probeAmplitude',
    'intensity',
    'pathDifference',
    'phaseDifference',
    'wavelength',
  ],
  3 => ['frequency', 'waveSpeed', 'wavelength', 'nodeCount', 'sum'],
  4 => [
    'peakFrequency',
    'peakAmplitude',
    'rms',
    'sampleRate',
    'windowSize',
    'binWidth',
    'nyquist',
  ],
  5 => [
    'observedFrequency',
    'sourceSpeed',
    'sourceX',
    'emissionTime',
    'retardedSourceX',
    'frontStride',
  ],
  6 => ['incidentAngle', 'reflectedAngle', 'hitX'],
  7 => [
    'incidentAngle',
    'transmittedAngle',
    'criticalAngle',
    'tir',
    'speed1',
    'speed2',
    'lambda1',
    'lambda2',
    'frequency',
  ],
  8 || 9 => [
    'imageType',
    'imageDistance',
    'magnification',
    'imageHeight',
    'imageVergence',
    'focusError',
  ],
  _ => [
    'intensity',
    'spacing',
    if (k == 11) 'centralWidth',
    'fresnelNumber',
    'angle',
  ],
};
