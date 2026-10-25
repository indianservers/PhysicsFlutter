# Phase 4 per-lab scientific specification

Generated from the shipped curriculum by `dart run tool/phase4_evidence.dart`. Model `waves-optics-4.0`. Companion numerical/sampling notes: [PHASE4_SCIENCE.md](PHASE4_SCIENCE.md). These are ideal teaching models with the explicit limits below. All stored physical inputs use SI units.

## 1. Wave Properties

Stable ID: `s08-e00`.

Glass ripple tank, driven paddle, surface-height markers and a fixed material probe.

Choose independent amplitude, frequency and wavelength; speed is derived as fλ. Material points oscillate locally while the phase pattern travels. The moving trace is a height field, not water flowing with the crest.

Equation: `y=A\sin(kx-s\omega t+\phi),\quad k=2\pi/\lambda,\quad \omega=2\pi f,\quad v=f\lambda`

Symbols/convention: x,y,λ m; A m; f Hz; s=+1 right, −1 left; phase radians. Positive y is upward surface displacement.

Supported assumptions and limitations: Nondispersive linear teaching family with independently selected f and λ (therefore different derived speeds); not a fixed real water dispersion relation or full fluid simulation. 0.1× physical time at 1× selector; 513 spatial samples over 2 m. Height exaggerated.

Procedure: Change A, f and λ; switch travel direction. Drag the probe, compare the same spatial samples with the string/tank profile and inspect the time history at the probe.

Misconception: Wave speed is not the local material-point velocity. Choosing f, λ and v independently would overconstrain this model.

Worked example: f=2 Hz and λ=0.4 m gives v=0.8 m/s. A local probe remains at the same x.

Recorded primary quantity: `waveSpeed` (m/s).

Independent control bounds (dependent validity clamps may narrow them):

- Displacement amplitude (`amplitude`): 0.0 to 0.04 m; documented default 0.02.
- Source frequency (`frequency`): 0.5 to 5.0 Hz; documented default 2.0.
- Wavelength (`wavelength`): 0.15 to 1.0 m; documented default 0.4.
- Relative / initial phase (`phase`): -3.141592653589793 to 3.141592653589793 rad; documented default 0.0.
- Probe x (`probe`): 0.0 to 2.0 m; documented default 0.6.

## 2. Superposition

Stable ID: `s08-e01`.

Long elastic teaching string with two signed Gaussian pulses and end supports outside the displayed interval.

Linear displacements add at every point. Opposite equal pulses can cancel during overlap and continue unchanged afterward; the pulses are not colliding material bodies.

Equation: `y_i=A_i\exp[-(x-x_{i0}-s_i ct)^2/(2\sigma_i^2)],\quad y=y_1+y_2`

Symbols/convention: A signed m; σ m; c common m/s; si=±1; x centres m; t s. Individual curves and the string share identical samples.

Supported assumptions and limitations: Infinite ideal linear nondispersive string, shown over x=−1…1 m; no endpoint reflections. Gaussian standard deviations define widths. 513 points, min width 0.04 m gives ≥10 samples per σ. 0.1× physical time. No material collision.

Procedure: Set signed amplitudes, widths, starting centres and directions. Use common medium speed. Play or scrub through overlap; compare blue/amber components and the navy sum. Try equal/opposite amplitudes.

Misconception: Zero resultant displacement at one instant does not mean the waves have been destroyed.

Worked example: At coincident centres, amplitudes +0.02 m and −0.02 m sum to zero everywhere when widths agree.

Recorded primary quantity: `sum` (m).

Independent control bounds (dependent validity clamps may narrow them):

