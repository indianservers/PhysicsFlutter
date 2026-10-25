# Phase 7 lab specifications

Generated from the same curriculum and control definitions used by the app. SI units internally. All plots use calculated data. Model fluid-modern-7.0.

## s14-e00 — Density & Pressure

Glass vessel, free-surface datum, depth probe and an independent mass/volume specimen.

Pressure rises with vertical depth in a stationary approximately incompressible liquid under uniform gravity. Gauge pressure compares absolute pressure with the chosen reference. A separate object density is calculated from measured mass and volume.

Equation: `\rho_o=m/V,\quad p=p_s+\rho gh,\quad p_g=p-p_{ref}`

m kg; V m³; h vertical depth m; p Pa; ρ kg/m³; g=9.80665 m/s². p_reference is independently stated.

Depth0…0.8 m. Model liquid density600…1400 kg/m³ is an illustrative fixed-reference-temperature input, not a claim that density is independent of temperature or an exact water table. No waves, acceleration, compressibility or thermal expansion. Free surface is held fixed by a large/overflow reservoir.

Reference example: ρ=1000 kg/m³ and h=.30 m give 2941.995 Pa above surface pressure, not 24.3 kPa.

Primary observation: gaugePressure (Pa).

Modes: Model liquid / pressure probe.

Supported controls (only model-relevant controls are exposed):

- Model liquid density at fixed reference temperature (`density`): 600.0…1400.0 kg/m³; default 1000.0.
- Depth below free surface (`depth`): 0.0…0.8 m; default 0.3.
- Absolute surface pressure (`surfacePressure`): 95000.0…110000.0 Pa; default 101325.0.
- Gauge reference pressure (`referencePressure`): 95000.0…110000.0 Pa; default 101325.0.
- Specimen mass (`objectMass`): 0.02…1.0 kg; default 0.2.
- Specimen volume (`objectVolume`): 0.0001…0.001 m³; default 0.0002.


## s14-e01 — Hydrostatics

Connected unequal-area vessels with a U-shaped base passage, pressure ports and an explicit z=0 datum.

Hydrostatic pressure balance and conserved base-liquid volume determine both levels. In the two-fluid mode a fixed lighter layer occupies only the left branch, with a physical interface.

Equation: `\Delta p=\rho g(z_R-z_L),\quad A_Lz_L+A_Rz_R=V_{base}`

Δp=p_left−p_right Pa, relative to a common atmospheric reference. Heights m above the marked datum; areas m²; volumes m³.

Constant cylindrical branch areas; base volume=(AL+AR)h0. Upper-layer thickness=Voil/AL. Pressure balance Δp+ρoil gH+ρbase gzinterface=ρbase gzright. Require lighter upper liquid, interface and right level≥.03 m, all tops≤.55 m. Overflow, empty branches, unstable stratification and capillarity are rejected/omitted.

Reference example: Equal areas .02 m², h0=.3 m, ρ=1000 and Δp=980.665 Pa give zL=.25 m and zR=.35 m; total branch volume stays .012 m³.

Primary observation: heightDifference (m).

Modes: One connected liquid, Lighter upper layer.

Supported controls (only model-relevant controls are exposed):

- Model liquid density at fixed reference temperature (`density`): 600.0…1400.0 kg/m³; default 1000.0.
- Lighter layer model density (`layerDensity`): 600.0…1200.0 kg/m³; default 850.0.
- Left branch area (`areaLeft`): 0.01…0.04 m²; default 0.02.
- Right branch area (`areaRight`): 0.005…0.04 m²; default 0.02.
- Equal-pressure base-liquid reference level (`initialLevel`): 0.15…0.4 m; default 0.3.
- Conserved upper-layer volume (`oilVolume`): 0.0002…0.001 m³; default 0.0006.
- Applied left minus right pressure (`deltaPressure`): -1500.0…1500.0 Pa; default 980.665.


## s14-e02 — Buoyancy

Rectangular block in a transparent overflow-reservoir tank, actual immersed geometry and force vectors.

Archimedes force depends on the submerged volume. A floating uniform block displaces its own weight; a fully immersed denser object has a downward free resultant.

Equation: `F_b=\rho_fgV_{sub},\quad W=\rho_oVg,\quad f_{float}=\rho_o/\rho_f`

