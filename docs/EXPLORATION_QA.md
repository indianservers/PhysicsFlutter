# Studio and lab exploration audit

Version 1.12.0+15. Scope: all 17 studios, 96 physical labs, six learning tools and five existing material/optical benches. No scientific model or stored schema was changed.

Implemented improvements:

- Studio pages reuse the generated subject artwork and premium typography, with actual catalogue counts, descriptions, search, Completed and Saved filters, clear empty states and full-card lab navigation. Saved filters appear only where lab favorites are supported. Card bookmark controls persist through the existing notebook. Studio guide sheets explain the actual subject and list working lab links.
- Every physical lab has a labeled illustrated guide with a direct route back to the same live apparatus. No values are reset and no observations are fabricated. Uncertainty uses a model-rendered example explicitly marked as simulated readings.
- Lab options expose collection saving, exploring the current studio and a direct Guided investigation action. Existing learning content, scientific constraints, prediction checks, recording and reopening remain intact.
- Shared reading cards use readable quantity names and small SI prefixes while retaining source SI values in their tooltips. Controls, calculations, notebook records and exports retain their original units and precision.
- Reference previews decode at a suitable higher resolution and preserve their selected image region. Measurement crops keep complete instruments and remove the Spherometer reference image’s fixed numerical panel. Live apparatus remains code-driven.
- Explanation and record controls meet 48 dp Android targets; compact graph actions have a semantic label. Menus scroll to selected sections in automated navigation. All screens share the bundled Manrope typography.

Validation:

- Full unit/widget suite: 333 tests passed on the delivery source, including the final reference crops, statistical-unit labels and shared text-color contrast checks.
- All 102 destinations fit small portrait and landscape at 200% text. All 96 illustrated guide return actions preserve controls at 200% text.
- Every physical lab accepts a primary control binding adjustment; discrete controls are exercised with valid distinct settings. No validation trials are added to the user notebook.
- Android-size tap-target and labeling guidelines pass for all 17 studios and 96 physical lab workspaces in the phone widget configuration. This is an automated guideline check, not a substitute for human assistive-technology testing.

The 102-entry checklist is EXPLORATION_SCREEN_AUDIT.csv. Native captures use explore- prefixes. Existing Home, Target UI and science milestone evidence remains unchanged.

Limits: live apparatus remains procedural rather than photographic; source illustrations are references rather than measurements. No pixel-identical artwork, physical-device/iOS validation, production signing or store-release certification is claimed.

Statistical plots now display the actual sample unit instead of a generic SI caption, including the explicitly simulated example. Shared blue text has approximately 4.92:1 contrast on white and the shared secondary text approximately 4.70:1.

Final delivery: 333 tests passed, static analysis clean, 346 unique native audit captures plus focused reference/unit refreshes. Ordinary debug and development-signed release APKs install with -r, match installed bytes by SHA-256 and launch offline. All 428 trial bodies, 123 challenge bodies, 108 saved session states and five preferences exactly match the pre-task backup; database integrity is ok and schema remains 3. See EXPLORATION_VALIDATION.json for combined evidence.

Deliverables: deliverables/physics-atelier-exploration-debug.apk, deliverables/physics-atelier-exploration-release-dev-signed.apk and deliverables/exploration-screenshots.zip. Screenshot index: EXPLORATION_SCREENSHOTS.md. These APKs use the existing development signing certificate.