- Pulse 1 signed amplitude (`a1`): -0.05 to 0.05 m; documented default 0.025.
- Pulse 2 signed amplitude (`a2`): -0.05 to 0.05 m; documented default -0.02.
- Pulse 1 width σ (`width1`): 0.04 to 0.25 m; documented default 0.1.
- Pulse 2 width σ (`width2`): 0.04 to 0.25 m; documented default 0.1.
- Pulse 1 initial centre (`x1`): -0.8 to 0.8 m; documented default -0.5.
- Pulse 2 initial centre (`x2`): -0.8 to 0.8 m; documented default 0.5.
- Pulse 1 direction (`d1`): -1.0 to 1.0 ; documented default 1.0.
- Pulse 2 direction (`d2`): -1.0 to 1.0 ; documented default -1.0.
- Common wave speed (`speed`): 0.1 to 1.0 m/s; documented default 0.4.
- Probe x (`probe`): -1.0 to 1.0 m; documented default 0.0.

## 3. Interference — mechanical

Stable ID: `s08-e02`.

Transparent ripple tank with two coherent driven pins and a movable two-dimensional probe.

The instantaneous height is a sum of two equal-frequency circular phase waves. Complex phasors give resultant amplitude and the time-averaged squared-height proxy. Path difference and relative source phase both matter.

Equation: `y=A\sin(kr_1-\omega t)+qA\sin(kr_2-\omega t+\phi),\quad I_{rel}=\frac{1+q^2+2q\cos(k\Delta r+\phi)}{(1+q)^2}`

Symbols/convention: r1,r2 centre distances m; q amplitude ratio; Δr=r2−r1 m; φ rad; intensity proxy dimensionless 0–1.

Supported assumptions and limitations: Constant-amplitude circular waves, no radial decay or source singularity, infinite linear teaching medium; no water dispersion, reflections or fluid dynamics. λ=c/f. 64×32 cached phasors; 257-point probe cross-section. The intensity proxy is normalized mean squared displacement, not optical brightness or calibrated acoustic power.

Procedure: Move the probe in x and z; change spacing, common frequency, phase and amplitude ratio. Compare signed instantaneous displacement with normalized time-averaged intensity. Equal paths cancel for equal amplitudes and phase π.

Misconception: Bright instantaneous positive height is not the same as time-averaged intensity. No far-field fringe formula is applied to this finite geometry.

Worked example: At equal paths q=1: φ=0 gives Irel=1; φ=π gives Irel=0.

Recorded primary quantity: `intensity` (dimensionless).

Independent control bounds (dependent validity clamps may narrow them):

- Source separation (`spacing`): 0.1 to 1.0 m; documented default 0.5.
- Source frequency (`frequency`): 0.5 to 5.0 Hz; documented default 2.0.
- Medium wave speed (`speed`): 0.5 to 2.0 m/s; documented default 1.0.
- Relative / initial phase (`phase`): -3.141592653589793 to 3.141592653589793 rad; documented default 0.0.
- Source 2 / source 1 amplitude (`ratio`): 0.0 to 2.0 ; documented default 1.0.
- Source 1 amplitude (`amplitude`): 0.005 to 0.03 m; documented default 0.015.
- Probe x (`probe`): -1.0 to 1.0 m; documented default 0.0.
- Probe z (`z`): -0.5 to 0.5 m; documented default 0.25.

## 4. Standing Waves

Stable ID: `s08-e03`.

Stretched string, two rigid clamps, tensioning weight and marked material probe.

Fixed ends allow harmonics with λn=2L/n and fn=n√(T/μ)/(2L). Nodes including both ends remain at zero; n−1 interior nodes separate n antinodes. Two opposite traveling components of amplitude A/2 give A sin(kx)cosωt.

Equation: `v=\sqrt{T/\mu},\quad \lambda_n=2L/n,\quad f_n=nv/(2L),\quad y=A\sin(n\pi x/L)\cos(2\pi f_nt)`

Symbols/convention: T N; μ kg/m; L m; n integer 1–6; A m; f Hz; node positions jL/n for j=0…n.

Supported assumptions and limitations: Small-amplitude ideal flexible uniform string with fixed endpoints; no stiffness, damping or nonlinear tension. A≤0.02 m and A is further limited to 0.02L/n. 0.001× physical time; 513 spatial points.

Procedure: Choose L, tension, linear density and integer n. Count nodes and antinodes; inspect equal traveling components. Move the probe and compare its time signal with the spatial shape.