Depth below surface m, positive down; forces N; free resultant is positive up. Support is signed upward. Regime0 float,1 neutral,2 denser/sinks.

Uniform rectangular prism; Vdisplaced=width×length×clamp(bottom-depth,0,height). Tank surface fixed by overflow reservoir, depth .22 m. Equilibrium shows floating, fully submerged neutral, or bottom-supported sinking end state. Held-position mode reports required external support. No arbitrary dynamic rise/sink easing or drag is simulated.

Reference example: A 700 kg/m³ block floats in a 1000 kg/m³ model liquid with 70% of its height submerged.

Primary observation: buoyantForce (N).

Modes: Static equilibrium, Position held externally.

Supported controls (only model-relevant controls are exposed):

- Model liquid density at fixed reference temperature (`density`): 600.0…1400.0 kg/m³; default 1000.0.
- Uniform object density (`objectDensity`): 200.0…2500.0 kg/m³; default 700.0.
- Block width (`width`): 0.04…0.12 m; default 0.08.
- Block length (`length`): 0.04…0.12 m; default 0.06.
- Block height (`height`): 0.06…0.16 m; default 0.12.
- Held bottom depth below free surface (`bottomDepth`): -0.02…0.22 m; default 0.09.


## s14-e03 — Continuity

Transparent circular constriction, cross-section probe and 24 passive flow markers.

A steady incompressible volume flux has average speed Q/A. The same radius function defines both the rendered pipe and the scientific area.

Equation: `Q=A(x)\bar v(x),\quad A(x)=\pi r(x)^2`

Q m³/s; r m; average speed m/s; x m. Flow is left to right.

Smooth cosine radius profile over x=−.12….12 m, circular A=πr². Positive steady flow, no pump/pressure calculation in this lab. Markers advect by inverse cumulative ∫A ds (2048 trapezoid intervals), so local axial speed is Q/A. Markers represent transported volume, not molecules or a resolved viscous velocity field. No bubbles or turbulent noise.

Reference example: Q=2e−5 m³/s gives .0282942 m/s at r=.015 m and .0994718 m/s at r=.008 m.

Primary observation: speed (m/s).

Modes: Steady incompressible flow.

Supported controls (only model-relevant controls are exposed):

- Inlet / outlet radius (`radius1`): 0.005…0.03 m; default 0.015.
- Throat radius (`radius2`): 0.003…0.03 m; default 0.008.
- Volume flow rate (`flow`): 0.000002…0.0005 m³/s; default 0.00002.
- Axial probe position (`probeX`): -0.12…0.12 m; default 0.0.


## s14-e04 — Bernoulli

Glass Venturi with two open same-liquid piezometers, axial probe and calculated pressure/speed profiles.

Continuity and Bernoulli jointly determine velocity and pressure along the ideal streamline. Open pressure columns rise to the calculated gauge head.

Equation: `p+\tfrac12\rho v^2+\rho gz=C,\quad Q=Av,\quad h_{column}=(p-p_{atm})/(\rho g)`

Absolute p Pa; density kg/m³; z m positive up; specific energy per volume Pa; atmosphere101325 Pa. Capillarity is neglected in the ideal piezometers.

Steady incompressible inviscid model, no pump/turbine/loss between stations. Positive model vapour-pressure margin required. Open piezometers require gauge head≥0 and top≤.14 m; unsupported suction/overflow is explained. The adjustable vapour pressure is a model input at fixed reference temperature, not a temperature-independent material table. Probe and taps use the same elevation/radius functions.

Reference example: In a horizontal constriction, p2−p1=½ρ(v1²−v2²). Each head and pressure is calculated, not independently editable.

Primary observation: pressure (Pa).

Modes: Ideal Venturi / open piezometers.

Supported controls (only model-relevant controls are exposed):

- Inlet / outlet radius (`radius1`): 0.005…0.03 m; default 0.015.
- Throat radius (`radius2`): 0.003…0.03 m; default 0.008.
- Volume flow rate (`flow`): 0.000002…0.0005 m³/s; default 0.00002.
- Axial probe position (`probeX`): -0.12…0.12 m; default 0.0.
- Model liquid density at fixed reference temperature (`density`): 600.0…1400.0 kg/m³; default 1000.0.
- Inlet absolute pressure (`inletPressure`): 101325.0…102600.0 Pa; default 101825.0.
- Throat elevation above inlet (`elevation`): -0.05…0.05 m; default 0.0.
- Model liquid vapour pressure at reference temperature (`vapourPressure`): 0.0…10000.0 Pa; default 2340.0.


