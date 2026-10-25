# Phase 6 lab specifications

Generated from the same curriculum and control definitions used by the app. SI units internally. All plots use calculated data. Model electronics-thermal-6.0.

## s12-e00 — Semiconductors

Silicon lattice and energy-band schematic; concentration and conductivity meter.

Charge neutrality and mass action determine both carrier populations. Doping redistributes carriers without giving the bulk a net charge.

Equation: `np=n_i^2,\quad n-p=N_D-N_A,\quad\sigma=e(n\mu_n+p\mu_p)`

n,p,ni,ND,NA m⁻³; σ S/m; e=1.602176634e−19 C. Fermi offset kBT ln(n/ni), joules.

Fully ionized, nondegenerate teaching silicon, 250–400 K and 0–1e21 m⁻³. ni(300 K)=1e16 m⁻³; Eg=1.12 eV constant. Mobilities 0.14 and 0.05 m²/(V s) at 300 K scale as (T/300)^−2.2. Excludes freeze-out, degeneracy and doping-dependent scattering. Bands are schematic, not atom trajectories.

Reference example: Intrinsic 300 K: n=p=1e16 m⁻³ and σ=0.00030441356 S/m.

Primary observation: conductivity (S/m). Sensors use seconds in distance mode.

Modes: Intrinsic, n-type, p-type.

Supported controls (only model-relevant controls are exposed):

- Temperature (`temperature`): 250.0…400.0 K; default 300.0.
- Ionized dopant concentration (`doping`): 0.0…1e+21 m⁻³; default 100000000000000000000.0.


## s12-e01 — Diodes

Series source, resistor and junction diode; cathode marked with a band.

The diode operating point is the intersection of Shockley current and the series-resistor load line.

Equation: `I=I_s(e^{V_D/(nV_T)}-1),\quad V_s=V_D+IR`

I A; VD,Vs,VT=kBT/e V; n ideality; R Ω.

Vs −5…12 V; R 100…100000 Ω; T 250…400 K; ideality 1…2; Is300 1e−14…1e−9 A. Bracketed bisection, 96 iterations, voltage residual ≤1e−11 max(1,|Vs|). Temperature-dependent Is uses fixed Eg=1.12 eV. No breakdown, capacitance, self-heating or SPICE claim.

Reference example: At zero supply the operating point is I=0, VD=0.

Primary observation: current (A). Sensors use seconds in distance mode.

Modes: Series diode.

Supported controls (only model-relevant controls are exposed):

- Supply (`supply`): -5.0…12.0 V; default 1.0.
- Series resistance (`resistance`): 100.0…100000.0 Ω; default 1000.0.
- Junction temperature (`temperature`): 250.0…400.0 K; default 300.0.
- Ideality factor (`ideality`): 1.0…2.0 ; default 1.5.
- Is at 300 K (`referenceIs`): 1e-14…1e-9 A; default 1e-12.


## s12-e02 — Transistors

Generic NPN E–B–C teaching package, base resistor and collector load.

Base drive and the collector load jointly determine cutoff, active operation or saturation. All terminal currents balance.

Equation: `I_B=\max(0,(V_{drive}-.65)/R_B),\quad I_E=I_B+I_C`

Currents A; resistances Ω; Vce V; region 0 cutoff, 1 active, 2 saturation.

Piecewise DC model: VBE=0.65 V, knee=0.15 V, Ic=βIb min(1,Vce/0.15). Solve its intersection with Vcc−RcIc. Excludes leakage, Early effect, charge storage and temperature dependence. Generic package pin labels, not a named-device pinout.

Reference example: Drive below 0.65 V gives Ib=Ic=0 and Vce=Vcc.

Primary observation: collectorCurrent (A). Sensors use seconds in distance mode.

Modes: Common emitter.

Supported controls (only model-relevant controls are exposed):

- Base drive (`drive`): 0.0…5.0 V; default 1.2.
- Base resistance (`baseResistance`): 1000.0…100000.0 Ω; default 10000.0.
- Collector supply (`supply`): 1.0…12.0 V; default 5.0.
- Collector resistance (`collectorResistance`): 100.0…10000.0 Ω; default 1000.0.
- Forward current gain (`beta`): 50.0…300.0 ; default 100.0.


## s12-e03 — Amplifiers

Generic ideal op-amp with dual rails and feedback resistors; two-channel oscilloscope.

Closed-loop gain determines the requested output; supply headroom limits the actual output. Inverting and non-inverting configurations differ in sign and gain.

Equation: `A_{noninv}=1+R_f/R_g,\quad A_{inv}=-R_f/R_{in},\quad V_o=\operatorname{clip}(AV_i)`

Resistances Ω; vin,vout V; frequency Hz; gain dimensionless.