Misconception: A standing wave is not a stationary material shape: antinodes move while nodes do not.

Worked example: L=1 m, T=50 N, μ=0.02 kg/m, n=2 gives v=50 m/s and f2=50 Hz.

Recorded primary quantity: `frequency` (Hz).

Independent control bounds (dependent validity clamps may narrow them):

- String length (`length`): 0.5 to 2.0 m; documented default 1.0.
- String tension (`tension`): 10.0 to 100.0 N; documented default 50.0.
- Linear mass density (`density`): 0.005 to 0.05 kg/m; documented default 0.02.
- Harmonic n (`harmonic`): 1.0 to 6.0 ; documented default 2.0.
- Standing amplitude (`amplitude`): 0.001 to 0.02 m; documented default 0.008.
- Probe x (`probe`): 0.0 to 2.0 m; documented default 0.25.

## 5. Sound Spectrum

Stable ID: `s08-e04`.

Metal microphone on a stable stand and a tuning fork; generated and live input are separate modes.

A sampled waveform can be decomposed into Fourier bins. The one-sided Hann spectrum is normalized by coherent window gain. A frequency between bins leaks into neighbours; a peak bin is an estimate with finite resolution, not a calibrated SPL measurement.

Equation: `X_k=\sum_{j=0}^{N-1}(x_j-\bar x)w_j e^{-i2\pi kj/N},\quad \Delta f=f_s/N,\quad A_k=2|X_k|/\sum_jw_j`

Symbols/convention: fs Hz; N=2048; wj Hann; amplitudes relative to full-scale PCM; DC/Nyquist bins use factor 1. Peaks are integer-bin estimates, no interpolation.

Supported assumptions and limitations: Generated: 2048 samples at 16,384 Hz, Δf=8 Hz, Nyquist=8192 Hz; harmonic-rich mode retains odd terms 1,3,5,7 strictly below Nyquist. Microphone: mono PCM16, requested 48 kHz with actual plugin-adjusted output rate honored; 2048 samples, Hann window, no interpolation; no automatic raw audio storage/upload or background capture. Relative full-scale amplitude, not dB SPL. Generated visualization clock is 0.0001×; listening uses real time independently.

Procedure: Without permission choose sine, two tones or a band-limited odd-harmonic signal. Predict peaks, inspect waveform and spectrum. Optionally choose microphone, read the explanation and explicitly start listening; Stop ends capture. Record saves analyzed bins/metrics only for microphone input.

Misconception: More FFT bins are not proof of better physical calibration. A Hann window reduces leakage but does not remove finite-window uncertainty.

Worked example: At fs=16384 Hz and N=2048, a 440 Hz bin-centred sine has bin 55; a second 880 Hz tone appears at bin 110.

Recorded primary quantity: `peakFrequency` (Hz).

Independent control bounds (dependent validity clamps may narrow them):

- Fundamental frequency (`frequency`): 100.0 to 2000.0 Hz; documented default 440.0.
- Generated peak scale (`amplitude`): 0.05 to 0.8 FS; documented default 0.6.
- Second tone frequency (`frequency2`): 100.0 to 4000.0 Hz; documented default 880.0.
- Second / first amplitude (`ratio`): 0.0 to 1.0 ; documented default 0.5.

## 6. Doppler Effect

Stable ID: `s08-e05`.

Moving sound-source cart, stationary microphone and emission-origin spherical wavefront cross-sections.

Reception time t equals emission time τ plus propagation delay. Wavefront centres are the source position at emission, not its current position. Subsonic collinear approach compresses received periods; recession stretches them.

Equation: `t=\tau+|x_o-x_0-v_s\tau|/c,\quad f_o=f_s\frac c{c-v_s\operatorname{sgn}(x_o-x_s(\tau))}`

Symbols/convention: c,vs m/s; source Mach=vs/c; x positions m; t,τ s; f Hz. Positive source velocity points right.

