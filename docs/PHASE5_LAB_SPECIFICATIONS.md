# Phase 5 per-lab scientific specification

Generated from the shipped curriculum by `dart run tool/phase5_evidence.dart`. Model `electromagnetism-5.0`. Companion [science and references](PHASE5_SCIENCE.md). Every stored physical input uses the listed SI unit.

## 1. Coulomb Force

Stable ID `s10-e00`.

Two charged conducting-sphere representations on insulating stands, centre-distance rule and equal/opposite force overlays.

Principle: Signed Coulomb forces act along the line joining point sources. Opposite charges attract, equal signs repel, and either zero charge gives zero force. The rendered metal spheres are small apparatus representations; mutual conducting-sphere polarization is not solved.

Equation: `\vec F_2=kq_1q_2\vec r/r^3,\quad \vec F_1=-\vec F_2`

Units and convention: q C; r centre-to-centre m; k=1/(4πε₀) N·m²/C²; +x right. Force on 2 is signed along +x; magnitude is nonnegative.

Assumptions, method and limitations: Point-charge exterior approximation. Centres 0.08–0.8 m apart; apparent sphere radius 0.0125 m. No contact, charge transfer or finite-conductor polarization. Static solution; no arbitrary Run animation. 101-point analytic sweeps.

Investigation: Explore charge sign, zero charge and centre separation. Compare the signed distance curve with the charge sweep. Double the separation and predict the factor-of-four change; compare the equal/opposite vectors.

Misconception: Equal/opposite forces have the same magnitude even when the charges differ. Sign gives direction, not a negative magnitude.

Worked example: q₁=+2 μC, q₂=−2 μC, r=.20 m: F₂x=−.898755 N, attraction.

Recorded primary quantity `force`, unit N.

Supported control bounds (dependent geometry validity still applies):

- Signed charge 1 (`q1`): -0.000005…0.000005 C; default 0.000002.
- Signed charge 2 (`q2`): -0.000005…0.000005 C; default -0.000002.
- Centre-to-centre separation (`distance`): 0.08…0.8 m; default 0.2.

## 2. Electric Field

Stable ID `s10-e01`.

One to three signed source spheres, bounded vector-field board, field-line traces and an independent test-charge probe.

Principle: Electric field is the vector sum of point-source contributions. A positive test charge follows E; a negative one feels the opposite force. Changing the test charge does not change the source field.

Equation: `\vec E=\sum_i kq_i(\vec r-\vec r_i)/|\vec r-\vec r_i|^3,\quad\vec F=q_t\vec E`

Units and convention: Positions m in xy plane; E N/C; test qₜ C; +x right, +y up, +z out of board. Vector glyphs are normalized directions; readouts retain true magnitude.

Assumptions, method and limitations: Static 3-D point-charge field sampled in z=0 plane. Every source has a .03 m excluded radius; source centres must be ≥.06 m apart. Invalid probes produce no readout. 15×11 vector grid, 12 seeds per nonzero positive source (negative seeds reversed if none positive), RK4 direction tracing ≤400 steps at .004 m; line count is qualitative, not a charge-flux scale.

Investigation: Explore one, two and three charges. Move source coordinates and probe; test equal like-charge cancellation and a dipole midpoint. Reverse the test charge while holding sources fixed. Compare components and force.

Misconception: E is a property of sources and location, independent of the selected test charge. Traces are a representation, not physical strings.

Worked example: Equal +5 nC sources at x=±.12 m give E=0 at their midpoint. Equal/opposite sources instead reinforce there.

Recorded primary quantity `field`, unit N/C.

Supported control bounds (dependent geometry validity still applies):

- Number of source charges (`count`): 1.0…3.0 ; default 2.0.
- Charge 1 (`q1`): -1e-8…1e-8 C; default 5e-9.
- Source 1 x (`x1`): -0.3…0.3 m; default -0.12.
- Source 1 y (`y1`): -0.24…0.24 m; default 0.0.
- Charge 2 (`q2`): -1e-8…1e-8 C; default -5e-9.
- Source 2 x (`x2`): -0.3…0.3 m; default 0.12.
- Source 2 y (`y2`): -0.24…0.24 m; default 0.0.
- Charge 3 (`q3`): -1e-8…1e-8 C; default 0.0.
- Source 3 x (`x3`): -0.3…0.3 m; default 0.0.
- Source 3 y (`y3`): -0.24…0.24 m; default -0.18.
- Probe x (`probeX`): -0.4…0.4 m; default 0.18.
- Probe y (`probeY`): -0.28…0.28 m; default 0.12.
- Test charge (does not change E) (`testCharge`): -5e-9…5e-9 C; default 1e-9.

