# Ten priority studios and ten implemented UX enhancements

Version 1.18.0+21. This is a subjective introductory-learning ranking based on prerequisites, breadth and connections between topics, not popularity or an externally published league table. Foundational coverage is informed by [OpenStax University Physics](https://openstax.org/books/university-physics-volume-1/pages/index). Prediction, manipulation and immediate explanatory feedback follow the exploration principles described by [PhET](https://phet.colorado.edu/en/about).

## Audit and implementation

The existing 17 studio pages already provided artwork, descriptions, lab grids, search, Saved/Completed filters, a guide, bottom navigation and ten curated studio tools. Those tools launch individual-lab investigations. This change adds a studio-level conceptual activity that connects two labs before the learner enters either apparatus.

Open the **Try:** button at the top of each selected studio. There are **ten new enhancements total, one distinct activity per ranked studio**:

1. **Measurement (`s01`) — Choose the right resolution.** Measurement supports meaningful observations everywhere else. Drag instrument division size, vary a target gap, predict whether it spans one division and inspect the resolution ratio and quantization uncertainty. Continue in Vernier Caliper and Uncertainty.
2. **Mechanics (`s02`) — Balance the lever.** Equilibrium connects geometry, force and engineering. Move the right attachment and vary the left mass, compare force arrows, predict the initial turning direction, then reveal both torques. Continue in Torque Levers and Equilibrium & Centre of Mass.
3. **Motion & Kinematics (`s03`) — Scrub motion, read its direction.** Graph literacy is a prerequisite for interpreting dynamics. Scrub time and vary acceleration; position, the graph marker and its local tangent move together. Predict direction from velocity rather than position. Continue in Position–Time and Velocity–Time.
4. **Force & Newton’s Laws (`s04`) — Combine opposing forces.** Net force links interactions to motion. Manipulate two opposing arrows on the same scale, predict acceleration direction, then reveal net force and acceleration for the 2 kg body. Continue in Second Law / F = ma and Multi-Force Challenge.
5. **Work, Energy & Power (`s05`) — Follow the energy budget.** Energy connects multiple branches of physics. Adjust drop height and retained fraction, inspect a kinetic/dissipated budget, predict the larger share, then reveal energy and speed. Continue in Kinetic Energy and Energy Conservation.
6. **Electricity (`s10`) — Compare circuit connections.** Circuit reasoning underlies electrical technology. Switch a working two-resistor preview between series and parallel, change resistance values, predict which component dissipates more power and inspect solver-derived powers/current. Continue in Wire Resistivity and Circuits.
7. **Waves & Sound (`s08`) — Connect frequency and wavelength.** Wave concepts connect acoustics, light and signals. Manipulate frequency/wavelength, scrub preview time, predict speed relative to a labeled 0.8 m/s reference and inspect speed/period. Continue in Wave Properties and Standing Waves.
8. **Thermodynamics (`s13`) — Compare two conduction rods.** Thermal reasoning connects energy to materials and heat transfer. Adjust one rod's length/conductivity against a fixed reference, predict which carries more heat per second and reveal both steady heat rates. Continue in Heat Transfer and Calorimetry.
9. **Optics (`s09`) — Move the object, classify the image.** Optics connects geometry with vision and instruments. Drag object distance, vary focal length, select converging/diverging, predict real/virtual/infinite images and reveal rays, signed distance and magnification. Continue in Lenses and Mirrors.
10. **Magnetism (`s11`) — Rotate a loop through the field.** Flux connects field geometry to electromagnetic induction. Rotate the chosen loop normal by dragging, change uniform field strength, predict flux sign and reveal the dot-product result. Continue in Solenoids and Induction.

## Learning flow and scientific scope

- Make a prediction for the current setup, reveal a match/discrepancy and explanation, manipulate inputs and try again. Changing inputs or lens/circuit mode clears the old prediction, preventing stale feedback.
- Each visual has labeled sliders/buttons as alternatives to dragging. Predictions use named choices, feedback is announced as a live region, long content scrolls and Close remains outside the scroll view.
- Controls/evidence survive closing/reopening the activity during the same studio visit. Reset restores the preview defaults. Leaving for a different studio releases that visit's activity state.
- These are explicitly labeled **independent studio previews**. Lab links open real catalog routes without transferring preview values, inserting trials, rewriting notes or awarding completion. They do not modify a saved apparatus configuration.
- Circuit results reuse the existing modified nodal analysis solver; optics uses `ImageSolution`; waves use the existing harmonic function; motion uses `trackPosition`. The remaining transparent analytic relationships are bounded and checked numerically.
- Resolution is not accuracy; q/√12 assumes uniform rounding. Lever arrows show an initial tendency, not a fabricated angular trajectory. Zero force does not imply rest. The energy-retention slider is an explicit accounting assumption, not a drag model. Independent f/λ do not describe a fixed dispersive medium. Conduction is steady, with no contact resistance or fabricated race timing. Flux-angle scrubbing has no physical clock and does not claim an EMF measurement. These limits are available in each activity.
- Optics handles signed focal length, virtual extensions and the image-at-infinity singularity. Numerical image distance is preserved even when outside the illustrative viewport. Magnetic flux is exactly zero at the entered 90° normal angle.

## Verification

`test/studio_mission_test.dart` covers all ten distinct registry entries, all twenty in-studio lab destinations, invalid/bounded inputs, every answer class, energy accounting, circuit powers/current, the focal limit, flux signs, reset and feedback invalidation. Widget flows exercise dragging, buttons, both circuit/lens modes, wave time, prediction/reveal, retention and all twenty real lab routes. No observations or mastery entries are created by these activities.

All 17 studio pages and all ten activity panels are checked at **320×568 portrait** and **640×320 landscape**, with **200% text**. Optional `--dart-define=STUDIO_MISSION_VISUALS=true` produces ten synthetic widget-rendered previews in ignored `Target UI/priorityStudioScreens`. These are not native-device screenshots; the test harness loads Manrope but not Material Icons.

Final command results are recorded in `PRIORITY_STUDIO_UX_VALIDATION.json`. The ordinary Android debug build is checked separately. Existing emulator/user data is left untouched; no physical-device, release-performance or iOS runtime certification is claimed.
