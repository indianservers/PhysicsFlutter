# Phase 8 lab specifications

Generated from the same curriculum and control definitions used by the app. SI units internally. Model plots use calculated data; the SPARC option retains observed points and uncertainties. Model astronomy-8.0.

## s16-e00 — Solar System Orbits

Sun and eight textured planets in the J2000 ecliptic frame.

Keplerian ellipses evolve through mean anomaly, with the Sun at a focus. These frozen sourced elements illustrate comparative planetary properties.

Equation: `M=E-e\sin E,\quad P=2\pi\sqrt{a^3/\mu_\odot}`

a m, μ m³/s², elapsed time s; orientation angles are J2000 ecliptic degrees. Epoch fixed, no calendar-date accuracy claim.

JPL Table1 elements frozen at JD2451545.0 TDB (J2000). ±200 Julian years educational evolution; not date-specific ephemerides. Earth marker is Earth–Moon barycentre. Body sizes exaggerated separately from physical or compressed distances. No interactions, perturbations or live sky.

Reference example: A circular 1 AU orbit has period about365.257 days under the nominal solar GM.

Primary observation: distance (m).

Modes: Mercury, Venus, Earth–Moon barycentre, Mars, Jupiter, Saturn, Uranus, Neptune.

Supported controls (only model-relevant controls are exposed):

- Elapsed Julian days from J2000 educational epoch (`elapsedDays`): -73050.0…73050.0 d; default 0.0.
- Distance scale:0 physical,1 compressed (`scaleMode`): 0.0…1.0 ; default 1.0.


## s16-e01 — Stellar Life

MIST reference star with H–R track, explicit evolutionary phase and age.

Initial mass changes evolution and main-sequence lifetime. The reference data set, not an arbitrary image morph, determines luminosity and effective temperature.

Equation: `L=4\pi R^2\sigma T_{eff}^4`

L W, radius m, effective temperature K, age s. Fraction maps linearly to actual track age; playback20s spans the supported lifetime.

Exactly1,3,15 solar-mass MIST1.2 tracks, MESA7503, [Fe/H]=0, Zinit0.0142857, Yinit0.2703, nonrotating. Interpolate age/logL/logT only within one phase; step at phase boundaries. No mass interpolation, binary evolution or prediction of an exact remnant mass.

Reference example: Select stage chips to reach short-lived phases without inventing their durations.1/3 M☉ tracks reach post-AGB;15 M☉ ends before collapse.

Primary observation: luminosity (W).

Modes: MIST 1 M☉, MIST 3 M☉, MIST 15 M☉.

Supported controls (only model-relevant controls are exposed):

- Fraction of supported reference-track age (`ageFraction`): 0.0…1.0 ; default 0.4.


## s16-e02 — Spectroscopy

Original telescope and grating spectrograph; synthetic normalized spectrum.

A Planck Bλ continuum and a clearly illustrative Balmer absorption template describe different aspects of an educational spectrum. Positive radial velocity means receding.

Equation: `B_\lambda={2hc^2\over\lambda^5(e^{hc/(\lambda kT)}-1)},\quad\lambda_o=\lambda_r\sqrt{{1+\beta\over1-\beta}}`

Wavelength m vacuum; Bλ W m⁻³ sr⁻¹ before unit-peak normalization. Wien b=2.897771955e−3 m K is for Bλ, not Bν. Resolution R=λ/FWHM.

Generated model, not observed Vega or a complete stellar atmosphere. Balmer wavelengths reuse the hydrogen vacuum dataset. Fixed illustrative line depths/intrinsic Gaussian width0.12nm; no composition inference. Gaussian instrumental FWHM=λ/R broadens and shallows actual lines. Relativistic longitudinal Doppler with |v|≤0.02c.

Reference example: At5800K, the Bλ maximum is about500nm. Hα rest vacuum wavelength≈656.47nm.

Primary observation: peakWavelength (m).

Modes: Synthetic Balmer absorption, Blackbody continuum only.

Supported controls (only model-relevant controls are exposed):

- Effective temperature (`temperature`): 3000.0…20000.0 K; default 5800.0.
- Radial velocity: positive receding (`velocity`): -5995849.0…5995849.0 m/s; default 0.0.
- Resolving power λ/FWHM (`resolution`): 500.0…10000.0 ; default 2000.0.
- Wavelength cursor (`wavelength`): 3.5e-7…8e-7 m; default 6.5647e-7.


## s16-e03 — Galaxies

Labeled schematic spiral galaxy and independent radial mass-model probe.

Circular speed follows R∂Φ/∂R in the defined axisymmetric potential. A disk must not be treated as a spherical enclosed mass.

