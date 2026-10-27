# Five UI/UX improvements for each laboratory

**116 physical labs × five tailored improvements = 580 lab-level enhancements.** The six overview tools are not counted as physical labs.

Open a lab → **Lab options → Lab-specific tools**, or use **5 lab-specific tools** inside Inspect. Tune, Compare, Watch, Plot and Explain share a consistent layout; their scenarios, control targets, focal quantities, axes and reasoning prompts are curated per experiment.

All actions use the actual scientific model. Mode-dependent controls are checked, captures require a ready state, and plots contain explicitly captured model snapshots. The existing Record Trial action remains the way to keep a complete reproducible experiment record. Saved explanation worksheets are accessible from **Saved → Investigation worksheets**.

Implementation: `lib/features/workbench/lab_research.dart`; reviewed definitions: `lib/content/lab_research_profiles.tsv`; source-readout adapters: the corresponding laboratory workspaces.

Status: **Verified** — see `LAB_SPECIFIC_UX_VALIDATION.json` for actual test and native-device coverage.

## Measurement

### Meter Scale — `s01-e00`

1. **Read from a nonzero origin** — Preview `a = .02` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare short and long spans** — Preview `b` at .04 and .08 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Endpoint subtraction lens** — Focused, live source quantities: `length,endpointA,endpointB`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build an endpoint-versus-length plot** — Build an explicit-snapshot scatter plot of `length` against `b`, with actual units and captured conditions.
5. **Explain why the first ruler mark need not be zero.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Vernier Caliper — `s01-e01`

1. **Practice positive zero correction** — Preview `zero = .0002` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare two jaw openings** — Preview `a` at .0136 and .0236 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Separate vernier contributions** — Focused, live source quantities: `main,fraction,zero,length`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Trace signed calibration correction** — Build an explicit-snapshot scatter plot of `length` against `zero`, with actual units and captured conditions.
5. **Explain why a positive zero error is subtracted from the observed length.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Micrometer — `s01-e02`

1. **Cross a sleeve millimetre mark** — Preview `a = 1.02` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare negative and positive zero error** — Preview `zero` at -.02 and .02 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Read sleeve and thimble together** — Focused, live source quantities: `main,fraction,observed,length`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Map screw indication to corrected size** — Build an explicit-snapshot scatter plot of `length` against `a`, with actual units and captured conditions.
5. **Explain how one turn, pitch and thimble divisions relate to the final reading.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Spherometer — `s01-e03`

1. **Approach plane contact gently** — Preview `a = .0001` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare two leg radii** — Preview `r` at .03 and .06 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Keep reference and sagitta distinct** — Focused, live source quantities: `indication,reference,sagitta,radius`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Plot radius only after both contacts** — Build an explicit-snapshot scatter plot of `radius` against `r`, with actual units and captured conditions.
5. **Explain why the screw indication alone is not the curved surface sagitta.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Mass & Time — `s01-e04`

1. **Establish a constant-speed timing run** — Preview `acceleration = 0` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare two release speeds** — Preview `v0` at .2 and .4 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Separate average and instantaneous speed** — Focused, live source quantities: `elapsed,travelled,speed,instantaneousSpeed`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a release-speed timing study** — Build an explicit-snapshot scatter plot of `speed` against `v0`, with actual units and captured conditions.
5. **Explain when track-average speed differs from the speed at the finish.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Uncertainty — `s01-e05`

1. **Set a defensible instrument resolution** — Preview `resolution = .0001` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare resolution contributions** — Preview `resolution` at .0001 and .001 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Separate repeatability and resolution** — Focused, live source quantities: `sampleCount,sem,instrument,combined`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Plot combined uncertainty from real samples** — Build an explicit-snapshot scatter plot of `combined` against `resolution`, with actual units and captured conditions.
5. **Explain why more repeated readings do not eliminate instrument resolution uncertainty.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

## Mechanics

### Free Body Diagrams — `s02-e00`

1. **Resolve an angled applied force** — Preview `angle = 30` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare sticking and sliding loads** — Preview `force` at 5 and 15 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Inspect support and friction together** — Focused, live source quantities: `normal,friction,ax`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a force-acceleration response** — Build an explicit-snapshot scatter plot of `ax` against `force`, with actual units and captured conditions.
5. **Explain why force components must not be counted as additional forces.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Inclined Plane — `s02-e01`

1. **Explore a shallow ramp** — Preview `angle = 10` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare below and above breakaway** — Preview `angle` at 10 and 35 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Read forces in slope coordinates** — Focused, live source quantities: `normal,friction,ax`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Plot ramp angle against acceleration** — Build an explicit-snapshot scatter plot of `ax` against `angle`, with actual units and captured conditions.
5. **Explain why static friction is not always equal to its limiting value.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Pulley Systems — `s02-e02`

1. **Balance the Atwood masses** — Preview `m2 = 2` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare balanced and unbalanced loads** — Preview `m2` at 2 and 4 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Inspect shared acceleration and tension** — Focused, live source quantities: `ax,tension`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build an unequal-mass pulley study** — Build an explicit-snapshot scatter plot of `ax` against `m2`, with actual units and captured conditions.
5. **Explain why the same rope tension does not imply equal weights.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Torque Levers — `s02-e03`

1. **Move a force to the pivot** — Preview `r1 = 0` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare moment arms** — Preview `r1` at -.5 and -1 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Keep clockwise and anticlockwise signs** — Focused, live source quantities: `torque1,torque2,netTorque`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Plot signed torque against lever arm** — Build an explicit-snapshot scatter plot of `netTorque` against `r1`, with actual units and captured conditions.
5. **Explain why a force applied through the pivot has zero moment.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Equilibrium & Centre of Mass — `s02-e04`

1. **Place support near the mass-weighted centre** — Preview `support = .1666666667` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare centre-of-mass shifts** — Preview `m2` at 1 and 5 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Track the centre before judging stability** — Focused, live source quantities: `x,y`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Plot mass redistribution and centre position** — Build an explicit-snapshot scatter plot of `x` against `m2`, with actual units and captured conditions.
5. **Explain why a geometric centre need not be the centre of mass.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Momentum & Collisions — `s02-e05`

1. **Try a perfectly inelastic collision** — Preview `e = 0` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare inelastic and elastic outcomes** — Preview `e` at 0 and 1 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Compare momentum with kinetic energy** — Focused, live source quantities: `initialMomentum,momentum,energy`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Audit momentum across restitution settings** — Build an explicit-snapshot scatter plot of `momentum` against `e`, with actual units and captured conditions.
5. **Explain why conserved momentum does not require conserved kinetic energy.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Rotational Inertia — `s02-e06`

1. **Increase the solid disk radius** — Preview `radius = .6` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare disks at fixed radius** — Preview `mass` at 1 and 2 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Read rotational resistance and response** — Focused, live source quantities: `inertia,angularAcceleration,energy`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build an inertia-radius study** — Build an explicit-snapshot scatter plot of `inertia` against `radius`, with actual units and captured conditions.
5. **Explain why doubling disk radius changes inertia more than doubling mass.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Rolling Motion — `s02-e07`

