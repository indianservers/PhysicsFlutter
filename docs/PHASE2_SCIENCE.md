# Phase 2 scientific models

Model ID: `dynamics-2.0`. The 18 new labs are stable IDs `s02-e00`…`s04-e05`. All use SI doubles. Standard gravity is the defined conventional value 9.80665 m/s², not a device measurement or a claim about local gravity. These are explicitly bounded educational models, not a general rigid-body engine. The Phase 1 `measurement-1.0` model and scientific notes remain supported.

## Coordinates, vectors and clock

`core/physics/dynamics.dart` contains pure Dart vector arithmetic, reference-frame transforms, torque, COM, impact response, friction events and trajectories. `Vec2` uses +x right and +y up. Painters invert screen y. Slope motion uses a separately stated positive-downhill coordinate. Camera following, zoom and pan affect rendering only. Controls that edit positions use the same drawing coordinates inversely; precise inputs are always available. Camera-following tracks have calibrated changing coordinates, so a cart can remain near the screen centre while changing its world position.

Physics advances at 1/120 s. Display frame intervals feed an accumulator, independent of integration. Each display callback accepts at most 0.1 simulated seconds and executes at most 12 steps. Excess catch-up time is discarded: a stalled device slows the simulation rather than making a large physical jump. The speed selector scales requested model time by 0.25×, 0.5×, 1× or 2×. Pause clears fractional catch-up. Leaving Experiment, covering a route or backgrounding stops the ticker. Resuming/restoring never automatically plays or counts background wall time.

Except for piecewise contact/impact cases, positions are analytic functions of the initial conditions and integer tick time. Friction integrates each constant-acceleration segment exactly, splitting at v=0. Acceleration schedules split at their stated switch time. Collisions are located at an exact within-step contact event. No Euler energy growth, overlap correction impulse or random perturbation is added.

Graph history is capped at 301 states, normally sampled every eight physics steps (15 Hz), plus explicit single-step, replay-end and event samples. Collision/schedule discontinuities include calculated left/right event states. A graph cursor selects an actual stored state. Linear traces connect samples; acceleration schedules use a step plot. Position slopes use the selected state's analytic velocity. Velocity graphs show signed area and separately computed distance. The axis never implies an artificial observation between samples. Numerical replay quantizes requested time to the nearest fixed step and deterministically reconstructs the model.

Model/initial-condition changes pause and restart the trajectory at t=0 with a visible explanation. Frame and overlay changes preserve the physical event/time. Trial configuration snapshots are deep-copied, so later edits cannot mutate prior observations in memory or on disk.

## Mechanics

### Free Body Diagrams

A horizontal crate receives weight (0,−mg), applied F(cosθ,sinθ), normal (0,mg−F sinθ) and signed Coulomb friction. The UI restricts the upward component to mg; no unsupported lift-off is implied. Applied angles cover −180°…180°. Normal is never negative. In-plane net force is F cosθ + f and acceleration is net/m. Static friction is −F cosθ when within its limit, not automatically its maximum. Original force and component arrows are never both accumulated. The resultant is labeled separately; isolation removes environmental scenery. Force-membership and numerical prediction checks explain which interactions belong to the crate alone.

### Inclined Plane

Positive s is downhill. N=mg cosθ and gravitational drive=mg sinθ. At rest, sticking is possible if |drive|≤μsN. In sliding, f=−μkN sign(v). A negative (uphill) velocity therefore gives downhill kinetic friction. A zero-speed event retests the static condition before any reversal. The drawing's full weight and its explanatory projections share one force scale; projections are not extra forces. The five-metre ramp has stopping boundaries. At a boundary the run stops; the external end-stop reaction is identified and no arbitrary bounce is offered.

### Pulley Systems

Two configurations only. Both assume massless inextensible rope, frictionless massless pulleys and no slipping.

Atwood: generalized positive x means A rises and B descends. a=(mB−mA)g/(mA+mB), T=mA(g+a). The plotted common-up coordinates are xA=x, xB=−x, and likewise for velocities. Thus rope length is unchanged. Equal masses give a=0 and T=mg.

Movable topology: one end fixed at the ceiling; rope passes beneath the load's movable sheave, over a fixed redirect sheave and down to effort mass m. Two segments support load M. With load-up x and effort-down coordinate 2x:

2T−Mg=Ma; mg−T=m(2a), hence a=(2m−M)g/(M+4m), T=m(g−2a).

