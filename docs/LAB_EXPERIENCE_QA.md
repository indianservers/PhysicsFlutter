# Lab exploration and scientific inspection

Build: **1.13.0+16**. Reviewed against the locally captured 102 lab/tool destinations in 17 studios.

## Shared experience

- The home screen and other destinations use the same Home / Explore / Saved / Settings navigation, including the reference icons. Lab learning, graphs and results are local workspace actions.
- Apparatus, Graph, Inspect and Results are directly accessible from the lab toolbar. The compact toolbar yields space on short landscape screens; the existing lab options remain available.
- Inspect pauses the experiment and exposes its actual calculated readings, precise input controls, the current model selection, equations, validity limits, prediction checks and guided investigation entry.
- Pin a reading and its inputs, change an input, and reopen Inspect to compare the before/after values. Pinned comparisons stay in the current workspace and do not create observations or alter notebook records.
- Continuous model curves have an interval inspector with endpoint controls, a secant slope and a clearly labeled trapezoidal signed-area approximation. Scatter/error-bar and histogram displays retain their discrete rendering and do not display a continuous-area result.
- Numeric entry uses reversible engineering-unit conversions. Stored measurements, configuration values and calculations retain their original units. Scientific notation is not ellipsized. Percentages, astronomical distance/time units and selected eV/MeV/solar-luminosity readings have contextual presentation.
- The workspace exposes Ready / Running / Paused / Finished state. Saving an observation acknowledges its actual value and provides a Results action.
- Reset keeps recorded trials and offers Undo using a deep copy of the owning model's complete configuration. The replay path uses the same restoration methods as notebook reopening.
- The controls drawer keeps its form widgets mounted while the keyboard changes size. It owns its Record action while open, avoiding duplicate recording controls.
- Measurement apparatus retains its own gesture region. Camera manipulation and scientific adjustments remain separate.

## Studio refinements

1. **Concept Overview:** readable initial lists, larger launcher previews, shorter metadata, honest practiced/completed states, focused relationship neighborhoods, a return-to-all-concepts action and visible search matches. Existing guided paths and model-backed mastery questions remain available.
2. **Measurement:** live endpoint subtraction, vernier/micrometer decomposition, signed zero correction, Spherometer reference/contact/radius explanations, instantaneous versus average speed, and repeated-reading interpretation. Larger Spherometer fitting shares its transform with hit testing; compact view options move into Inspect. Precision scale readers remain accessible from the app bar.
3. **Mechanics:** readable force callouts, direct isolated-body/component switches, signed torque comparisons and before/after collision momentum. Existing pulley constraints and centre-of-mass diagnostics are exposed through Inspect.
4. **Motion & Kinematics:** interval slopes/areas, synchronized existing graph cursors, direct rest/uniform-motion/uniform-acceleration references and readable frame diagnostics. Camera following, projectile and circular-motion controls remain source-model operations.
5. **Force & Newton's Laws:** net/contact-force comparisons, isolated-body inspection and promoted friction presets. Resultant forces remain distinguished from individual contact forces and counterpart-body forces.
6. **Work, Energy & Power:** actual kinetic/potential/total/input/useful/loss comparisons, readable percentage efficiency, interval graph tools and the existing energy/sign-convention explanations.
7. **Gravitation:** field-component comparisons, readable distances/speeds/periods and promoted circular/escape references. Existing probe, orbital and Kepler diagnostics retain their scientific assumptions.
8. **Oscillations:** energy accounting, damping-regime, natural-frequency and coupled-mode reference controls directly in Inspect, plus interval graph measurement.
9. **Waves & Sound:** a draggable wavelength ruler with a non-drag positioning control, clearer access to the existing component/probe/harmonic diagnostics and optional generated Android audio. Playback uses the same educational-signal generator as spectrum analysis, has explicit volume and mute/stop controls, ends after two seconds, and releases native resources on background/disposal. Microphone audio is never replayed or stored by this feature.
10. **Optics:** staged ray construction, optional fitting of finite real/virtual images, promoted critical-angle/image-position references, readable wavelength entry and existing image-type/infinity diagnostics. View changes do not modify the optical model.
11. **Electricity:** an alternate connected schematic and component inspector from the same circuit graph, readable signed charge controls, complete accessible model readings and node/branch diagnostics, current/potential/capacitor controls and comparison tools.
12. **Magnetism:** accessible component/probe/coil readings, equations, signed inputs, current-state comparisons and existing induction/field diagnostics.
13. **Electronics:** direct binary input switches, the existing truth table beside the active logic controls, amplifier input/output/clipping comparisons and readable carrier, bias and sensor diagnostics.
14. **Thermodynamics:** the tip follows conduction/convection/radiation selection, Kelvin and Celsius appear together, and the model's energy and two-body entropy ledgers are exposed. Existing material libraries and process/cycle controls are preserved.
15. **Fluid Mechanics:** weight/buoyancy/support comparisons, complete probe/geometry/material inputs, readable units and the existing hydrostatic, flow and Reynolds-limit diagnostics.
16. **Modern Physics:** contextual quantum-energy/binding-energy and decay-time units, accessible state/probability/model descriptions and the existing stochastic, spectral and detector distinctions.
17. **Astronomy & Astrophysics:** AU/pc/kpc/Mpc, day/year and solar-luminosity presentation; galaxy component and cosmological-distance comparisons; an H–R diagram linked to the source stellar age and direct prediction entry; existing transit, spectral and evolutionary diagnostics.

The review's 180 suggestions are design directions, including refinements of existing capabilities. This implementation combines shared controls and selected visual/interaction changes with those existing scientific tools; it does not claim 180 separately built features.

## Validation

- `flutter analyze --no-pub`
- `flutter test --no-pub`: 342 tests cover the feature implementation, including pinned values at 200% text and the specialist studio tools.
- `integration_test/lab_experience_audit_test.dart`: native traversal and captures of all 17 studios, 102 lab/tool views, 96 inspectors and 96 graph views, checking that inspector navigation preserves control values.
- Native capture output is local under `Target UI/updatedScreens`; the earlier `Target UI/currentScreens` evidence is preserved.
- Private notebook preservation uses a fresh app-sandbox baseline and the existing local restoration fixture. The baseline and fixture are never committed or included in the ordinary app build.

Native verification passed: all 102 final primary views, specialist tools and real generated audio play/stop. [Build verification](LAB_EXPERIENCE_VALIDATION.json) records the installed APK hash. There are 332 local evidence images including 17 contact sheets. The ordinary app was installed after QA; all 428 trial bodies, 123 challenge bodies and 108 original session states matched the fresh baseline exactly, with all five original preference values/types preserved. The database schema remains 3 and integrity_check is ok. Preference comparisons ignore only insignificant XML element-tail whitespace. No QA fixture is compiled into the ordinary artifact. Emulator checks do not replace physical-device or iOS QA. The optional tone player is Android-only; the rest of the experience retains the Flutter implementation.

Accessibility references: [Flutter UI design](https://docs.flutter.dev/ui/accessibility/ui-design-and-styling), [Flutter accessibility testing](https://docs.flutter.dev/ui/accessibility/accessibility-testing), [W3C dragging alternatives](https://www.w3.org/WAI/WCAG22/Understanding/dragging-movements). Native sound uses Android's [AudioTrack](https://developer.android.com/reference/android/media/AudioTrack).