1. **Begin with a gentle rolling ramp** — Preview `incline = 10` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare two rolling accelerations** — Preview `incline` at 10 and 30 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Check the no-slip requirement** — Focused, live source quantities: `requiredFriction,acceleration,angularSpeed`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Capture equal-time rolling speeds** — Build an explicit-snapshot scatter plot of `speed` against `incline`, with actual units and captured conditions.
5. **Explain how rotational kinetic energy reduces translational acceleration.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Hooke’s Law — `s02-e08`

1. **Stretch beyond the initial extension** — Preview `extension = .12` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare force and energy scaling** — Preview `extension` at .04 and .08 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Distinguish linear force from quadratic energy** — Focused, live source quantities: `force,energy`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Construct a spring force-extension plot** — Build an explicit-snapshot scatter plot of `force` against `extension`, with actual units and captured conditions.
5. **Explain why doubling extension doubles force but quadruples stored energy.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Young’s Modulus — `s02-e09`

1. **Double the wire radius** — Preview `radius = .001` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare two tensile loads** — Preview `force` at 25 and 50 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Watch the small-strain validity limit** — Focused, live source quantities: `stress,strain,length`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a load-extension response** — Build an explicit-snapshot scatter plot of `length` against `force`, with actual units and captured conditions.
5. **Explain why cross-sectional area, rather than radius alone, sets tensile stress.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

## Motion & Kinematics

### Position–Time — `s03-e00`

1. **Create a straight position-time trace** — Preview `a = 0` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare opposite graph slopes** — Preview `v0` at -2 and 2 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Read position and its rate separately** — Focused, live source quantities: `x,vx,ax`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Compare initial slopes numerically** — Build an explicit-snapshot scatter plot of `vx` against `v0`, with actual units and captured conditions.
5. **Explain what a negative slope says about velocity, not position.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Velocity–Time — `s03-e01`

1. **Hold velocity constant** — Preview `a = 0` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare accumulated displacement** — Preview `v0` at 1 and 3 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Distinguish curve height from area** — Focused, live source quantities: `vx,displacement`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build equal-time displacement samples** — Build an explicit-snapshot scatter plot of `displacement` against `v0`, with actual units and captured conditions.
5. **Explain why displacement is an area under velocity-time, not the curve height.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Acceleration–Time — `s03-e02`

1. **Change the second acceleration segment** — Preview `a2 = -2` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare early and late switching** — Preview `switch` at 1 and 3 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Track acceleration and accumulated velocity** — Focused, live source quantities: `ax,vx,displacement`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Sample velocity at a common final time** — Build an explicit-snapshot scatter plot of `vx` against `switch`, with actual units and captured conditions.
5. **Explain why a negative acceleration need not mean negative velocity.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Projectile Motion — `s03-e03`

1. **Try a 45-degree launch** — Preview `angle = 45` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare complementary launch angles** — Preview `angle` at 30 and 60 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Separate horizontal range and vertical motion** — Focused, live source quantities: `range,vx,vy,y`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a launch-angle range study** — Build an explicit-snapshot scatter plot of `range` against `angle`, with actual units and captured conditions.
5. **Explain why complementary angles need not have equal ranges from an elevated launch.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Relative Motion — `s03-e04`

1. **Move both bodies with the same velocity** — Preview `v2 = 1` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare approaching and separating frames** — Preview `v2` at -2 and 2 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Read relative quantities before frame claims** — Focused, live source quantities: `relativePosition,relativeVelocity`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Plot observer velocity and relative speed** — Build an explicit-snapshot scatter plot of `relativeVelocity` against `v2`, with actual units and captured conditions.
5. **Explain why changing observer changes velocity but not the interaction.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Circular Motion — `s03-e05`

1. **Increase circular speed** — Preview `speed = 3` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare centripetal requirements** — Preview `radius` at .5 and 1.5 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Distinguish inward force from tangential speed** — Focused, live source quantities: `radialForce,ax,ay`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build the quadratic speed-force relation** — Build an explicit-snapshot scatter plot of `radialForce` against `speed`, with actual units and captured conditions.
5. **Explain why an object accelerates even when its speed remains constant.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Free Fall — `s03-e06`

1. **Try a lunar-like gravity setting** — Preview `gravity = 1.62` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare release heights** — Preview `height` at 10 and 40 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Read remaining height and impact time** — Focused, live source quantities: `height,speed,time`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Capture equal-stage falling speeds** — Build an explicit-snapshot scatter plot of `speed` against `height`, with actual units and captured conditions.
5. **Explain why impact time and impact speed scale differently with release height.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

## Force & Newton’s Laws

### First Law / Inertia — `s04-e00`

1. **Remove the applied impulse** — Preview `impulse = 0` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare equal impulses on different masses** — Preview `m` at 1 and 4 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Separate a brief impulse from continuing force** — Focused, live source quantities: `impulse,vx,fx`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build an impulse-response mass study** — Build an explicit-snapshot scatter plot of `vx` against `m`, with actual units and captured conditions.
5. **Explain why continued motion does not require a continuing net force.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Second Law / F = ma — `s04-e01`

1. **Find the zero-net-force case** — Preview `force = 0` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare acceleration at fixed force** — Preview `m` at 1 and 3 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Connect net force to acceleration** — Focused, live source quantities: `fx,ax,vx`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Construct a signed force-acceleration plot** — Build an explicit-snapshot scatter plot of `ax` against `force`, with actual units and captured conditions.
5. **Explain why doubling mass at fixed net force reduces acceleration.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Third Law / Action–Reaction Pairs — `s04-e02`

1. **Make the second cart heavier** — Preview `m2 = 6` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare action-reaction accelerations** — Preview `m2` at 1 and 6 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Read the two-body interaction separately** — Focused, live source quantities: `ax,force2,momentum`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Audit the first cart under partner-mass changes** — Build an explicit-snapshot scatter plot of `ax` against `m2`, with actual units and captured conditions.
5. **Explain why equal and opposite forces can produce unequal accelerations.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Friction — `s04-e03`

1. **Inspect friction without an applied push** — Preview `force = 0` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare static and kinetic response** — Preview `force` at 5 and 12 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Follow friction direction and magnitude** — Focused, live source quantities: `friction,normal,ax`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a friction-versus-push record** — Build an explicit-snapshot scatter plot of `friction` against `force`, with actual units and captured conditions.
5. **Explain why friction can grow with a push before motion starts.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Tension & Normal Force — `s04-e04`

1. **Set an upward elevator acceleration** — Preview `a = 2` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare apparent weights** — Preview `a` at -2 and 2 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Separate support force from gravity** — Focused, live source quantities: `supportForce,ax,ay`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Plot support force against elevator acceleration** — Build an explicit-snapshot scatter plot of `supportForce` against `a`, with actual units and captured conditions.
5. **Explain why apparent weight changes although gravitational weight does not.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Multi-Force Challenge — `s04-e05`

1. **Align two applied forces** — Preview `d2 = 0` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare reinforcement and opposition** — Preview `d2` at 0 and 180 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Resolve the vector resultant** — Focused, live source quantities: `fx,fy,ax,ay`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Sample force direction and x acceleration** — Build an explicit-snapshot scatter plot of `ax` against `d2`, with actual units and captured conditions.
5. **Explain why force magnitudes cannot simply be added without directions.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