Ideal quasistatic low-frequency amplifier, 0.5…20 Hz; no finite gain bandwidth, slew, input impedance or named-chip claim. Output clamps at ±(rail−margin). The two-cycle graph is an analytic reference; live traces follow physical time.

Reference example: Rf=10 kΩ, Rg=2 kΩ: gains +6 or −5.

Primary observation: gain (). Sensors use seconds in distance mode.

Modes: Non-inverting, Inverting.

Supported controls (only model-relevant controls are exposed):

- Input amplitude (`amplitude`): 0.0…1.0 V; default 0.2.
- Input DC offset (`offset`): -1.0…1.0 V; default 0.0.
- Input frequency (`frequency`): 0.5…20.0 Hz; default 2.0.
- Feedback resistance (`feedback`): 1000.0…100000.0 Ω; default 10000.0.
- Input / ground resistance (`inputResistance`): 1000.0…100000.0 Ω; default 2000.0.
- Supply rail magnitude (`rail`): 1.0…12.0 V; default 5.0.
- Output headroom (`margin`): 0.1…0.8 V; default 0.2.


## s12-e04 — Logic Gates

Generic Boolean IC, two input switches and output LED; truth table and timing plot.

The output is evaluated directly from the selected Boolean operation. Input changes during playback create real timing edges.

Equation: `Y=A\land B\quad\text{(AND; select other gates)}`

A,B,Y dimensionless Boolean values; physical time s.

Ideal Boolean states 0/1, seven gates; NOT ignores B. No propagation delay, analog voltage, fan-out or named IC pinout. Timing history bounded to 200 input events and 301 samples.

Reference example: AND(1,0)=0; XOR(1,1)=0; NOT(0)=1.

Primary observation: logicOutput (). Sensors use seconds in distance mode.

Modes: AND, OR, NOT, NAND, NOR, XOR, XNOR.

Supported controls (only model-relevant controls are exposed):

- Input A (`inputA`): 0.0…1.0 ; default 0.0.
- Input B (`inputB`): 0.0…1.0 ; default 1.0.


## s12-e05 — Sensors

Offline sensor transfer-function modules: TMP36, illustrative LDR divider and ultrasonic echo.

A sensor maps a physical quantity to an electrical signal. Calibration and valid ranges are part of every measurement.

Equation: `V_{TMP}=.5+.01T_C,\quad V_{LDR}=3.3R_b/(R_{LDR}+R_b),\quad t_{echo}=2d/c`

Temperature K internally; lux lx; distance m; voltages V; echo s.

No phone hardware. TMP36 nominal V=.5+.01T°C, −40…125°C, no noise/accuracy simulation. LDR R=10k(lux/100)^−0.7 Ω with lux clamped to 1…10000; saturation flagged; 3.3 V divider solved with shared MNA. Echo range .02…4 m; c=331.3+.606Tair°C for 0…40°C; no echo outside range.

Reference example: 25°C gives 0.75 V. At 100 lx the equal-resistor divider gives 1.65 V.

Primary observation: sensorOutput (V). Sensors use seconds in distance mode.

Modes: Temperature, Light, Distance.

Supported controls (only model-relevant controls are exposed):

- Simulated temperature (`temperature`): 220.0…430.0 K; default 301.65.
- Illuminance (`lux`): 0.0…20000.0 lx; default 100.0.
- Target distance (`distance`): 0.0…5.0 m; default 1.0.
- Air temperature (`airTemperature`): 273.15…313.15 K; default 293.15.


## s13-e00 — Temperature

Sample vessel with a separate lagging temperature probe; Celsius, kelvin and Fahrenheit readings.

A probe responds with a finite time constant. In cooling-sample mode, the sample loses heat to a fixed ambient reservoir while the negligible-capacity probe follows it.

Equation: `\tau_p\dot T_p=T_s-T_p,\quad mc_p\dot T_s=-hA(T_s-T_a)`

All temperatures K; τ s; h W/(m² K); A m²; cp J/(kg K). TC=TK−273.15, TF=1.8TC+32.

First-order analytic response. Fixed sample is an infinite reservoir; finite sample has capacity m cp and lumped heat loss hA. Probe heat capacity is neglected. No boiling, phase change or spatial gradients. Playback accelerates physical time explicitly.

Reference example: 58.4°C = 331.55 K = 137.12°F.

Primary observation: probeTemperature (K). Sensors use seconds in distance mode.

Modes: Fixed sample, Cooling sample.

Supported controls (only model-relevant controls are exposed):