Supported assumptions and limitations: Stationary medium and observer; constant-speed eternally emitting point source on the x axis; |v|≤0.7c. Both approach/recession use the unique retarded time. Frequency undefined at source-observer coincidence. Circles show every ceil(0.03f)th emitted crest, latest 32 fronts, not all audible cycles. 0.5× physical time; no supersonic controls, atmospheric effects or audio playback.

Procedure: Adjust source Mach fraction, frequency, sound speed, initial position and observer position. Inspect past emission centres and the retarded source. Compare source and received frequencies before/after a pass along the same line.

Misconception: A 2D circle diagram does not justify applying a collinear formula at an off-axis observer. This observer is restricted to the source axis.

Worked example: c=343 m/s, vs=30 m/s toward an observer, fs=600 Hz gives 657.51 Hz, not 705 Hz in the reference.

Recorded primary quantity: `observedFrequency` (Hz).

Independent control bounds (dependent validity clamps may narrow them):

- Signed source Mach fraction (`mach`): -0.7 to 0.7 ; documented default 0.1.
- Source frequency (`frequency`): 200.0 to 1000.0 Hz; documented default 600.0.
- Sound speed (`c`): 250.0 to 400.0 m/s; documented default 343.0.
- Source position at t=0 (`x0`): -80.0 to 80.0 m; documented default -60.0.
- Observer x on source axis (`observer`): -80.0 to 80.0 m; documented default 70.0.

## 7. Reflection

Stable ID: `s09-e00`.

Plane mirror on an optical bench, adjustable light source and normal at the actual hit point.

The ray-plane intersection determines where reflection occurs. The reflected unit direction is d−2(d·n)n; incident and reflected angles measured from the normal agree.

Equation: `\vec r=\vec d-2(\vec d\cdot\hat n)\hat n,\quad \theta_r=\theta_i`

Symbols/convention: Directions unit vectors; θ degrees displayed; hit x m; normal perpendicular to the actual plane.

Supported assumptions and limitations: Ideal plane reflecting surface at y=0, normal +y. Ray paths in clear air are instructional overlays, not visible beams or measured power. Angles 0–85°; finite mirror hit is constrained within its extent.

Procedure: Drag the source to change incidence or edit angle and hit position. Toggle overlays, inspect the normal and angle arcs, and compare the equality curve.

Misconception: The angle is measured from the normal, not the mirror surface.

Worked example: At incidence 30° from the normal, reflection is 30° from the normal, or 60° from the surface.

Recorded primary quantity: `reflectedAngle` (°).

Independent control bounds (dependent validity clamps may narrow them):

- Incident angle from normal (`angle`): 0.0 to 85.0 °; documented default 30.0.
- Mirror hit coordinate (`hit`): -0.2 to 0.2 m; documented default 0.0.

## 8. Refraction

Stable ID: `s09-e01`.

Homogeneous glass boundary, incident light source and exact normal/intersection overlay.

Snell’s law determines transmission direction. Speed and wavelength change while frequency remains continuous. From higher to lower index there is a critical angle and then no ordinary transmitted propagating ray.

Equation: `n_1\sin\theta_1=n_2\sin\theta_2,\quad v_j=c_0/n_j,\quad \lambda_j=\lambda_0/n_j,\quad f=c_0/\lambda_0`

Symbols/convention: n dimensionless; θ relative to normal; c0=299792458 m/s; vacuum λ0 m; critical angle asin(n2/n1) only if n1>n2.

Supported assumptions and limitations: Two semi-infinite homogeneous isotropic nondispersive media with a plane boundary; no Fresnel intensity or polarization percentages. Radicand tolerance 10⁻¹² handles grazing critical transmission. Optical rays are static instructional paths; no optical-frequency motion is faked.

Procedure: Change both indices, angle and vacuum wavelength. Compare normal/equal-index cases, use the critical-angle preset and cross into total internal reflection. Inspect current wavelengths and frequency.

Misconception: Frequency does not decrease in glass. Total internal reflection does not include a normal transmitted beam into the second medium.

Worked example: Air 1.00 to glass 1.50 at 40° gives about 25.374° transmission. Glass to air has critical angle about 41.810°.

Recorded primary quantity: `incidentAngle` (°).

