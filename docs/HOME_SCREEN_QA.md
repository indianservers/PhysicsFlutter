# Home screen implementation

The Home screen follows the supplied visual composition: white background, atom wordmark, prism/gyroscope hero, live search, four filters, a two-column artwork catalogue and floating Home / Explore / Saved / Settings navigation. Actual catalogue names and routes are retained, as required by the attached brief. The supplied image uses a different taxonomy, so its card names are not copied over the existing catalogue.

All artwork was generated separately with the built-in image_gen tool, then encoded as display-sized WebP assets. No screenshot is used as a home card. Text and vector icons remain code-rendered. The 18 artwork assets total approximately 420 KB. Exact generation prompts and saved asset paths: HOME_ARTWORK_PROMPTS.json.

Studio titles, counts and routes derive from the existing catalogue. Presentation metadata supplies only descriptions, categories and artwork paths. Long-press a card for its description and actual activity count; semantic labels expose both. Cards keep the reference’s sparse visible labeling.

Continue learning appears only for a real last-opened lab and includes studio context plus Resume. Saved reads the existing persistent lab favorites. Search covers studio titles, lab titles, principles and descriptions, with real destinations and a resettable empty state. Push/pop navigation retains Home scroll, query and filter state. Reduced-motion preferences disable scroll animation. Larger system text uses a single-column catalogue and a separated hero artwork row.

## Connected studios

- Concept Overview: `/studio/s00`
- Measurement: `/studio/s01`
- Mechanics: `/studio/s02`
- Motion & Kinematics: `/studio/s03`
- Force & Newton’s Laws: `/studio/s04`
- Work, Energy & Power: `/studio/s05`
- Gravitation: `/studio/s06`
- Oscillations: `/studio/s07`
- Waves & Sound: `/studio/s08`
- Optics: `/studio/s09`
- Electricity: `/studio/s10`
- Magnetism: `/studio/s11`
- Electronics: `/studio/s12`
- Thermodynamics: `/studio/s13`
- Fluid Mechanics: `/studio/s14`
- Modern Physics: `/studio/s15`
- Astronomy & Astrophysics: `/studio/s16`


## Validation and screenshots

The final 327-test suite passed, including existing scientific/navigation regressions, a phone-keyboard search regression, and the Saved empty-state reset. Static analysis reports no issues. Native Android checks open all 17 studios through their full-card targets, verify 17 scroll restorations, decode all 18 generated artwork assets, exercise search and Saved/Settings navigation, and confirm that trial counts do not change. Exact data-preservation and ordinary APK installation reports are supplied separately.

Screenshots: [top](../screenshots/home-redesign-top.png), [middle](../screenshots/home-redesign-middle.png), [bottom](../screenshots/home-redesign-bottom.png), [search](../screenshots/home-redesign-search.png), [saved](../screenshots/home-redesign-saved.png).

Manrope is used only on Home. Source: https://github.com/google/fonts/tree/main/ofl/manrope ; the bundled SIL Open Font License is assets/home/Manrope-OFL.txt. The atom mark and navigation/search/arrow icons are generated as crisp Flutter vector painters. They do not depend on rasterized UI text.

The design preserves real history and the existing 17-studio taxonomy; those differ from the illustrative catalogue shown in the supplied screenshot. Original generated artwork recreates its style and subjects rather than claiming byte-for-byte photographic identity. Physical iOS/device validation is pending; responsive tablet and 200% text were verified in widget tests.

The final Android audit and restoration passed. Existing 428 trial bodies, 123 challenge bodies, 108 session states and five preferences match the pre-task backup exactly. SQLite integrity is ok; schema remains 3.

Ordinary main-entry debug and release APKs installed with -r and launched offline; installed bytes match their SHA-256 sidecars. Both use the existing development certificate, not production signing. Combined evidence: HOME_VALIDATION.json. Installable release: deliverables/physics-atelier-home-release-dev-signed.apk.