## Work, Energy & Power

### Work — `s05-e00`

1. **Turn the applied force perpendicular** — Preview `angle = -90` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare parallel and transverse work** — Preview `angle` at 0 and -90 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Keep applied and net work distinct** — Focused, live source quantities: `appliedWork,frictionWork,netWork`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Sample work at equal travelled distances** — Build an explicit-snapshot scatter plot of `netWork` against `angle`, with actual units and captured conditions.
5. **Explain why a nonzero force can do zero work on the chosen displacement.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Kinetic Energy — `s05-e01`

1. **Reverse velocity at fixed speed magnitude** — Preview `speed = -3` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare kinetic energy scaling** — Preview `speed` at 2 and 4 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Read speed magnitude separately from direction** — Focused, live source quantities: `K,vx`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a quadratic kinetic-energy plot** — Build an explicit-snapshot scatter plot of `K` against `speed`, with actual units and captured conditions.
5. **Explain why reversing velocity does not make kinetic energy negative.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Potential Energy — `s05-e02`

1. **Move the potential-energy datum** — Preview `zero = 2` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare two reference levels** — Preview `zero` at 0 and 3 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Separate potential values from differences** — Focused, live source quantities: `U,targetDeltaU`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Plot reference choice and potential value** — Build an explicit-snapshot scatter plot of `U` against `zero`, with actual units and captured conditions.
5. **Explain why changing the zero of potential does not change forces.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Energy Conservation — `s05-e03`

1. **Introduce dissipative drag** — Preview `drag = 1` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare mechanical-energy histories** — Preview `drag` at 0 and 1 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Separate mechanical and total energy accounting** — Focused, live source quantities: `K,U,total,loss`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Capture energies at matching model times** — Build an explicit-snapshot scatter plot of `total` against `drag`, with actual units and captured conditions.
5. **Explain where lost mechanical energy appears in this model.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Power — `s05-e04`

1. **Lift the load in less time** — Preview `duration = 2` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare equal lifts at different durations** — Preview `duration` at 2 and 8 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Read energy transfer and transfer rate** — Focused, live source quantities: `power,work`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a duration-average-power plot** — Build an explicit-snapshot scatter plot of `power` against `duration`, with actual units and captured conditions.
5. **Explain why equal work can require different average power.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Efficiency — `s05-e05`

1. **Try ideal unit efficiency** — Preview `eta = 1` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare useful and wasted energy** — Preview `eta` at .4 and .8 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Read the complete conversion budget** — Focused, live source quantities: `useful,loss,efficiency`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Plot requested conversion efficiency** — Build an explicit-snapshot scatter plot of `efficiency` against `eta`, with actual units and captured conditions.
5. **Explain why useful output cannot exceed input in this stated model.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

## Gravitation

### Universal Gravitation — `s06-e00`

1. **Double centre-to-centre separation** — Preview `r = 40` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare source-mass scaling** — Preview `source` at .5 and 2 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Read a large force with explicit units** — Focused, live source quantities: `force`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build an inverse-square attraction study** — Build an explicit-snapshot scatter plot of `force` against `r`, with actual units and captured conditions.
5. **Explain why doubling separation has a stronger effect than doubling one mass.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Gravitational Field — `s06-e01`

1. **Move the gravitational probe outward** — Preview `r = 4` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare fields from different masses** — Preview `source` at .5 and 2 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Separate field magnitude and direction** — Focused, live source quantities: `field,gx,gy`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Construct a field-versus-radius record** — Build an explicit-snapshot scatter plot of `field` against `r`, with actual units and captured conditions.
5. **Explain why field strength is independent of the test body's mass.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Gravitational Potential — `s06-e02`

1. **Move outward in a negative potential** — Preview `r = 4` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare potential with test-mass choice** — Preview `m` at 500 and 1500 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Separate potential per mass from energy** — Focused, live source quantities: `potential,U`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build an exterior potential profile** — Build an explicit-snapshot scatter plot of `potential` against `r`, with actual units and captured conditions.
5. **Explain why zero-at-infinity gravitational potential is negative.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Orbits — `s06-e03`

1. **Introduce a radial launch component** — Preview `vr = 1` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare orbital-energy regimes** — Preview `vt` at 4 and 7 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Read energy before naming an orbit** — Focused, live source quantities: `specificEnergy,eccentricity,radius`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Capture the transverse-speed energy boundary** — Build an explicit-snapshot scatter plot of `specificEnergy` against `vt`, with actual units and captured conditions.
5. **Explain why orbital speed alone does not determine a path without position and direction.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Escape Velocity — `s06-e04`

1. **Try a faster outward launch** — Preview `vr = 12` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare escape thresholds** — Preview `source` at .5 and 2 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Separate launch speed from escape speed** — Focused, live source quantities: `escape,specificEnergy,radius`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build an escape-speed radius study** — Build an explicit-snapshot scatter plot of `escape` against `r`, with actual units and captured conditions.
5. **Explain why escape does not require the force of gravity to become zero.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Kepler’s Laws — `s06-e05`

1. **Start with a circular Kepler orbit** — Preview `e = 0` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare orbital sizes** — Preview `a` at 3 and 6 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Read period and swept-area evidence** — Focused, live source quantities: `period,area,angularMomentum`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a semimajor-axis period record** — Build an explicit-snapshot scatter plot of `period` against `a`, with actual units and captured conditions.
5. **Explain why equal areas in equal times do not imply equal speed everywhere.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

## Oscillations

### Spring SHM — `s07-e00`

1. **Stiffen the SHM spring** — Preview `k = 40` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare oscillator masses** — Preview `m` at .5 and 2 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Distinguish period from amplitude** — Focused, live source quantities: `period,frequency,x`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a mass-period study** — Build an explicit-snapshot scatter plot of `period` against `m`, with actual units and captured conditions.
5. **Explain why period depends on mass and stiffness in linear SHM.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Pendulum — `s07-e01`

1. **Start with a small pendulum angle** — Preview `angle = 5` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare pendulum lengths** — Preview `length` at .5 and 1.5 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Compare nonlinear and small-angle periods** — Focused, live source quantities: `period,smallPeriod,angle`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a pendulum length-period record** — Build an explicit-snapshot scatter plot of `period` against `length`, with actual units and captured conditions.
5. **Explain why the small-angle period is an approximation at large amplitudes.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Energy Exchange — `s07-e02`

1. **Add an initial kinetic contribution** — Preview `v0 = .3` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare oscillator energy budgets** — Preview `x0` at .08 and .16 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Follow the potential-kinetic exchange** — Focused, live source quantities: `K,U,total`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build an amplitude-energy relation** — Build an explicit-snapshot scatter plot of `total` against `x0`, with actual units and captured conditions.
5. **Explain why zero displacement does not imply zero oscillator energy.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Damping — `s07-e03`