Independent control bounds (dependent validity clamps may narrow them):

- Incidence from normal (`angle`): 0.0 to 85.0 °; documented default 40.0.
- Boundary hit coordinate (`hit`): -0.2 to 0.2 m; documented default 0.0.
- Index of incident medium (`n1`): 1.0 to 2.5 ; documented default 1.0.
- Index of second medium (`n2`): 1.0 to 2.5 ; documented default 1.5.
- Vacuum wavelength (`wavelength`): 3.8e-7 to 7.5e-7 m; documented default 6.5e-7.

## 9. Lenses

Stable ID: `s09-e02`.

Thin converging/diverging glass lens, object, calibrated optical rail and movable screen.

For a real object on the left, signed f is positive for converging and negative for diverging. Real image distance v is positive to the right; virtual v is negative. Magnification −v/u gives orientation. The image vergence 1/v remains finite at the focal limit.

Equation: `1/f=1/u+1/v,\quad m=-v/u,\quad h_i=mh_o,\quad 1/v=1/f-1/u`

Symbols/convention: u>0 m for a real object; signed f m; v>0 real/right, v<0 virtual/left; m dimensionless; vergence m⁻¹. Incident light travels left→right.

Supported assumptions and limitations: Thin-lens/paraxial model with real u>0. Object height is limited to 0.08min(u,|f|); vertical display magnification is labeled. At |u−f|≤10⁻¹⁰max(1,u), image is at infinity. Very distant images may be outside the labeled viewport; numerical positions are not clipped. No thick-lens or calibrated blur model.

Procedure: Try beyond 2f, at 2f, between f and 2f, at f and inside f, then diverging mode. Drag the object, align a physical screen only for a real image, and inspect dashed backward extensions for a virtual image.

Misconception: Virtual images cannot be caught on a screen. At f an arbitrary huge finite image is not a valid substitute for infinity.

Worked example: f=0.10 m, u=0.25 m gives v=0.166667 m, m=−0.666667. u=f gives image at infinity.

Recorded primary quantity: `imageVergence` (m⁻¹).

Independent control bounds (dependent validity clamps may narrow them):

- Object distance u (`u`): 0.05 to 1.0 m; documented default 0.3.
- Focal-length magnitude (`focal`): 0.05 to 0.3 m; documented default 0.1.
- Object height (`height`): 0.001 to 0.02 m; documented default 0.004.
- Screen distance (`screen`): 0.05 to 1.0 m; documented default 0.3.

## 10. Mirrors

Stable ID: `s09-e03`.

Concave/convex spherical mirror on a rail, object, focal and curvature markers, and optional real-image screen.

The real-is-positive paraxial mirror equation uses f>0 concave and f<0 convex. Real images are in front of the mirror (left); virtual images are behind it. The surface has radius |2f| and its centre/focus agree with the chosen mode.

Equation: `1/f=1/u+1/v,\quad m=-v/u,\quad R=2f`

Symbols/convention: u,v real-positive distances from vertex; world object x=−u, image x=−v, F=−f, C=−2f. Height units m; vergence m⁻¹.

Supported assumptions and limitations: Paraxial image equation with real object u>0; small off-axis object height guard as for lenses. The spherical surface intersections and reflection directions are geometrically traced; the predicted image uses the paraxial limit, so small spherical-aberration differences are not claimed exact. At f, image-at-infinity is reported.

Procedure: Change mode, object and focal length. Test centre of curvature u=2f, focal u=f and inside-f cases. Inspect principal rays, virtual extensions and screen eligibility.

Misconception: A convex mirror has negative focal length in this convention; a virtual image remains upright and cannot be projected.

Worked example: Concave f=0.15 m and u=0.30 m gives real v=0.30 m and m=−1.

Recorded primary quantity: `imageVergence` (m⁻¹).

Independent control bounds (dependent validity clamps may narrow them):

- Object distance u (`u`): 0.05 to 1.0 m; documented default 0.3.
- Focal-length magnitude (`focal`): 0.05 to 0.3 m; documented default 0.15.
- Object height (`height`): 0.001 to 0.02 m; documented default 0.004.
- Screen distance (`screen`): 0.05 to 1.0 m; documented default 0.3.