## 3. Electric Potential

Stable ID `s10-e02`.

Signed source spheres, equipotential contour board, potential probe and an independently selected test charge.

Principle: Potential is a scalar sum with zero at infinity. Potential energy is qₜV. Sampled equipotential contours are orthogonal to the electric field within interpolation accuracy; field is minus the spatial potential gradient.

Equation: `V=\sum_i kq_i/r_i,\quad U=q_tV,\quad\vec E=-\nabla V`

Units and convention: V volts relative to infinity, U joules, E N/C, q C, r m. Horizontal path uses current probe y.

Assumptions, method and limitations: Same .03 m exclusions and source separation as Electric Field. Marching triangles on a bounded 36×24 grid; contour levels −1000,−500,−200,−100,0,100,200,500,1000 V. Contours near source holes are omitted. Curve has 161 samples, leaving invalid samples blank. No arbitrary softening or finite-conductor boundary solution.

Investigation: Use the same editable sources as Electric Field. Move the probe/path height. Compare V and E along the horizontal selected path. Find a dipole midpoint with zero V and nonzero E. Reverse test charge to change U while V stays fixed.

Misconception: Zero scalar potential does not imply zero electric field. Electric-field work for moving q from a to b is q(Va−Vb), the negative change of U.

Worked example: A single +5 nC source at .15 m gives 299.585 V; +5 μC would give 299585 V, not the mockup’s 180 V.

Recorded primary quantity `potential`, unit V.

Supported control bounds (dependent geometry validity still applies):

- Number of source charges (`count`): 1.0…3.0 ; default 2.0.
- Charge 1 (`q1`): -1e-8…1e-8 C; default 5e-9.
- Source 1 x (`x1`): -0.3…0.3 m; default -0.12.
- Source 1 y (`y1`): -0.24…0.24 m; default 0.0.
- Charge 2 (`q2`): -1e-8…1e-8 C; default -5e-9.
- Source 2 x (`x2`): -0.3…0.3 m; default 0.12.
- Source 2 y (`y2`): -0.24…0.24 m; default 0.0.
- Charge 3 (`q3`): -1e-8…1e-8 C; default 0.0.
- Source 3 x (`x3`): -0.3…0.3 m; default 0.0.
- Source 3 y (`y3`): -0.24…0.24 m; default -0.18.
- Probe x (`probeX`): -0.4…0.4 m; default 0.18.
- Probe y (`probeY`): -0.28…0.28 m; default 0.12.
- Test charge (does not change E) (`testCharge`): -5e-9…5e-9 C; default 1e-9.

## 4. Current

Stable ID `s10-e03`.

Closed battery–resistor loop with switch, series ammeter and enlarged copper-conductor drift inset.

Principle: For a closed ideal ohmic loop I=V/R, transferred signed charge Q=It and power VI. Opening the switch gives zero steady conduction current. Conventional current and electron drift in the metal have opposite directions.

Equation: `I=V/R,\quad Q=It,\quad P=VI,\quad v_{electron}=-I/(neA)`

Units and convention: V volts, R ohms, I A, Q C, P W, n carriers/m³, area m², drift m/s. Positive current leaves the positive source terminal through the resistor.

Assumptions, method and limitations: Lumped steady DC, ideal source/wires/meters and constant R; no signal-propagation transient. Constant carrier density/area define vd=−I/(neA). Marker size/count are illustrative; displayed drift uses a fixed ×10000 displacement scale, not signal speed. Changes restart Q and time at zero. 120 Hz shared clock, history≤301.

Investigation: Explore supply polarity and resistance; open/close the switch. Step/run to accumulate charge. Inspect ammeter, power and drift speed. Predict I before recording; compare the I–V sweep at fixed R.

Misconception: Electrons do not race around the loop at signal-propagation speed. An open switch carries no sustained conduction current in this model.

Worked example: V=6 V, R=15 Ω gives .4 A and 2.4 W. After 2 s the signed charge is .8 C.

Recorded primary quantity `current`, unit A.

Supported control bounds (dependent geometry validity still applies):