The scene moves the sheave with the load, labels load support 2T and effort support T, and maintains the 2:1 travel/speed ratio. No compound topology is shown. At apparatus travel limits the run stops against external stops. The displayed ideal tension is the free-motion prediction retained at that stopping configuration; it is not claimed to be a unique post-impact rope stress. End-stop transient forces/compliance are outside the model.

### Torque Levers

A static beam has two movable directional forces, an adjustable ideal bilateral pivot, and optional uniform beam mass. For each attachment r=(x−xp,0), τz=r×F=(x−xp)F sinθ, anticlockwise positive. The perpendicular arm is |x−xp| |sinθ|. Beam weight acts at its geometric centre x=0. Pivot reactions can balance force but supply no couple; zero net torque is independently needed for unclamped equilibrium. No rotational dynamics or arbitrary torque-to-angle animation is present.

### Equilibrium & Centre of Mass

Three positive point masses form a composite assembly with massless connecting rods. COM=Σmi ri/Σmi is computed from the actual original coordinates. A finite support base can balance gravity with a reaction through the COM projection when the projection is inside the base. At an edge the state is marginal; it is not mislabeled neutral. Outside the base, a residual tipping torque is calculated about the nearest edge. No tipping transient is simulated.

Suspension is a calculated static equilibrium about a selected eye. The assembly rotates through φ=−π/2−atan2(yCOM−yeye,xCOM−xeye). Its transformed COM lies vertically below the eye; the plumb line passes through it. Metrics explicitly retain original-assembly coordinates for mass-distribution comparison. Suspended net torque is zero in its equilibrium frame. There is no unsupported arbitrary lamina or numerically chosen visual centre.

### Momentum & Collisions

Two positive-mass carts, each 0.8 m long, move on an unbounded 1D frictionless track. A starts left of B. If approaching, contact time is gap/(uA−uB). At contact:

J=(1+e)(uA−uB)/(1/mA+1/mB); vA=uA−J/mA; vB=uB+J/mB.

e∈[0,1]. Separating bodies receive no impulse. One approaching encounter is supported; an impact flag prevents repeated application. e=0 gives equal final velocities, e=1 conserves kinetic energy, and other supported e values lose relative kinetic energy while preserving system momentum. The exact contact position avoids penetration; no position-correction impulse is mixed into J. Impact history and event graph states preserve the actual event time and before/after values.

## Motion & Kinematics

### Position–Time

x=x0+v0t+at²/2; v=v0+at. Position and displacement are signed; distance integrates |v| and splits at −v0/a when a reversal lies inside the elapsed interval. The graph's tangent uses the selected sample's exact velocity. Average velocity is displacement/t, with t=0 handled explicitly. A time scrub reconstructs the actual initial-value solution.

### Velocity–Time

The same analytic 1D model drives vehicle position and velocity. Signed v–t area is displacement; distance is the integral of speed, not the signed area. The actual shaded/sample trace and numeric interpretation distinguish a reversal. For v0=−2 m/s,a=1 m/s²,t=4 s: displacement=0 but distance=4 m.

### Acceleration–Time

Constant mode and a bounded two-segment schedule are implemented. Within each segment, velocity and position integrate analytically. Steps crossing the switch split exactly; position/velocity remain continuous. The two acceleration values at the event describe left/right limits in a step graph. Acceleration area equals v−v0. There is no free-fall control or unsupported hand-drawn schedule.

### Projectile Motion

Uniform downward gravity, no drag and flat ground y=0. Initial velocity is resolved by the launch angle; height may be nonzero and angles may be downward, horizontal or vertical. Landing time is the nonnegative physically valid root (vy0+sqrt(vy0²+2gh))/g. xlanding=vx0 tflight. Maximum height is h+max(vy0,0)²/(2g). The displayed state is evaluated at landing time and stopped at ground, including zero-speed and ground-level downward cases. No equal-height-only range formula is misapplied. Ball rotation is not simulated.

### Relative Motion

Two trains occupy separate noninteracting tracks. Ground, A and B frames use Galilean transforms x'=x−Vt, v'=v−V, with coincident frame origins at t=0. Relative differences xA−xB and vA−vB are invariant under the shared frame transformation. Switching observer preserves integer time and the physical event. No relativistic claim or universal absolute-speed subtraction is used.

### Circular Motion

A bead follows a horizontal circular constraint with positive r≥0.2 m and nonnegative constant tangential speed. θ=θ0+(v/r)t, ω=v/r, ac=v²/r, required radial resultant=m v²/r, period=2πr/v. At v=0 the period is reported infinite/undefined rather than divided by zero. Velocity is tangent and acceleration inward. Radial force is a role of the constraint resultant, not another interaction to add. No conical pendulum is depicted.