1. **Remove damping for a reference run** — Preview `b = 0` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare underdamped and overdamped response** — Preview `b` at 2 and 12 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Read damping against the critical value** — Focused, live source quantities: `critical,envelope,K,total`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Capture equal-time damping displacements** — Build an explicit-snapshot scatter plot of `x` against `b`, with actual units and captured conditions.
5. **Explain why stronger damping does not always mean a faster return without oscillation.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Resonance — `s07-e04`

1. **Tune near the default natural frequency** — Preview `omega = 4.4721` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare detuned driving frequencies** — Preview `omega` at 2 and 6 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Separate natural frequency and response peak** — Focused, live source quantities: `naturalOmega,peakOmega,steadyAmplitude`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a driven-response sample plot** — Build an explicit-snapshot scatter plot of `steadyAmplitude` against `omega`, with actual units and captured conditions.
5. **Explain why damping changes the resonance peak and its height.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Coupled Oscillators — `s07-e05`

1. **Decouple the two oscillators** — Preview `kc = 0` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare uncoupled and coupled motion** — Preview `kc` at 0 and 4 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Read the two normal-mode frequencies** — Focused, live source quantities: `lowFrequency,highFrequency,total`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a coupling-mode-frequency study** — Build an explicit-snapshot scatter plot of `highFrequency` against `kc`, with actual units and captured conditions.
5. **Explain how coupling transfers local energy while preserving the ideal total.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Torsional Pendulum — `s07-e06`

1. **Increase rotational inertia fourfold** — Preview `inertia = .08` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare soft and stiff torsion fibres** — Preview `torsion` at .05 and .2 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Separate angular amplitude and period** — Focused, live source quantities: `period,angle,energy`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a torsional-inertia period record** — Build an explicit-snapshot scatter plot of `period` against `inertia`, with actual units and captured conditions.
5. **Explain why angular amplitude does not set the ideal linear torsional period.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

## Waves & Sound

### Wave Properties — `s08-e00`

1. **Move the local wave probe** — Preview `probe = 1` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare frequency at fixed wavelength** — Preview `frequency` at 1 and 4 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Separate propagation and local displacement** — Focused, live source quantities: `waveSpeed,wavelength,sum`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a frequency-phase-speed record** — Build an explicit-snapshot scatter plot of `waveSpeed` against `frequency`, with actual units and captured conditions.
5. **Explain which wave quantities change when frequency changes at fixed wavelength.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Superposition — `s08-e01`

1. **Make both pulse amplitudes positive** — Preview `a2 = .025` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare cancellation and reinforcement** — Preview `a2` at -.025 and .025 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Read components before their algebraic sum** — Focused, live source quantities: `first,second,sum`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Capture superposition at a fixed probe and time** — Build an explicit-snapshot scatter plot of `sum` against `a2`, with actual units and captured conditions.
5. **Explain why superposition applies to signed displacement, not the sum of magnitudes.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Interference — `s08-e02`

1. **Reverse one source phase** — Preview `phase = 3.141592653589793` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare coherent phase conditions** — Preview `phase` at 0 and 3.141592653589793 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Link path difference to local interference** — Focused, live source quantities: `pathDifference,phaseDifference,intensity`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a source-phase intensity record** — Build an explicit-snapshot scatter plot of `intensity` against `phase`, with actual units and captured conditions.
5. **Explain why a dark location can move when the source phase changes.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Standing Waves — `s08-e03`

1. **Select the fundamental mode** — Preview `harmonic = 1` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare fundamental and third harmonic** — Preview `harmonic` at 1 and 3 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Count endpoint nodes correctly** — Focused, live source quantities: `frequency,wavelength,nodeCount`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a string-mode frequency ladder** — Build an explicit-snapshot scatter plot of `frequency` against `harmonic`, with actual units and captured conditions.
5. **Explain why a higher harmonic has more nodes and a shorter wavelength.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Sound Spectrum — `s08-e04`

1. **Move the generated tone by one FFT bin** — Preview `frequency = 448` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare spectral amplitudes at equal frequency** — Preview `amplitude` at .2 and .6 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Read bin spacing before claiming precision** — Focused, live source quantities: `peakFrequency,binWidth,nyquist`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Compare requested tones with detected FFT bins** — Build an explicit-snapshot scatter plot of `peakFrequency` against `frequency`, with actual units and captured conditions.
5. **Explain why the strongest FFT bin need not equal the exact tone frequency.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Doppler Effect — `s08-e05`

1. **Establish a stationary-source reference** — Preview `mach = 0` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare recession and approach** — Preview `mach` at -.2 and .2 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Separate emission time from reception state** — Focused, live source quantities: `observedFrequency,sourceSpeed,emissionTime`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a signed Doppler response** — Build an explicit-snapshot scatter plot of `observedFrequency` against `mach`, with actual units and captured conditions.
5. **Explain why source motion changes received frequency without changing emitted frequency.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Beats — `s08-e06`

1. **Inspect zero frequency separation** — Preview `difference = 0` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare slow and fast envelopes** — Preview `difference` at 2 and 6 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Separate carrier pressure and beat envelope** — Focused, live source quantities: `frequency,envelope,pressure`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a beat-rate frequency-difference plot** — Build an explicit-snapshot scatter plot of `frequency` against `difference`, with actual units and captured conditions.
5. **Explain why the envelope repetition rate is the frequency difference.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

## Optics

### Reflection — `s09-e00`

1. **Start with normal incidence** — Preview `angle = 0` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare two reflected directions** — Preview `angle` at 20 and 60 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Measure angles from the normal** — Focused, live source quantities: `incidentAngle,reflectedAngle`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Construct the reflection-angle relation** — Build an explicit-snapshot scatter plot of `reflectedAngle` against `angle`, with actual units and captured conditions.
5. **Explain why an angle measured from the surface gives a different number.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Refraction — `s09-e01`

1. **Match the two refractive indices** — Preview `n2 = 1` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare incidence angles at fixed indices** — Preview `angle` at 20 and 60 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Keep refraction and internal reflection distinct** — Focused, live source quantities: `incidentAngle,transmittedAngle,criticalAngle,tir`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a Snell-angle observation plot** — Build an explicit-snapshot scatter plot of `transmittedAngle` against `angle`, with actual units and captured conditions.
5. **Explain when a critical angle exists and why it cannot be assumed for every interface.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Lenses — `s09-e02`

1. **Place the object at the default focal plane** — Preview `u = .1` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare inside-focus and outside-focus images** — Preview `u` at .08 and .3 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Read real, virtual and infinite-image cases** — Focused, live source quantities: `imageDistance,magnification,imageVergence`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Plot object distance against image vergence** — Build an explicit-snapshot scatter plot of `imageVergence` against `u`, with actual units and captured conditions.
5. **Explain why an image at infinity is not a missing finite image on the screen.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Mirrors — `s09-e03`

1. **Place the object at the mirror focal plane** — Preview `u = .15` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare two mirror object distances** — Preview `u` at .1 and .45 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Keep image signs and orientation visible** — Focused, live source quantities: `imageDistance,magnification,imageVergence`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a mirror conjugate-position study** — Build an explicit-snapshot scatter plot of `imageVergence` against `u`, with actual units and captured conditions.
5. **Explain why image sign conventions matter when describing virtual images.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Interference — `s09-e04`