- Supply voltage (`voltage`): -12.0…12.0 V; default 6.0.
- Resistance (`resistance`): 1.0…100.0 Ω; default 15.0.
- Switch closed (1) / open (0) (`closed`): 0.0…1.0 ; default 1.0.
- Conductor cross-sectional area (`area`): 5e-7…0.000005 m²; default 0.000001.
- Carrier density (copper teaching value) (`density`): 5e+28…1e+29 m⁻³; default 8.5e+28.

## 5. Circuits

Stable ID `s10-e04`.

Editable terminal-based DC workbench: source, resistors, switches, wires, ideal ammeter/voltmeter and explicitly ohmic lamp.

Principle: A genuine graph is solved with modified nodal analysis. Wires merge nodes, positive resistors stamp conductance, ideal voltage sources/closed switches/ammeters add current unknowns, and ideal voltmeters draw no current. Source negative terminal is the reference.

Equation: `G\vec V+B\vec I=\vec 0,\quad B^T\vec V=\vec V_s,\quad\sum I_{node}=0,\quad\sum P=0`

Units and convention: Component terminals a→b define passive voltage/current signs. Source a is +. Node voltages V; branch currents A; absorbed powers W. Negative source power is delivered power.

Assumptions, method and limitations: 1–12 parts, ≤24 wires, ideal DC only, R/lamp .1–10000 Ω, sources ±24 V. Partial-pivot Gaussian elimination tolerance 1e−12. Floating/disconnected nodes, shorts, singular/redundant or inconsistent ideal constraints return explanatory invalid states with no fabricated meter values. Lamp is a linear resistor; brightness=P/(P+.5 W), illustrative. Canvas movement changes layout only, wires change topology. Sweeps use 26 actual graph solves.

Investigation: Load series, parallel and mixed examples. Add/move parts, select two terminals and connect, delete a wire or component, edit component values and toggle switches. Insert ammeters in series and voltmeters across nodes. Inspect all branch currents/node voltages, KCL and power balance. Build a target-current network.

Misconception: An ideal ammeter connected across a source is an ideal short, not a plausible normal reading. An ideal voltmeter supplies no conductive path.

Worked example: 6 V across 10 Ω+20 Ω in series gives .2 A; parallel gives .9 A. A 5 Ω series resistor added to that parallel combination gives 6/(5+20/3)=.514286 A.

Recorded primary quantity `current`, unit A.

Supported control bounds (dependent geometry validity still applies):

- Real graph editor: 1–12 components, ≤24 wires; terminal topology and per-component values saved. Resistors/lamps .1–10000 Ω; ideal sources −24…24 V; ideal series ammeters/across-node voltmeters/switches.

## 6. Capacitors

Stable ID `s10-e05`.

Parallel plates with dielectric and supply isolation; separate finite-resistance RC charging/discharging apparatus.

Principle: Geometry mode uses C=ε₀εrA/d. Connected voltage is fixed; isolated charge is held when geometry changes, so V and energy can change through mechanical work. RC modes use exact exponential solutions and continuous voltage at charge/discharge switching.

Equation: `C=\epsilon_0\epsilon_r A/d,\ Q=CV,\ U=Q^2/(2C),\ V_C=V_s+(V_0-V_s)e^{-t/(RC)}`

Units and convention: C F; A m²; d m; εr dimensionless; Q C; U J; τ=RC s. Charging current positive into the positive capacitor plate; discharging current is negative.

Assumptions, method and limitations: Square uniform plates, gap≤.05√A, no fringing/leakage/breakdown; linear εr. Isolated Q captured when disconnecting and stored in the session. RC is separate chosen C, finite R, no inductance. Switching RC modes takes the last capacitor voltage as the new initial value. Analytic 101-point profiles; five τ maximum with one τ per display second.

Investigation: Compare connected and isolated geometry while changing area/gap/permittivity. Switch to RC charge/discharge, choose R,C and initial V, step/run through five time constants, and inspect voltage/current curves and actual time history.

Misconception: Isolated means constant charge, not constant energy. Finite-R charging cannot make capacitor voltage jump instantaneously.

Worked example: Air, A=.005 m², d=.001 m gives C=44.2709 pF. RC: R=10 kΩ,C=100 μF gives τ=1 s; a 6 V zero-initial charge reaches 3.79272 V at τ.

Recorded primary quantity `capacitance`, unit F.