## s14-e05 — Viscosity

Large-vessel falling-sphere viscometer, release mark, calibrated travel interval and metal sphere.

Weight minus buoyancy accelerates the sphere; linear Stokes drag approaches the terminal speed with an analytic exponential response.

Equation: `F_D=6\pi\mu rv,\quad v_t=2r^2(\rho_s-\rho_f)g/(9\mu),\quad Re=2\rho_fr|v|/\mu`

μ Pa·s; r m; speed m/s; τ=m/(6πμr) s; displacement m positive down. Initial speed0.

r≤1 mm in a 50 mm-radius vessel (r/R≤.02), travel≤.2 m. Large-vessel approximation; wall/end corrections and added mass/history effects are omitted. Finite walls can still cause a few-percent correction. μ is an editable illustrative dynamic viscosity at fixed reference temperature; no temperature law. Require sphere density above liquid and terminal Re≤.1; invalid Stokes regimes are rejected. Arrival time is solved by bracketed bisection; playback explicitly accelerates long travel times.

Reference example: r=.5 mm, ρs=2500, ρf=1000 kg/m³, μ=1 Pa·s: vt=.000817221 m/s and terminal Re=.000817221.

Primary observation: terminalSpeed (m/s).

Modes: Low-Re falling sphere.

Supported controls (only model-relevant controls are exposed):

- Sphere radius (`radius`): 0.00005…0.001 m; default 0.0005.
- Sphere density (`sphereDensity`): 800.0…8000.0 kg/m³; default 2500.0.
- Model liquid density at fixed reference temperature (`density`): 600.0…1400.0 kg/m³; default 1000.0.
- Model dynamic viscosity at fixed temperature (`viscosity`): 0.001…5.0 Pa·s; default 1.0.
- Calibrated travel distance (`travel`): 0.05…0.2 m; default 0.2.


## s15-e00 — Quantum Ideas

One-dimensional infinite-square-well model, distinct ψ and |ψ|² plots, energy ladder and simulated-position histogram.

A normalized stationary eigenstate has quantized energy and a time-independent position probability density. Individual seeded samples populate a histogram drawn from that density.

Equation: `E_n=n^2\pi^2\hbar^2/(2mL^2),\quad\psi_n=\sqrt{2/L}\sin(n\pi x/L)`

L,x m; m kg; E J (eV also displayed); ψ m⁻¹ᐟ²; density m⁻¹. Planck h exact6.62607015e−34 J s; ħ=h/(2π).

Infinite hard walls, one particle, n1…6, L .5…2 nm, mass1…100 electron masses. Spatial eigenfunction shown at a reference global phase; no superposition or moving density. Normalized 4096-interval trapezoid CDF with inverse interpolation; up to2000 samples and300 recent positions. Histogram density is count/(N bin-width), 40 bins. Sampling-grid approximation is convergence tested. The apparatus is a schematic/probability visualization, not an electron photograph.

Reference example: An electron in a 1 nm well has E1≈.37603 eV and E2≈1.50412 eV. The density remains stationary as detections accumulate.

Primary observation: energy (J).

Modes: Stationary well eigenstate.

Supported controls (only model-relevant controls are exposed):

- Well width (`wellWidth`): 5e-10…2e-9 m; default 1e-9.
- Particle mass (`mass`): 9.1093837139e-31…9.1093837139e-29 kg; default 9.1093837139e-31.
- Eigenstate n (`n`): 1.0…6.0 ; default 2.0.
- Reproducible simulation seed (`seed`): 1.0…2147483647.0 ; default 42.0.
- Simulated position detections per second (`eventRate`): 1.0…100.0 s⁻¹; default 40.0.


## s15-e01 — Photoelectric Effect

Monochromatic source, evacuated photocell, emitter/collector and signed bias supply.

Photon energy above the work function sets maximum kinetic energy and stopping potential. Intensity sets photon flux, not a way around the one-photon threshold.