## Force & Newton's Laws

### First Law / Inertia

An ideal air-table puck receives a specified instantaneous initial impulse J, so v(0+)=v0+J/m. Afterwards the in-plane net force is zero and velocity stays constant. Zero impulse and zero initial velocity leave it at rest. The velocity arrow is explicitly not a force. No sustained push/resistance control is offered without a model.

### Second Law / F=ma

A cart with positive fixed mass receives a signed constant net horizontal force and evolves analytically with a=Fnet/m. Resistance is absent, so applied and net force coincide by this model's stated assumption. Force and mass sweep rows calculate F/m for each row; they are labeled predictions, not recorded observations.

### Third Law / Action–Reaction Pairs

An ideal prescribed internal actuator applies −F to A and +F to B for duration D. Its internal energy source is not modeled. Let s=min(t,D), J=Fs: velocities change by −J/mA and +J/mB. Displacement includes acceleration during s and coasting after D, with no timestep crossing error at pulse end. Different masses get different accelerations. Individual diagrams attach each force to its own body; only the combined system cancels the internal pair. A common initial velocity allows nonzero conserved COM momentum. There is no unsupported general contact engine.

### Friction

The horizontal Coulomb model uses N=mg, |fs|≤μsN and fk=−μkN sign(v). A stopping event retests static equilibrium exactly. With no drive, friction cannot create kinetic energy or launch the body from rest. Preset wood/rubber/ice coefficients are explicitly illustrative editable input values; μk≤μs is a supported-model restriction, not a universal materials database.

### Tension & Normal Force

Hanging mode prescribes upward acceleration with T=m(g+ay). The range −5…5 m/s² satisfies ay≥−g, maintaining nonnegative taut tension. An ideal hoist supplies the prescribed motion; no compressive rope is shown. Table mode uses N=mg−F sinθ; a force edit that would require lift-off is restricted with an explanation. Horizontal acceleration is F cosθ/m. The model never silently reports negative normal force as contact.

### Multi-Force Challenge

Three in-plane forces add as signed vectors once each, then a=ΣF/m. This is a top-down frictionless plane; vertical weight/support balance outside the drawn plane. Reproducible tasks cover equilibrium, acceleration target, resultant direction, cancelling one force with two others and a doubled-mass prediction. Equilibrium tolerance is resultant ≤0.05 N; target acceleration tolerance is 0.05 m/s² per component. Numeric predictions accept max(0.01,1% of reference magnitude); directions use a wrapped angular difference. Attempts store inputs, target, parameters, time, correctness, feedback and tolerance explanation. Completion requires a changed parameter, a correct supported attempt, guided steps and a real recorded trial.

## References checked during development

Lesson prose and drawings are original. Target PNGs are visual references only. Equations were independently derived/implemented and compared with these primary educational sources:

- OpenStax, Newton-law problem solving and force diagrams: https://openstax.org/books/university-physics-volume-1/pages/6-1-solving-problems-with-newtons-laws
- OpenStax, friction: https://openstax.org/books/university-physics-volume-1/pages/6-2-friction
- OpenStax, constant-acceleration kinematics: https://openstax.org/books/university-physics-volume-1/pages/3-4-motion-with-constant-acceleration
- OpenStax, projectile motion: https://openstax.org/books/university-physics-volume-1/pages/4-3-projectile-motion
- OpenStax, circular motion: https://openstax.org/books/university-physics-volume-1/pages/4-4-uniform-and-nonuniform-circular-motion
- OpenStax, relative frames: https://openstax.org/books/university-physics-volume-1/pages/4-5-relative-motion-in-one-and-two-dimensions
- OpenStax, collisions: https://openstax.org/books/university-physics-volume-1/pages/9-4-types-of-collisions
- OpenStax, centre of mass: https://openstax.org/books/university-physics-volume-1/pages/9-6-center-of-mass
- OpenStax, torque: https://openstax.org/books/university-physics-volume-1/pages/10-6-torque
- University of Illinois Mechanics Reference, restitution/impulse: https://mechref.engr.illinois.edu/dyn/rec.html

The movable-pulley formula above is derived from the actual displayed rope topology rather than borrowed from the mockup. Unknown dynamics versions are rejected on restore; their original saved trial snapshots remain available instead of silently receiving new model defaults.