Supported control bounds (dependent geometry validity still applies):

- Plate area (`area`): 0.002…0.02 m²; default 0.005.
- Plate separation (`gap`): 0.0002…0.002 m; default 0.001.
- Relative permittivity (`epsilonR`): 1.0…5.0 ; default 1.0.
- Supply voltage (`voltage`): 0.0…12.0 V; default 6.0.
- RC resistance (`resistance`): 100.0…100000.0 Ω; default 10000.0.
- RC capacitance (`capacitance`): 0.000001…0.001 F; default 0.0001.
- RC initial capacitor voltage (`initialV`): 0.0…12.0 V; default 0.0.

## 7. Field Lines

Stable ID `s11-e00`.

N/S bar-magnet representation and ideal compass on an exterior-field board.

Principle: The 3-D dipole formula is sampled in the xy plane with magnetic moment along x. Compass north points along local B. Only exterior line segments are calculated; the complete magnetic lines close through the excluded source region, not at monopoles.

Equation: `\vec B=\mu_0[3(\vec m\cdot\hat r)\hat r-\vec m]/(4\pi r^3)`

Units and convention: Moment A·m², B T, r m. +x is magnet moment direction for positive moment, north at right; compass angle radians from +x.

Assumptions, method and limitations: Ideal dipole approximates only exterior distances r≥.08 m, outside the rendered .08 m-long magnet and a conservative near-field sphere. No interior/near-field bar-magnet solution. Qualitative line seeds, bounded RK4 tracing ≤600 steps. Instant ideal compass alignment; no Earth/background field or compass dynamics.

Investigation: Move the compass/probe around the magnet; reverse the signed moment. Compare axial/equatorial field and inverse-cube radial curve. Predict B at the probe. Inspect direction arrows and the explicit source exclusion region.

Misconception: Magnetic field lines do not begin or end at monopoles. A compass orientation is undefined when the net field is zero.

Worked example: For m=.15 A·m² at axial r=.10 m, B≈30 μT. At the equator the magnitude is half and direction reverses.

Recorded primary quantity `field`, unit T.

Supported control bounds (dependent geometry validity still applies):

- Signed magnetic moment (`moment`): -0.3…0.3 A·m²; default 0.15.
- Probe x (`probeX`): -0.4…0.4 m; default 0.18.
- Probe y (`probeY`): -0.28…0.28 m; default 0.12.

## 8. Lorentz Force

Stable ID `s11-e01`.

Uniform-field particle chamber with a rotatable 3-D projected trajectory, instantaneous velocity/force vectors and numerical values.

Principle: Nonrelativistic magnetic Lorentz force is q(v×B), with B along signed z. A perpendicular component forms a circle and a parallel component makes a helix. Magnetic force does no work; the Boris rotation preserves speed to roundoff.

Equation: `\vec F=q\vec v\times\vec B,\quad r=mv_\perp/(|q|B),\quad T=2\pi m/(|q|B)`

Units and convention: q C; mass kg; v m/s; B T along z; force N; time s. Right-handed xyz, positive charge with +vx and +Bz feels −Fy.

Assumptions, method and limitations: B-only, uniform field, no electric field/radiation/collisions; initial speed<3e6 m/s. Shared 120 Hz wall clock at 10⁻⁶ physical seconds per display second. Boris rotation uses substeps with |qB|h/m≤.03; trapezoidal position. Trails≤601 points, history≤301, physical maximum20 μs. Camera auto-fit and particle size are explicitly display-scaled.

Investigation: Reverse charge or field and inspect bending. Set parallel velocity to zero for a circle or perpendicular velocity to zero for straight motion. Step/run and compare speed/energy. Change the view azimuth/elevation without changing physical state.

Misconception: A helical path needs a parallel velocity component. Perpendicular velocity alone gives a circle; magnetic force cannot increase kinetic energy.

Worked example: q=1.602176634e−19 C,m=1.6726e−27 kg,v⊥=1e5 m/s,B=.02 T: radius≈.0522 m and period≈3.28 μs.

Recorded primary quantity `force`, unit N.

Supported control bounds (dependent geometry validity still applies):