Equation: `K_{max}=hf-\phi,\quad f_0=\phi/h,\quad V_s=K_{max}/e,\quad I_{sat}=e\eta IA/(hf)`

λ m; f Hz; irradiance W/m²; illuminated area m²; φ J; QE fraction; bias Vanode−Vcathode V. Positive bias accelerates electrons.

Ideal one-photon model. Work function is an explicitly adjustable model input, not a named-metal calibration. P=irradiance×area, emitted-electron rate=QE×P/(hf). Uniform longitudinal kinetic energies on [0,Kmax] define collection=max(0,min(1,1+eV/Kmax)); no detailed real photocathode curve claim. At exactly zero Kmax only positive extraction bias collects electrons. Below threshold current is zero. No secondary emission, space charge or multiphoton effects.

Reference example: At f=6e14 Hz and φ=2 eV, maximum kinetic energy≈.4814 eV and stopping potential≈.4814 V; 1.8 V is not implied by those inputs.

Primary observation: current (A).

Modes: Wavelength input, Frequency input.

Supported controls (only model-relevant controls are exposed):

- Incident vacuum wavelength (`wavelength`): 2e-7…8e-7 m; default 4e-7.
- Incident frequency (`frequency`): 375000000000000.0…1500000000000000.0 Hz; default 600000000000000.0.
- Incident irradiance (`intensity`): 0.0…100.0 W/m²; default 10.0.
- Illuminated area (`illuminatedArea`): 0.000001…0.001 m²; default 0.0001.
- Model work function (`workFunction`): 1.602176634e-19…8.01088317e-19 J; default 3.204353268e-19.
- Quantum efficiency (`quantumEfficiency`): 0.0…1.0 ; default 0.1.
- Collector minus emitter bias (`bias`): -5.0…5.0 V; default 0.0.


## s15-e02 — Matter Waves

Electron source, two-slit plate and transverse detector; probability curve and seeded accumulating detections.

The de Broglie wavelength and coherent far-field slit amplitudes determine the conditional distribution of detections within the visible screen window.

Equation: `\lambda=h/p,\quad p=\sqrt{2m_e eV},\quad P(y)\propto\operatorname{sinc}^2(\pi ay/\lambda D)\cos^2(\pi dy/\lambda D)`

p kg m/s; V accelerating voltage V; λ,a,d,D,y m. me=9.1093837139e−31 kg, e exact1.602176634e−19 C.

Nonrelativistic electron KE≤200 eV. Paraxial Fraunhofer finite-width identical slits: sinc²(πay/λD) cos²(πdy/λD). Require a≤d/2, window/D≤.05, d²/(λD)≤.01, and ≥4 histogram bins per fringe. Probability is normalized within the selected finite window, not an absolute source detection efficiency. 4096 grid intervals,160 bins,≤2000 samples/300 recent positions. No classical path through both slits or which-path model.

Reference example: 100 V electrons have λ≈.12264 nm. p=6e−25 kg m/s instead gives λ≈1.10435 nm.

Primary observation: wavelength (m).

Modes: Accelerating voltage, Momentum input.

Supported controls (only model-relevant controls are exposed):

- Electron accelerating voltage (`voltage`): 1.0…200.0 V; default 100.0.
- Incident electron momentum (`momentum`): 1e-25…8e-24 kg·m/s; default 6e-25.
- Each slit width (`slitWidth`): 1e-8…4e-8 m; default 2e-8.
- Slit centre separation (`separation`): 5e-8…2e-7 m; default 1e-7.
- Slit-to-screen distance (`screenDistance`): 0.1…1.0 m; default 0.3.
- Detector half-window (`window`): 0.0005…0.004 m; default 0.002.
- Reproducible simulation seed (`seed`): 1.0…2147483647.0 ; default 42.0.
- Simulated position detections per second (`eventRate`): 1.0…100.0 s⁻¹; default 40.0.


## s15-e03 — Atomic Spectra

Hydrogen discharge tube, spectroscope, discrete energy ladder and an explicitly schematic line spectrum.

Transitions between hydrogen energy levels emit or absorb a photon with the positive level-energy difference. Each series fixes the lower level.

Equation: `1/\lambda=R_H(1/n_l^2-1/n_u^2),\quad E_\gamma=hc/\lambda`