1. **Try a shorter optical wavelength** — Preview `wavelength = 4.5e-7` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare fringe spacing at two screens** — Preview `screen` at .5 and 2 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Separate fringe spacing from local intensity** — Focused, live source quantities: `spacing,intensity`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a wavelength-fringe-spacing record** — Build an explicit-snapshot scatter plot of `spacing` against `wavelength`, with actual units and captured conditions.
5. **Explain why changing wavelength changes fringe spacing without changing slit separation.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Diffraction — `s09-e05`

1. **Narrow the single slit** — Preview `aperture = .00005` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare narrow and wide central maxima** — Preview `aperture` at .00005 and .00015 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Check far-field validity beside width** — Focused, live source quantities: `centralWidth,intensity,fresnelNumber`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build an aperture-central-width relation** — Build an explicit-snapshot scatter plot of `centralWidth` against `aperture`, with actual units and captured conditions.
5. **Explain why a narrower slit produces a wider diffraction maximum.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Polarization — `s09-e06`

1. **Cross the analyzer and polarizer** — Preview `angle = 90` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare aligned and diagonal transmission** — Preview `angle` at 0 and 45 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Keep the first-polarizer half factor visible** — Focused, live source quantities: `intensity,transmission`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Construct a Malus-law intensity record** — Build an explicit-snapshot scatter plot of `intensity` against `angle`, with actual units and captured conditions.
5. **Explain why unpolarized input loses half its intensity before the analyzer.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

## Electricity

### Coulomb Force — `s10-e00`

1. **Change attraction into repulsion** — Preview `q2 = 2e-6` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare centre separations** — Preview `distance` at .2 and .4 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Keep charge signs separate from force magnitude** — Focused, live source quantities: `force`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a Coulomb inverse-square record** — Build an explicit-snapshot scatter plot of `force` against `distance`, with actual units and captured conditions.
5. **Explain how charge sign and separation affect different aspects of the force.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Electric Field — `s10-e01`

1. **Reverse the test-charge sign** — Preview `testCharge = -1e-9` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare source polarities** — Preview `q1` at -5e-9 and 5e-9 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Read field independently of the test charge** — Focused, live source quantities: `field,ex,ey`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a probe-position field study** — Build an explicit-snapshot scatter plot of `field` against `probeX`, with actual units and captured conditions.
5. **Explain why changing the test charge changes force but not the source field.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Electric Potential — `s10-e02`

1. **Move toward the dipole symmetry line** — Preview `probeX = 0` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare potential sign contributions** — Preview `q1` at -5e-9 and 5e-9 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Separate scalar potential from vector field** — Focused, live source quantities: `potential,field`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a potential profile from probe snapshots** — Build an explicit-snapshot scatter plot of `potential` against `probeX`, with actual units and captured conditions.
5. **Explain why zero potential does not necessarily mean zero electric field.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Current — `s10-e03`

1. **Open the DC circuit** — Preview `closed = 0` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare reversed source polarities** — Preview `voltage` at -6 and 6 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Distinguish current direction and heating** — Focused, live source quantities: `current,drift,power`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a signed current-voltage relation** — Build an explicit-snapshot scatter plot of `current` against `voltage`, with actual units and captured conditions.
5. **Explain why reversing current does not reverse resistive heating.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Circuits — `s10-e04`

1. **Edit the selected circuit component precisely** — Preview `component = 20` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare two selected-component values** — Preview `component` at 10 and 30 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Inspect circuit conservation residuals** — Focused, live source quantities: `current,kclResidual,powerResidual`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a selected-component response record** — Build an explicit-snapshot scatter plot of `current` against `component`, with actual units and captured conditions.
5. **Explain why a component effect depends on its actual terminal connections.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Capacitors — `s10-e05`

1. **Insert a higher-permittivity dielectric** — Preview `epsilonR = 3` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare plate gaps** — Preview `gap` at .0005 and .0015 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Separate stored charge and stored energy** — Focused, live source quantities: `capacitance,charge,energy`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a plate-gap capacitance study** — Build an explicit-snapshot scatter plot of `capacitance` against `gap`, with actual units and captured conditions.
5. **Explain why connected and isolated capacitors obey different constraints.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Wire Resistivity — `s10-e06`

1. **Double the conductor radius** — Preview `radius = .001` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare uniform-wire lengths** — Preview `length` at 1 and 4 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Link geometry to resistance and heating** — Focused, live source quantities: `resistance,voltage,power`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build an inverse-area resistivity study** — Build an explicit-snapshot scatter plot of `resistance` against `radius`, with actual units and captured conditions.
5. **Explain why doubling wire radius changes resistance by a factor of four.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Wheatstone Bridge — `s10-e07`

1. **Return the default bridge to its null** — Preview `unknown = 300` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare either side of bridge balance** — Preview `unknown` at 150 and 600 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Show both divider midpoints at once** — Focused, live source quantities: `leftVoltage,rightVoltage,voltage`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a signed bridge-null plot** — Build an explicit-snapshot scatter plot of `voltage` against `unknown`, with actual units and captured conditions.
5. **Explain why a zero detector voltage does not mean all branch currents vanish.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### AC RLC Circuits — `s10-e08`

1. **Tune near the default RLC resonance** — Preview `frequency = 50.3292` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare capacitive and inductive sides** — Preview `frequency` at 20 and 100 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Read phase and impedance beside current** — Focused, live source quantities: `rmsCurrent,phase,impedance`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a sampled AC resonance response** — Build an explicit-snapshot scatter plot of `rmsCurrent` against `frequency`, with actual units and captured conditions.
5. **Explain why resonance is reactance cancellation rather than zero total impedance.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

## Magnetism

### Field Lines — `s11-e00`

1. **Reverse the dipole polarity** — Preview `moment = -.15` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare exterior field positions** — Preview `probeX` at .12 and .24 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Keep field direction distinct from magnitude** — Focused, live source quantities: `field,bx,by`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a dipole probe-field record** — Build an explicit-snapshot scatter plot of `field` against `probeX`, with actual units and captured conditions.
5. **Explain why field-line density is a drawing convention rather than a count of physical wires.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Lorentz Force — `s11-e01`

1. **Reverse the particle charge** — Preview `charge = -1.602176634e-19` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare opposite magnetic fields** — Preview `field` at -.02 and .02 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Separate curvature and parallel motion** — Focused, live source quantities: `force,radius,speed`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a magnetic-force field study** — Build an explicit-snapshot scatter plot of `force` against `field`, with actual units and captured conditions.
5. **Explain why a magnetic force bends motion without doing work on the particle.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Current-Carrying Wire — `s11-e02`

1. **Reverse wire-current direction** — Preview `current = -5` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare current magnitudes** — Preview `current` at 2 and 6 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Read azimuthal field components** — Focused, live source quantities: `field,bx,by`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a straight-wire current-field record** — Build an explicit-snapshot scatter plot of `field` against `current`, with actual units and captured conditions.
5. **Explain how the right-hand rule changes when current reverses.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Solenoids — `s11-e03`