Equation: `v_c^2=R{\partial\Phi\over\partial R},\quad \Phi_d=-{GM_d\over\sqrt{R^2+(a+b)^2}}`

Radius m; speed m/s; masses kg. kpc and M☉ controls convert centrally to SI. Halo speed is a potential parameter, not an observed constant curve.

Hernquist spherical bulge scale0.6kpc; exact equatorial Miyamoto–Nagai disk with vertical scale0.3kpc; optional logarithmic spherical halo core4kpc. Adjustable parameters are illustrative, not fitted measurements of a named galaxy. SPARC NGC2403 observations/uncertainties are a separately labeled comparison only.

Reference example: The disk contribution tends to Keplerian falloff outside its scale. Adding a halo can sustain larger outer speeds.

Primary observation: speed (m/s).

Modes: Bulge + disk + halo, Bulge + disk only.

Supported controls (only model-relevant controls are exposed):

- Radius probe (`radiusKpc`): 0.1…30.0 kpc; default 8.0.
- Bulge mass (`bulgeMass`): 0.0…20000000000.0 M☉; default 1000000000.0.
- Disk mass (`diskMass`): 1000000000.0…100000000000.0 M☉; default 40000000000.0.
- Disk radial scale (`diskScale`): 1.0…8.0 kpc; default 3.0.
- Log-halo asymptotic speed parameter (`haloSpeed`): 0.0…250000.0 m/s; default 130000.0.


## s16-e04 — Cosmology

Schematic comoving grid with an expanding scale factor, no preferred origin.

Flat FLRW distances come from integrating the expansion history. Redshift, light-travel distance, comoving distance and recession conventions differ.

Equation: `E(z)^2=\Omega_r(1+z)^4+\Omega_m(1+z)^3+\Omega_\Lambda,\quad D_C={c\over H_0}\int_0^z{dz\over E(z)}`

H0 input km/s/Mpc; H SI s⁻¹. DL=(1+z)DC, DA=DC/(1+z), a=1/(1+z); lookback s; present recession convention H0DC may exceed c.

Flat ΛCDM only; ΩΛ=1−Ωm−Ωr; fixed illustrative Ωr=0.00009 including effective radiation today. z≤5; no varying neutrino masses, curvature, dark-energy equation-of-state or early-universe accuracy claim. Simpson integration1024 even intervals, tested against refinement and reference cases. User parameters are hypothetical.

Reference example: As z→0, DC≈cz/H0 and lookback≈z/H0. Plot physical distance units separately from time.

Primary observation: comovingDistance (m).

Modes: Flat ΛCDM.

Supported controls (only model-relevant controls are exposed):

- Cosmological redshift (`redshift`): 0.0…5.0 ; default 0.5.
- Hubble constant parameter (`h0`): 50.0…90.0 km/s/Mpc; default 70.0.
- Matter density parameter (`omegaMatter`): 0.1…0.5 ; default 0.3.


## s16-e05 — Exoplanets

Uniform stellar disk, opaque foreground planet and exact synchronized transit light curve.

Projected circular-orbit geometry determines circle overlap and fractional flux. Kepler fixes semi-major axis from the chosen stellar mass and period.

Equation: `F/F_0=1-{A_{overlap}\over\pi R_s^2},\quad a^3={GM_sP^2\over4\pi^2}`

Rs solar radii, Ms solar masses convert to SI; Rp/Rs dimensionless; period input days. Impact b=(a/Rs)cos i. Duration is first-to-fourth contact.

Synthetic unnamed system, circular orbit, zero planet mass, uniform star, no limb darkening/stellar spots/eccentricity. Inclination80…90°; exact overlap for full, partial and grazing transits. P1…30days. Time0 is inferior conjunction. Saved-seed independent Gaussian noise is optional synthetic detector noise, not an observation.

Reference example: At full overlap with Rp/Rs=.1, depth=.01; a grazing transit has less depth and shorter duration.

Primary observation: midDepth ().

Modes: Synthetic circular system.

Supported controls (only model-relevant controls are exposed):

- Stellar mass (`starMass`): 0.5…2.0 M☉; default 1.0.
- Stellar radius (`starRadius`): 0.5…2.0 R☉; default 1.0.
- Planet/star radius ratio (`radiusRatio`): 0.01…0.2 ; default 0.1.
- Orbital period (`periodDays`): 1.0…30.0 d; default 5.0.
- Orbital inclination (`inclination`): 80.0…90.0 °; default 89.0.
- Time cursor in orbital-period fractions (`phase`): -0.04…0.04 ; default 0.0.
- Synthetic Gaussian flux noise σ (`noise`): 0.0…0.002 ; default 0.0.
- Synthetic noise seed (`seed`): 1.0…2147483647.0 ; default 42.0.