- Signed particle charge (`charge`): -3.2e-19…3.2e-19 C; default 1.602176634e-19.
- Particle mass (`mass`): 1e-27…1e-25 kg; default 1.6726e-27.
- Initial velocity x (`vx`): -2000000.0…2000000.0 m/s; default 100000.0.
- Initial velocity y (`vy`): -2000000.0…2000000.0 m/s; default 0.0.
- Initial velocity z (`vz`): -1000000.0…1000000.0 m/s; default 30000.0.
- Signed uniform Bz (`field`): -0.1…0.1 T; default 0.02.

## 9. Current-Carrying Wire

Stable ID `s11-e02`.

Straight copper wire viewed in cross-section, signed current marker, circular field directions and movable compass.

Principle: Outside an ideal infinite straight wire, magnetic field is tangent to circles with B=μ₀I/(2πr). Positive current points out of the xy board; the field is counterclockwise by the right-hand rule.

Equation: `\vec B=\mu_0 I(-y,x,0)/(2\pi(x^2+y^2))`

Units and convention: I A along +z for positive current; x,y,r m; B T. Compass north points along B.

Assumptions, method and limitations: Exterior infinite-wire approximation only, probe r≥.005 m; visible copper radius .005 m. No unsupported interior or finite-end field. Circle count is qualitative. Zero current has no defined compass direction. 101-point 1/r curve from .01 to .20 m.

Investigation: Move the probe, reverse current and compare the compass. Double radial distance and predict half the magnitude. Explain the dot/cross current marker and field arrow direction before recording.

Misconception: Magnetic field is tangent, not radial. Reversing current reverses direction while magnitude at fixed |I| stays unchanged.

Worked example: I=5 A at .03 m gives 33.3333 μT, not the reference’s 49.8 μT.

Recorded primary quantity `field`, unit T.

Supported control bounds (dependent geometry validity still applies):

- Signed current (+ out of board) (`current`): -10.0…10.0 A; default 5.0.
- Probe x (`probeX`): -0.4…0.4 m; default 0.18.
- Probe y (`probeY`): -0.28…0.28 m; default 0.12.

## 10. Solenoids

Stable ID `s11-e03`.

Air-core finite solenoid with copper turns, polarity/direction indicator and axial probe.

Principle: The finite thin-current-sheet solenoid axial field accounts for both coil ends. The long-solenoid reference μ₀NI/L is offered only when L/R≥10 and the probe is within the central half-length; it is not applied to arbitrary exterior points.

Equation: `B_x={\mu_0NI\over2L}\left[{x+L/2\over\sqrt{R^2+(x+L/2)^2}}-{x-L/2\over\sqrt{R^2+(x-L/2)^2}}\right]`

Units and convention: N turns, L/R/x m, I A, B T along x. Positive current is defined by right-hand-rule +x magnetic moment.

Assumptions, method and limitations: Air core only, finite uniformly distributed thin winding. Formula exact for this current-sheet idealization on the axis, not off-axis. Turns integer50–1000; drawing shows at most32 representative windings labeled N/displayed count. No arbitrary core material/saturation selector. 101 axial samples over±.6 m.

Investigation: Explore turns, length, radius, current sign and axial position. Compare the finite-axis plot with the long-coil reference in its supported regime. Shorten the coil and inspect the loss of uniformity near its ends.

Misconception: The long-solenoid interior approximation is not a field model everywhere. A short coil and its exterior require the finite expression.

Worked example: N=500,I=2 A,L=.10 m,R=.02 m: finite centre field≈11.6676 mT; long reference12.5664 mT is outside the strict L/R≥10 criterion.

Recorded primary quantity `field`, unit T.

Supported control bounds (dependent geometry validity still applies):

- Turns N (`turns`): 50.0…1000.0 ; default 500.0.
- Coil length (`length`): 0.05…0.5 m; default 0.1.
- Coil radius (`radius`): 0.005…0.04 m; default 0.02.
- Signed current (`current`): -3.0…3.0 A; default 2.0.
- Axial probe x (`probe`): -0.4…0.4 m; default 0.0.

## 11. Induction

Stable ID `s11-e04`.

Magnet-source representation moving coaxially through a copper receiver coil, terminals and open EMF/closed-current meter.

Principle: An explicitly defined finite current-loop source models the magnet’s excitation. Mutual flux is the Neumann loop integral over actual source/receiver geometry; differentiating it gives ε=−N(dΦ/dz)v. Distinct loop radii keep the source nonsingular as it passes through the coil plane.

Equation: `\Phi=I_sM(z),\quad\epsilon=-N{d\Phi\over dz}v,\quad I_{closed}=\epsilon/R`