1. **Move the probe beyond the solenoid centre** — Preview `probe = .15` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare short and long coils** — Preview `length` at .1 and .3 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Compare finite-coil and long-coil estimates** — Focused, live source quantities: `field`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build an axial solenoid field profile** — Build an explicit-snapshot scatter plot of `field` against `probe`, with actual units and captured conditions.
5. **Explain why the long-solenoid approximation can fail near an end.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Induction — `s11-e04`

1. **Reverse magnet motion through the loop** — Preview `velocity = -.12` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare opposite source positions** — Preview `initialZ` at -.15 and .15 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Keep flux, EMF and current separate** — Focused, live source quantities: `flux,emf,current`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a position-induced-EMF record** — Build an explicit-snapshot scatter plot of `emf` against `initialZ`, with actual units and captured conditions.
5. **Explain why an open coil can have EMF without a conducting-loop current.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Electromagnets — `s11-e05`

1. **Increase the magnetic air gap** — Preview `gap = .01` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare electromagnet drive currents** — Preview `current` at .25 and 1 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Compare ideal attraction with load weight** — Focused, live source quantities: `field,force,weight`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build an air-gap attraction study** — Build an explicit-snapshot scatter plot of `force` against `gap`, with actual units and captured conditions.
5. **Explain why core permeability alone cannot remove the reluctance of a large air gap.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Transformer — `s11-e06`

1. **Try equal primary and secondary turns** — Preview `secondary = 500` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare step-down and step-up ratios** — Preview `secondary` at 500 and 1500 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Read ideal transformer power balance** — Focused, live source quantities: `rmsVoltage,primaryCurrent,secondaryCurrent,power`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a turns-ratio voltage record** — Build an explicit-snapshot scatter plot of `rmsVoltage` against `secondary`, with actual units and captured conditions.
5. **Explain why stepping up voltage does not create extra power.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

## Electronics

### Semiconductors — `s12-e00`

1. **Warm the intrinsic semiconductor** — Preview `temperature = 350` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare thermal carrier populations** — Preview `temperature` at 280 and 360 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Keep electrons and holes distinct** — Focused, live source quantities: `conductivity,electrons,holes`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a conductivity-temperature record** — Build an explicit-snapshot scatter plot of `conductivity` against `temperature`, with actual units and captured conditions.
5. **Explain why intrinsic conduction involves both electrons and holes.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Diodes — `s12-e01`

1. **Reverse-bias the series diode** — Preview `supply = -1` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare two forward-drive voltages** — Preview `supply` at .4 and 1.2 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Separate junction voltage and resistor drop** — Focused, live source quantities: `current,diodeVoltage,diodePower`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a source-voltage diode response** — Build an explicit-snapshot scatter plot of `current` against `supply`, with actual units and captured conditions.
5. **Explain why the series resistor and source voltage matter beyond an ideal diode threshold.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Transistors — `s12-e02`

1. **Move the transistor toward cutoff** — Preview `drive = 0` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare active and saturation drive** — Preview `drive` at .8 and 2 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Read transistor operating-region evidence** — Focused, live source quantities: `collectorCurrent,baseCurrent,vce`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a base-drive output response** — Build an explicit-snapshot scatter plot of `collectorCurrent` against `drive`, with actual units and captured conditions.
5. **Explain why collector current cannot rise indefinitely as beta times base current.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Amplifiers — `s12-e03`

1. **Drive the amplifier toward clipping** — Preview `amplitude = 1` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare closed-loop gain settings** — Preview `feedback` at 5000 and 20000 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Keep gain, rails and clipping together** — Focused, live source quantities: `gain,inputVoltage,outputVoltage`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a feedback-resistance gain record** — Build an explicit-snapshot scatter plot of `gain` against `feedback`, with actual units and captured conditions.
5. **Explain why a mathematical gain does not guarantee an unclipped output swing.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Logic Gates — `s12-e04`

1. **Toggle the first binary input** — Preview `inputA = 1` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare second-input truth-table rows** — Preview `inputB` at 0 and 1 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Read the selected gate as a binary rule** — Focused, live source quantities: `logicOutput`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Capture discrete truth-table points** — Build an explicit-snapshot scatter plot of `logicOutput` against `inputA`, with actual units and captured conditions.
5. **Explain why the selected logical operation must be stated with its input values.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Sensors — `s12-e05`

1. **Choose an input inside calibration range** — Preview `temperature = 310` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare two calibrated sensor inputs** — Preview `temperature` at 280 and 320 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Read physical input separately from voltage output** — Focused, live source quantities: `sensorOutput`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a temperature-sensor transfer record** — Build an explicit-snapshot scatter plot of `sensorOutput` against `temperature`, with actual units and captured conditions.
5. **Explain why sensor voltage is not itself a temperature without calibration.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Full-wave Rectifier — `s12-e06`

1. **Change the input AC frequency** — Preview `frequency = 60` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare two rectified amplitudes** — Preview `supply` at 6 and 18 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Keep mean voltage and ripple distinct** — Focused, live source quantities: `averageVoltage,rippleFrequency,rippleFactor`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build an RMS-input to mean-output record** — Build an explicit-snapshot scatter plot of `averageVoltage` against `supply`, with actual units and captured conditions.
5. **Explain why full-wave rectification doubles ripple frequency without smoothing it away.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

## Thermodynamics

### Temperature — `s13-e00`

1. **Use a faster thermal probe** — Preview `probeTau = 1` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare sensor response times** — Preview `probeTau` at 1 and 10 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Separate sample temperature from probe indication** — Focused, live source quantities: `probeTemperature,sampleTemperature`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Capture equal-time thermometer lag** — Build an explicit-snapshot scatter plot of `probeTemperature` against `probeTau`, with actual units and captured conditions.
5. **Explain why an initially cold probe does not instantly show the sample temperature.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Heat Transfer — `s13-e01`

1. **Double the conducting-rod length** — Preview `length = .4` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare prescribed conductivities** — Preview `conductivity` at 20 and 205 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Keep temperature gradient and heat rate distinct** — Focused, live source quantities: `heatRate,gradient`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a rod-length heat-flow record** — Build an explicit-snapshot scatter plot of `heatRate` against `length`, with actual units and captured conditions.
5. **Explain why equal end temperatures produce no net conductive heat flow.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Gas Laws — `s13-e02`

1. **Plan an isothermal volume doubling** — Preview `volumeRatio = 2` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare initial gas volumes** — Preview `initialVolume` at .002 and .004 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Read pressure with the process constraints** — Focused, live source quantities: `pressure,volume,temperature`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Capture final-pressure volume-ratio samples** — Build an explicit-snapshot scatter plot of `pressure` against `volumeRatio`, with actual units and captured conditions.
5. **Explain why Boyle's law requires a constant temperature and fixed amount of gas.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### First Law — `s13-e03`

1. **Plan a zero-temperature-change process** — Preview `temperatureRatio = 1` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare cooling and heating endpoints** — Preview `temperatureRatio` at .8 and 1.2 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Read the signed first-law ledger** — Focused, live source quantities: `deltaU,heat,work`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Capture internal energy at a common process stage** — Build an explicit-snapshot scatter plot of `deltaU` against `temperatureRatio`, with actual units and captured conditions.
5. **Explain why heat supplied and internal-energy increase need not be equal when work is done.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Entropy — `s13-e04`