λ vacuum m; R_H=R∞/(1+me/mp) m⁻¹; energies J; emission downward, absorption upward. Photon energy remains positive in both modes.

Hydrogen only; Lyman lower1, Balmer lower2, Paschen lower3, upper≤8 and above lower. Reduced-proton-mass Bohr/Rydberg gross structure; vacuum wavelengths, no fine structure/Lamb shift or air correction. Line heights are schematic, RGB illustrative. Absorption assumes atoms prepared in the selected lower level; level populations are not calculated. UV/IR lines are labeled rather than assigned visible spectral output. No multi-electron-atom formula.

Reference example: Hydrogen n3→2: approximately656.47 nm vacuum, visible. Lyman limit≈91.18 nm; Paschen lines are infrared.

Primary observation: wavelength (m).

Modes: Lyman emission, Balmer emission, Paschen emission, Lyman absorption, Balmer absorption, Paschen absorption.

Supported controls (only model-relevant controls are exposed):

- Upper hydrogen level (`upper`): 2.0…8.0 ; default 4.0.


## s15-e04 — Nuclear Structure

Schematic proton/neutron model, nuclide notation, neutral-atom mass data and a discrete isotope comparison plot.

A=Z+N. Binding energy uses atomic masses consistently: Z neutral hydrogen masses plus N neutron masses minus the neutral isotope mass.

Equation: `A=Z+N,\quad B=[Zm_H+Nm_n-M_{atom}]c^2`

Z,N,A counts; nuclear charge Ze C; neutral mass kg and u; B J and MeV (conversion by exact e). Rotation is a camera control only.

Eight bounded isotope entries from NIST Atomic Weights and Isotopic Compositions; central masses only, uncertainty/covariance propagation omitted. B=[Z mH+N mn−Matom]c² includes negligible atomic-electron binding bookkeeping at this teaching precision. No natural-abundance mean substituted for isotope mass. No invented half-lives or stability labels. Geometry and nucleon locations are schematic and not to scale; graph contains only sourced points.

Reference example: Carbon-12 has Z=6,N=6 and exactly12 u by mass convention. Its binding energy is approximately92.16 MeV, about7.68 MeV/nucleon.

Primary observation: bindingPerNucleon (J).

Modes: H-2, He-3, He-4, C-12, C-13, Fe-54, Fe-56, Fe-58.

Supported controls (only model-relevant controls are exposed):

- Schematic camera rotation (`azimuth`): -3.141592653589793…3.141592653589793 rad; default 0.6.


## s15-e05 — Radioactivity

Simulated sealed parent source, detector and counter; expected population alongside an aggregate stochastic realization.

Each surviving parent has exponential decay probability. Detector efficiency thins simulated source decays; independent Poisson background adds detector events. Activity and detected count rate are distinct.

Equation: `N=N_0e^{-\lambda t},\quad\lambda=\ln2/T_{1/2},\quad A=\lambda N,\quad\mathbb E[R_{det}]=\eta A+b`

Time s internally; half-life y uses365.25×86400 s; activity Bq=s⁻¹; efficiency fraction; background counts/s. Counts/populations dimensionless.

Bounded Cs-137/Co-60 dataset: PTB representative rounded half-lives30.05/5.27 Julian years. Single parent, no daughter chain or energy-dependent detection. Aggregate exact beta-recursive binomial sampling (N≤1e9), independent seeded source/detection/background streams, Poisson PTRS for large means. No astronomical per-nucleus simulation. Background physical counts/s; duration0.1…5 half-lives is accelerated into20 playback seconds. Quantitative shielding and dose/safety inference are not offered.

Reference example: After one half-life the expected population is N0/2; a realization fluctuates. With η=0 and background=0 detected counts remain zero despite decays.

Primary observation: expectedActivity (Bq).

Modes: Cs-137, Co-60.

Supported controls (only model-relevant controls are exposed):

- Initial parent nuclei (`initialN`): 1000.0…1000000000.0 ; default 1000000.0.
- Reproducible simulation seed (`seed`): 1.0…2147483647.0 ; default 42.0.
- Detector efficiency (`efficiency`): 0.0…1.0 ; default 0.25.
- Independent background rate (`background`): 0.0…1.0 s⁻¹; default 0.00001.
- Physical duration in half-lives (`halfLifeCount`): 0.1…5.0 ; default 1.0.