- Initial sample temperature (`sampleT`): 283.15…353.15 K; default 333.15.
- Initial probe temperature (`probeT`): 273.15…353.15 K; default 293.15.
- Probe time constant (`probeTau`): 1.0…20.0 s; default 4.0.
- Ambient temperature (`ambientT`): 283.15…333.15 K; default 293.15.
- Sample mass (`mass`): 0.1…1.0 kg; default 0.25.
- Specific heat (`cp`): 400.0…4200.0 J/(kg K); default 4180.0.
- Heat transfer coefficient (`h`): 5.0…100.0 W/(m² K); default 25.0.
- Exposed surface (`surface`): 0.02…0.2 m²; default 0.1.


## s13-e01 — Heat Transfer

Steady rod with position probe, lumped cooling body or radiating surface.

Conduction depends on a temperature gradient; convection on temperature difference; radiation on the difference of fourth powers of absolute temperatures.

Equation: `\dot Q=kA(T_L-T_R)/L,\quad\dot Q=hA(T-T_a),\quad\dot Q=\epsilon\sigma A(T^4-T_a^4)`

Heat rate W positive outward/rightward; ΔU J; σ=5.670374419e−8 W m⁻² K⁻⁴.

Conduction: steady 1-D constant k, fixed end reservoirs. Convection: uniform body only when Bi=h(m/ρA)/k≤0.1; invalid otherwise. Radiation: gray body, view factor 1 to large fixed enclosure, no convection; RK4 with stability-limited substeps. No visible glow at ordinary temperatures.

Reference example: Doubling rod area doubles heat rate; equal temperatures give zero net radiation.

Primary observation: heatRate (W). Sensors use seconds in distance mode.

Modes: Conduction, Convection, Radiation.

Supported controls (only model-relevant controls are exposed):

- Thermal conductivity (`conductivity`): 0.1…400.0 W/(m K); default 205.0.
- Rod cross section (`area`): 0.0001…0.0005 m²; default 0.0002.
- Rod length (`length`): 0.05…0.5 m; default 0.2.
- Left reservoir (`leftT`): 283.15…353.15 K; default 333.15.
- Right reservoir (`rightT`): 273.15…333.15 K; default 293.15.
- Probe position / length (`probe`): 0.0…1.0 ; default 0.5.
- Initial body temperature (`initialT`): 273.15…353.15 K; default 333.15.
- Enclosure / ambient (`ambientT`): 273.15…333.15 K; default 293.15.
- Convection coefficient (`h`): 5.0…100.0 W/(m² K); default 12.0.
- Exposed surface (`surface`): 0.01…0.2 m²; default 0.05.
- Body mass (`mass`): 0.1…1.0 kg; default 0.25.
- Specific heat (`cp`): 400.0…4200.0 J/(kg K); default 900.0.
- Density (`density`): 1000.0…9000.0 kg/m³; default 2700.0.
- Emissivity (`emissivity`): 0.05…1.0 ; default 0.8.


## s13-e02 — Gas Laws

Monatomic ideal gas piston and state-linked pressure gauge.

Choose the fixed constraint. The remaining state follows PV=nRT; pressure is never independently editable.

Equation: `PV=nRT,\quad W_T=nRT\ln(V_2/V_1),\quad W_P=P\Delta V`

P Pa; V m³; n mol; R=kB NA=8.314462618… J/(mol K); Q into gas, W by gas.

Quasistatic ideal monatomic gas; n .01….2 mol, initial T 250…450 K, V .001….02 m³; ratios .75…3. Reference-path duration controls playback only. No real-gas, turbulence or particle dynamics claim.

Reference example: At .1 mol, 300 K and .0025 m³: P=99773.55 Pa.

Primary observation: pressure (Pa). Sensors use seconds in distance mode.

Modes: Isothermal, Isochoric, Isobaric.

Supported controls (only model-relevant controls are exposed):

- Amount (`amount`): 0.01…0.2 mol; default 0.1.
- Initial temperature (`initialT`): 250.0…450.0 K; default 300.0.
- Initial volume (`initialVolume`): 0.001…0.02 m³; default 0.0025.
- Final / initial volume (`volumeRatio`): 0.75…3.0 ; default 1.8.
- Final / initial temperature (`temperatureRatio`): 0.7…1.3 ; default 1.2.
- Reference-path duration (`duration`): 5.0…30.0 s; default 10.0.


## s13-e03 — First Law

Gas piston, energy ledger and process history.

Internal-energy change is heat entering minus work performed by the gas. A chosen process determines heat and work consistently.

Equation: `\Delta U=nC_V\Delta T=Q-W,\quad PV^\gamma=\text{constant (adiabatic)}`

ΔU,Q,W J; work positive for expansion; heat positive into gas.

Monatomic ideal gas Cv=1.5R; reversible adiabatic γ=5/3. Same state limits as Gas Laws. Q and W are derived, never arbitrary independent inputs. History records actual states and can be replayed as trials.