## 11. Interference — optical

Stable ID: `s09-e04`.

Coherent monochromatic source, two narrow slits, physical screen and movable detector.

Fraunhofer double-slit angular intensity is cos²(πd sinθ/λ). Screen coordinates use sinθ=y/√(L²+y²). The small-angle fringe spacing λL/d is labeled approximate; no finite-width envelope is silently invented.

Equation: `I/I_{max}=\cos^2(\pi d\sin\theta/\lambda),\quad \sin\theta=y/\sqrt{L^2+y^2},\quad \Delta y\simeq\lambda L/d`

Symbols/convention: Vacuum/air λ m (n=1), d slit-centre separation m, L m, detector y m; normalized intensity 0–1.

Supported assumptions and limitations: Ideal narrow equally illuminated coherent slits, far field. Enforce d²/(λL)≤0.1; parameter edits may reduce d. Detector ±0.03 m, L≥0.5 m, so |θ|≤3.44°. 801 spatial samples. Display RGB is illustrative, not a calibrated spectrum. No optical carrier animation or finite-slit envelope.

Procedure: Change wavelength, slit separation, screen distance and detector y. Compare physical-screen brightness, intensity curve and exact detector value. Predict the approximate spacing after changing wavelength.

Misconception: This optical double-slit lab is distinct from the finite-geometry mechanical two-source field. Far-field formulas cannot describe arbitrary near-field propagation.

Worked example: λ=650 nm, L=0.5 m, d=0.20 mm gives approximate spacing 1.625 mm; a screen distance must be specified.

Recorded primary quantity: `spacing` (m).

Independent control bounds (dependent validity clamps may narrow them):

- Vacuum wavelength (`wavelength`): 3.8e-7 to 7.5e-7 m; documented default 6.5e-7.
- Slit centre separation (`aperture`): 0.00005 to 0.00025 m; documented default 0.0002.
- Slit-to-screen distance (`screen`): 0.5 to 3.0 m; documented default 1.0.
- Detector y (`probe`): -0.03 to 0.03 m; documented default 0.0.

## 12. Diffraction

Stable ID: `s09-e05`.

Monochromatic source, single slit plate, intensity screen and detector.

A finite slit produces a normalized sinc-squared Fraunhofer pattern. The β→0 limit is one. The first minima set an exact angular central-maximum width 2L tan(asin(λ/a)); narrower apertures broaden the pattern.

Equation: `I/I_0=(\sin\beta/\beta)^2,\quad \beta=\pi a\sin\theta/\lambda,\quad a\sin\theta=m\lambda`

Symbols/convention: a slit width m; λ m; L m; θ from optical axis; m nonzero integer; I relative, dimensionless. Small-angle width ≈2λL/a.

Supported assumptions and limitations: Single uniform slit in air, Fraunhofer field, a²/(λL)≤0.1, no near-field solver. Finite display span ±30 mm with 801 samples. Nonzero integer minima must satisfy |mλ/a|<1 and lie in the shown screen region. RGB is illustrative.

Procedure: Change wavelength, slit width and screen distance. Move the detector through the central and side lobes. Show minima markers and compare the exact central width with the small-angle approximation.

Misconception: The central lobe is twice the small-angle width of adjacent lobes between minima. Narrower slits spread light more widely; they do not sharpen the central peak.

Worked example: λ=650 nm, a=100 μm and L=1 m gives central width about 13.0003 mm.

Recorded primary quantity: `centralWidth` (m).

Independent control bounds (dependent validity clamps may narrow them):

- Vacuum wavelength (`wavelength`): 3.8e-7 to 7.5e-7 m; documented default 6.5e-7.
- Slit width (`aperture`): 0.00002 to 0.00015 m; documented default 0.0001.
- Slit-to-screen distance (`screen`): 0.5 to 3.0 m; documented default 1.0.
- Detector y (`probe`): -0.03 to 0.03 m; documented default 0.0.