1. **Remove the volume-change contribution** — Preview `volumeRatio = 1` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare endpoint-temperature changes** — Preview `finalT` at 280 and 360 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Keep endpoint entropy and energy distinct** — Focused, live source quantities: `entropy,deltaU`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a final-temperature entropy study** — Build an explicit-snapshot scatter plot of `entropy` against `finalT`, with actual units and captured conditions.
5. **Explain why a reversible reference calculation does not make an irreversible process reversible.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Heat Engines — `s13-e05`

1. **Lower the cold reservoir temperature** — Preview `coldT = 250` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare hot-reservoir settings** — Preview `hotT` at 450 and 600 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Read efficiency alongside reservoir constraints** — Focused, live source quantities: `efficiency,hotHeatReference,coldHeatReference,work`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a cold-temperature efficiency record** — Build an explicit-snapshot scatter plot of `efficiency` against `coldT`, with actual units and captured conditions.
5. **Explain why absolute temperature must be used in a Carnot efficiency ratio.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Calorimetry — `s13-e06`

1. **Remove the calorimeter heat capacity** — Preview `calorimeter = 0` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare hot-body masses** — Preview `hotMass` at .1 and .4 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Close the signed calorimetry heat balance** — Focused, live source quantities: `temperature,hotHeat,coldHeat,calorimeterHeat`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build an equilibrium mixing-temperature study** — Build an explicit-snapshot scatter plot of `temperature` against `hotMass`, with actual units and captured conditions.
5. **Explain why ignoring the initially cold calorimeter can overestimate the final temperature.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Heating Curve & Latent Heat — `s13-e07`

1. **Double the heater power** — Preview `power = 1000` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare heating two ice masses** — Preview `mass` at .1 and .4 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Read phase fractions beside temperature** — Focused, live source quantities: `temperature,meltFraction,vapourFraction,energy`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Capture equal-time heater-power samples** — Build an explicit-snapshot scatter plot of `temperature` against `power`, with actual units and captured conditions.
5. **Explain why energy continues increasing during a constant-temperature phase change.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Thermal Expansion — `s13-e08`

1. **Establish an unheated rod reference** — Preview `temperatureChange = 0` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare original rod lengths** — Preview `length` at .5 and 1.5 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Separate original length, extension and strain** — Focused, live source quantities: `length,finalLength,strain`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a temperature-rise extension record** — Build an explicit-snapshot scatter plot of `length` against `temperatureChange`, with actual units and captured conditions.
5. **Explain why free thermal expansion is not a direct measurement of thermal stress.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

## Fluid Mechanics

### Density & Pressure — `s14-e00`

1. **Move the pressure probe to the surface** — Preview `depth = 0` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare liquid densities** — Preview `density` at 700 and 1200 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Keep gauge and absolute pressures separate** — Focused, live source quantities: `gaugePressure,absolutePressure`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a depth-gauge-pressure record** — Build an explicit-snapshot scatter plot of `gaugePressure` against `depth`, with actual units and captured conditions.
5. **Explain why zero gauge pressure does not usually mean a vacuum.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Hydrostatics — `s14-e01`

1. **Balance the manometer pressures** — Preview `deltaPressure = 0` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare opposite pressure differences** — Preview `deltaPressure` at -980.665 and 980.665 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Read level difference with its sign** — Focused, live source quantities: `heightDifference,leftLevel,rightLevel`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a signed manometer response** — Build an explicit-snapshot scatter plot of `heightDifference` against `deltaPressure`, with actual units and captured conditions.
5. **Explain why unequal tube areas affect level movements but not the hydrostatic head relation.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Buoyancy — `s14-e02`

1. **Approach neutral density matching** — Preview `objectDensity = 1000` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare floating and sinking tendencies** — Preview `objectDensity` at 500 and 1500 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Separate buoyancy from displacement geometry** — Focused, live source quantities: `buoyantForce,weight,displacedVolume`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Capture buoyancy at matching equilibrium stages** — Build an explicit-snapshot scatter plot of `buoyantForce` against `objectDensity`, with actual units and captured conditions.
5. **Explain why buoyant force depends on displaced fluid rather than object density alone.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Continuity — `s14-e03`

1. **Match inlet and outlet radii** — Preview `radius2 = .015` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare constrictions and expansions** — Preview `radius2` at .006 and .018 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Keep volume flow and local speed distinct** — Focused, live source quantities: `speed,flowRate,area`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a probe-based continuity record** — Build an explicit-snapshot scatter plot of `speed` against `radius2`, with actual units and captured conditions.
5. **Explain why radius changes flow speed through area squared, not radius alone.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Bernoulli — `s14-e04`

1. **Raise the Bernoulli outlet** — Preview `elevation = .03` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare outlet cross sections** — Preview `radius2` at .006 and .018 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Read pressure alongside speed and height** — Focused, live source quantities: `pressure,speed,probeHead`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Capture flow-rate pressure responses at one probe** — Build an explicit-snapshot scatter plot of `pressure` against `flow`, with actual units and captured conditions.
5. **Explain why the simple Bernoulli relation requires its stated loss and phase assumptions.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Viscosity — `s14-e05`

1. **Use a more viscous liquid** — Preview `viscosity = 2` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare two falling-sphere radii** — Preview `radius` at .00025 and .0005 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Check low-Reynolds-number evidence** — Focused, live source quantities: `terminalSpeed,reynolds,drag`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build an inverse-viscosity terminal-speed study** — Build an explicit-snapshot scatter plot of `terminalSpeed` against `viscosity`, with actual units and captured conditions.
5. **Explain why Stokes drag cannot be extended to every falling-sphere speed.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Capillary Rise — `s14-e06`

1. **Try a right-angle wetting boundary** — Preview `angle = 90` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare capillary rise and depression** — Preview `angle` at 20 and 120 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Keep signed height relative to the reservoir** — Focused, live source quantities: `length`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a tube-radius capillary-height record** — Build an explicit-snapshot scatter plot of `length` against `radius`, with actual units and captured conditions.
5. **Explain why a nonwetting liquid can sit lower inside a narrow capillary.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

## Modern Physics

### Quantum Ideas — `s15-e00`

1. **Select the ground-state well level** — Preview `n = 1` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare confinement widths** — Preview `wellWidth` at 8e-10 and 1.6e-9 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Keep energy and detection probability distinct** — Focused, live source quantities: `energy,normalization`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a well-width energy record** — Build an explicit-snapshot scatter plot of `energy` against `wellWidth`, with actual units and captured conditions.
5. **Explain why a stationary quantum state is not a particle following a classical orbit.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Photoelectric Effect — `s15-e01`

1. **Probe below the default photoemission threshold** — Preview `wavelength = 7e-7` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare brightness at fixed photon energy** — Preview `intensity` at 5 and 20 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Separate photon threshold and emitted current** — Focused, live source quantities: `current,maximumKineticEnergy,stoppingPotential`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a wavelength-photocurrent record** — Build an explicit-snapshot scatter plot of `current` against `wavelength`, with actual units and captured conditions.
5. **Explain why more sub-threshold photons do not release electrons in this model.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Matter Waves — `s15-e02`