Units and convention: Flux per receiver turn Wb; linkage NΦ Wb-turn; EMF V; z m; velocity m/s; m A·m²; radii m. Positive receiver normal +z and positive EMF is counterclockwise viewed from +z.

Assumptions, method and limitations: Ideal coaxial filament loops, source moment m=Isπa², not an exact real-bar-magnet near field. Receiver radius−source radius≥.01 m. Composite midpoint quadrature256 samples for flux and its analytic z derivative; 101 profile positions. Closed-current model ε/R neglects self-inductance, valid quasistatically. No I=ε fabrication. Position edits restart; constant-velocity run stops beyond .35 m or3 s.

Investigation: Move source position, reverse velocity or moment, and vary receiver turns/radius. Run through the coil; compare flux, signed EMF and actual time history. Stop motion for zero EMF. Compare open EMF with current through a defined closed resistance.

Misconception: Large centre-field variation cannot justify Bcentre×area. Reversing velocity or source polarity reverses EMF; stationary geometry gives none. Induced current requires a closed circuit.

Worked example: For positive source moment approaching from z<0 with positive velocity, flux increases and EMF is negative. At the symmetric centre dΦ/dz=0, then polarity reverses after passage.

Recorded primary quantity `emf`, unit V.

Supported control bounds (dependent geometry validity still applies):

- Signed magnetic moment (`moment`): -0.3…0.3 A·m²; default 0.15.
- Turns N (`turns`): 50.0…1000.0 ; default 500.0.
- Equivalent source-loop radius (`sourceRadius`): 0.005…0.025 m; default 0.015.
- Receiver coil radius (`radius`): 0.04…0.08 m; default 0.05.
- Initial axial source position (`initialZ`): -0.25…0.25 m; default -0.15.
- Signed source velocity (`velocity`): -0.2…0.2 m/s; default 0.12.
- Receiver closed (1) / open (0) (`closed`): 0.0…1.0 ; default 0.0.
- Receiver circuit resistance (`resistance`): 10.0…200.0 Ω; default 50.0.

## 12. Electromagnets

Stable ID `s11-e05`.

Copper-wound uniform core, defined air gap, stationary armature and load-weight comparison; air-core reference.

Principle: The simplified magnetic circuit has reluctance (l/μr+g)/(μ₀A), flux NI/reluctance and uniform gap B. Ideal single-gap attraction is B²A/(2μ₀), compared with the load’s actual mg as an estimate, not a certified rating.

Equation: `B={\mu_0NI\over l/\mu_r+g},\quad\Phi=BA,\quad F\simeq{B^2A\over2\mu_0},\quad W=mg`

Units and convention: N turns, I A, core path l m, gap g m, area A m², μr dimensionless, B T, flux Wb, force/load weight N. Reversing current reverses B but leaves B² force positive.

Assumptions, method and limitations: One uniform gap/cross section, no leakage/fringing, linear educational μr (not a material specification), no saturation/hysteresis. |B|≤.3 T required; unsupported values give an explanatory invalid state. Armature remains at the specified gap; no unsupported levitation/sticking animation. 101 gap samples leave invalid points blank.

Investigation: Explore current, turns, core path, area and gap. Compare the same geometry with air core. Double current within validity and predict four times force; enlarge the gap and compare field/force and estimated force-to-weight ratio.

Misconception: B²A/(2μ₀) is an ideal uniform-gap estimate, not a universal lifting formula or certified load rating. Real cores have nonlinear permeability and losses.

Worked example: N=400,I=.5 A,l=.15 m,μr=200,g=.003 m,A=.0005 m²: B≈.0670 T, ideal F≈.8936 N. A .05 kg load weighs .490333 N.

Recorded primary quantity `force`, unit N.

Supported control bounds (dependent geometry validity still applies):

- Turns N (`turns`): 100.0…1000.0 ; default 400.0.
- Signed coil current (`current`): -2.0…2.0 A; default 0.5.
- Core magnetic path length (`length`): 0.1…0.3 m; default 0.15.
- Single uniform air gap (`gap`): 0.001…0.02 m; default 0.003.
- Uniform core/gap area (`area`): 0.0001…0.001 m²; default 0.0005.
- Educational linear core μr (`muR`): 10.0…1000.0 ; default 200.0.
- Compared load mass (`load`): 0.01…1.0 kg; default 0.05.