Reference example: Isochoric warming .1 mol by 30 K: W=0, Q=ΔU=37.41508 J.

Primary observation: deltaU (J). Sensors use seconds in distance mode.

Modes: Isochoric, Isobaric, Isothermal, Adiabatic.

Supported controls (only model-relevant controls are exposed):

- Amount (`amount`): 0.01…0.2 mol; default 0.1.
- Initial temperature (`initialT`): 250.0…450.0 K; default 300.0.
- Initial volume (`initialVolume`): 0.001…0.02 m³; default 0.0025.
- Final / initial volume (`volumeRatio`): 0.75…3.0 ; default 1.8.
- Final / initial temperature (`temperatureRatio`): 0.7…1.3 ; default 1.2.
- Reference-path duration (`duration`): 5.0…30.0 s; default 10.0.


## s13-e04 — Entropy

State-change reference path, free-expansion endpoints or two finite thermal bodies.

Entropy is a state function. Free expansion increases gas entropy without heat or work. Thermal contact conserves total energy and produces nonnegative total entropy.

Equation: `\Delta S=nC_V\ln(T_2/T_1)+nR\ln(V_2/V_1),\quad T_f=(C_1T_1+C_2T_2)/(C_1+C_2)`

S J/K; capacities J/K; conductance W/K; temperatures K.

Ideal monatomic gas ΔS=nCv ln(T2/T1)+nR ln(V2/V1). State path is a reversible reference, not an irreversible trajectory. Free expansion is endpoint-only, V2≥V1, no identical-gas mixing claim. Two constant heat capacities exchange heat through conductance G in an isolated pair.

Reference example: Isothermal doubling of .1 mol: ΔS=.1R ln2=0.5763146 J/K.

Primary observation: entropy (J/K). Sensors use seconds in distance mode.

Modes: State change, Free expansion, Thermal contact.

Supported controls (only model-relevant controls are exposed):

- Amount (`amount`): 0.01…0.2 mol; default 0.1.
- Initial temperature (`initialT`): 250.0…450.0 K; default 300.0.
- Initial volume (`initialVolume`): 0.001…0.02 m³; default 0.0025.
- Final / initial volume (`volumeRatio`): 0.75…3.0 ; default 1.8.
- Final / initial temperature (`temperatureRatio`): 0.7…1.3 ; default 1.2.
- Reference-path duration (`duration`): 5.0…30.0 s; default 10.0.
- Final reference temperature (`finalT`): 250.0…450.0 K; default 330.0.
- Endpoint: 0 initial, 1 expanded (`expanded`): 0.0…1.0 ; default 1.0.
- Body 1 initial temperature (`body1T`): 283.15…353.15 K; default 343.15.
- Body 2 initial temperature (`body2T`): 283.15…353.15 K; default 293.15.
- Body 1 heat capacity (`capacity1`): 100.0…2000.0 J/K; default 500.0.
- Body 2 heat capacity (`capacity2`): 100.0…2000.0 J/K; default 700.0.
- Contact conductance (`conductance`): 1.0…50.0 W/K; default 10.0.


## s13-e05 — Heat Engines

Four-stage reversible Carnot piston engine, hot/cold reservoirs and a closed P–V cycle.

Isothermal expansion, adiabatic expansion, isothermal compression and adiabatic compression close the cycle. Enclosed P–V area equals net work.

Equation: `\eta=1-T_c/T_h,\quad Q_h=nRT_h\ln r,\quad W_{net}=Q_h-Q_c`

T K; P Pa; V m³; energies J; efficiency fraction. Stage index 0…3.

Ideal reversible monatomic gas. Th 400…650 K, Tc 250…350 K; Th>Tc; expansion ratio 1.2…3. Geometry follows both adiabats, not a decorative ellipse. Reference heat totals differ from cumulative current-stage heat. No RPM, friction or practical-engine claim.

Reference example: n=.1 mol, Th=600 K, Tc=300 K, r=2: Qh=345.789 J, Wnet=172.894 J.

Primary observation: efficiency (). Sensors use seconds in distance mode.

Modes: Carnot cycle.

Supported controls (only model-relevant controls are exposed):

- Amount (`amount`): 0.01…0.2 mol; default 0.1.
- Hot reservoir (`hotT`): 400.0…650.0 K; default 600.0.
- Cold reservoir (`coldT`): 250.0…350.0 K; default 300.0.
- Cycle initial volume (`initialVolume`): 0.001…0.003 m³; default 0.002.
- Isothermal expansion ratio (`volumeRatio`): 1.2…3.0 ; default 2.0.
- Cycle duration (`duration`): 8.0…32.0 s; default 16.0.