1. **Reduce electron acceleration voltage** — Preview `voltage = 25` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare matter wavelengths** — Preview `voltage` at 25 and 100 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Link de Broglie wavelength to diffraction scale** — Focused, live source quantities: `wavelength,fringeSpacing`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build an electron-voltage wavelength record** — Build an explicit-snapshot scatter plot of `wavelength` against `voltage`, with actual units and captured conditions.
5. **Explain why individual detections do not imply a classical path through both slits.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Atomic Spectra — `s15-e03`

1. **Choose a lower excited hydrogen level** — Preview `upper = 3` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare two upper-state transitions** — Preview `upper` at 3 and 6 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Pair transition energy with wavelength** — Focused, live source quantities: `wavelength,photonEnergy`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build the selected-series wavelength ladder** — Build an explicit-snapshot scatter plot of `wavelength` against `upper`, with actual units and captured conditions.
5. **Explain why the final energy level must be specified as well as the upper level.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Nuclear Structure — `s15-e04`

1. **Rotate the nuclear structure for inspection** — Preview `azimuth = 1.2` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare selected nuclides without altering them** — Choose two nuclides in the actual source selector and capture their calculated states.
3. **Separate total and per-nucleon binding** — Focused, live source quantities: `protons,neutrons,bindingEnergy,bindingPerNucleon`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Verify binding invariance under view rotation** — Build an explicit-snapshot scatter plot of `bindingPerNucleon` against `azimuth`, with actual units and captured conditions.
5. **Explain why changing a camera angle cannot change nuclear binding energy.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Radioactivity — `s15-e05`

1. **Try an ideal detector efficiency** — Preview `efficiency = 1` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare counts with the same decay model** — Preview `efficiency` at .25 and .75 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Separate activity, detection and background** — Focused, live source quantities: `expectedActivity,remaining,expectedDetected`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Audit activity against detector efficiency** — Build an explicit-snapshot scatter plot of `expectedActivity` against `efficiency`, with actual units and captured conditions.
5. **Explain why lower measured counts do not necessarily mean a longer half-life.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Rutherford Scattering — `s15-e06`

1. **Inspect a head-on alpha encounter** — Preview `impact = 0` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare small and large impact parameters** — Preview `impact` at 20 and 80 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Separate deflection and closest approach** — Focused, live source quantities: `angle,closestApproach`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a Rutherford impact-parameter response** — Build an explicit-snapshot scatter plot of `angle` against `impact`, with actual units and captured conditions.
5. **Explain why the displayed asymptotes are not an integrated nuclear trajectory.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Time Dilation & Length Contraction — `s15-e07`

1. **Establish zero relative speed** — Preview `beta = 0` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare two relativistic speeds** — Preview `beta` at .6 and .8 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Read dilation and contraction together** — Focused, live source quantities: `gamma,time,length`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a speed-observed-time record** — Build an explicit-snapshot scatter plot of `time` against `beta`, with actual units and captured conditions.
5. **Explain why proper time and simultaneous length endpoints refer to different measurement conditions.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

## Astronomy & Astrophysics

### Solar System Orbits — `s16-e00`

1. **Advance the frozen-element orbital epoch** — Preview `elapsedDays = 365.25` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare half-year-separated positions** — Preview `elapsedDays` at 0 and 182.625 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Separate playback time from physical epoch** — Focused, live source quantities: `distance,speed,period`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a planet-distance orbital record** — Build an explicit-snapshot scatter plot of `distance` against `elapsedDays`, with actual units and captured conditions.
5. **Explain why the frozen-element model is not a full present-day ephemeris.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Stellar Life — `s16-e01`

1. **Move along the selected stellar track** — Preview `ageFraction = .7` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare two actual track locations** — Preview `ageFraction` at .2 and .8 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Read sourced stellar properties together** — Focused, live source quantities: `luminosity,temperature,radius`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a selected-track luminosity record** — Build an explicit-snapshot scatter plot of `luminosity` against `ageFraction`, with actual units and captured conditions.
5. **Explain why an age fraction is relative to the selected stored track, not a universal stellar clock.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Spectroscopy — `s16-e02`

1. **Redshift the synthetic stellar spectrum** — Preview `velocity = 300000` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare instrument resolving powers** — Preview `resolution` at 500 and 10000 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Separate continuum temperature and line displacement** — Focused, live source quantities: `peakWavelength,radialVelocity,dopplerFactor`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a continuum-temperature peak record** — Build an explicit-snapshot scatter plot of `peakWavelength` against `temperature`, with actual units and captured conditions.
5. **Explain why line shift and line broadening carry different information.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Galaxies — `s16-e03`

1. **Remove the illustrative halo contribution** — Preview `haloSpeed = 0` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare baryonic and halo-supported rotation** — Preview `haloSpeed` at 0 and 200000 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Separate the rotation contributions** — Focused, live source quantities: `speed,diskSpeed,haloSpeed`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a sampled galactic rotation curve** — Build an explicit-snapshot scatter plot of `speed` against `radiusKpc`, with actual units and captured conditions.
5. **Explain why a fitted halo contribution is a model inference rather than a directly photographed component.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Cosmology — `s16-e04`

1. **Start at zero cosmological redshift** — Preview `redshift = 0` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare hypothetical expansion scales** — Preview `h0` at 60 and 80 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Keep distance definitions separate** — Focused, live source quantities: `comovingDistance,luminosityDistance,angularDistance`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a flat-FLRW redshift-distance record** — Build an explicit-snapshot scatter plot of `comovingDistance` against `redshift`, with actual units and captured conditions.
5. **Explain why light-travel, luminosity and comoving distances need not be equal.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Exoplanets — `s16-e05`

1. **Centre the transit observation** — Preview `phase = 0` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare planet-to-star radius ratios** — Preview `radiusRatio` at .05 and .15 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Read transit depth alongside chord geometry** — Focused, live source quantities: `midDepth,flux,projectedSeparation`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build a radius-ratio transit-depth record** — Build an explicit-snapshot scatter plot of `midDepth` against `radiusRatio`, with actual units and captured conditions.
5. **Explain why grazing overlap can invalidate the simple full-transit depth estimate.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.

### Stellar Parallax — `s16-e06`

1. **Double the orbital-radius baseline** — Preview `baseline = 2` in its actual displayed unit, apply through the source control and undo the setup change.
2. **Compare nearby-star distances** — Preview `distance` at 10 and 20 in the source control’s displayed units; explicitly capture A and B, then inspect signed differences.
3. **Separate half-angle parallax and full shift** — Focused, live source quantities: `parallax,fullShift`. Undefined or not-yet-measured quantities remain explicitly unavailable.
4. **Build an inverse-distance parallax record** — Build an explicit-snapshot scatter plot of `parallax` against `distance`, with actual units and captured conditions.
5. **Explain why the full six-month angular shift is twice the quoted parallax angle.** — Write a claim, reasoning and next question; attach captured evidence, save locally and reopen directly from Saved.
