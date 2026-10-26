# Target UI implementation audit

Version: 1.10.0+13. This audit compares the application with all 17 user-supplied Target UI collages (102 reference panels).

Implemented across the shared workspaces: white surfaces, navy centered headings, bright blue accents, compact reading cards, labeled sliders with chevrons and precise numeric fields, bordered Reset controls, explanation strips, and the four-item Learn / Labs / Results / Profile footer. Later subject headings follow the unnumbered reference style. The first footer icon follows the source family (home or book); Learn opens actual learning content. Camera tools remain in the contextual menu. Full-screen scientific views retain their full-screen behavior. The former five-section bar remains removed.

Launchers now use static cropped previews from the supplied references, with original renderer fallbacks. The app does not treat the displayed preview numbers as live observations. Reference source files are copied without modification into assets/reference_previews; ownership is not asserted. The original Target UI folder is untouched. The generated material atlas supplies steel, brass, wood and other surface texture while code retains all scientific geometry, scales, rays, contact tests and values. See TARGET_UI_ASSETS.json for origin, hashes and the 16 tile meanings.

Validation scope:

- All 102 catalog destinations: Android screenshots and uncaught-error checks.
- All 17 studio launchers, five optical/thermal bench routes, Home, Notebook, Profile and Settings.
- Learn, Formulas and Results screens for the first lab in each of the 16 physical studios.
- Widget suite checks all physical family sections and interactions, small portrait and landscape at 200% text, camera state preservation, numeric entry with keyboard, and real footer navigation in every workspace family.
- Exact local SQLite/preferences preservation comparison against a private backup captured before this UI task. No reset or deletion of saved trials.

The screenshot index is TARGET_UI_SCREENSHOTS.md. The checklist is TARGET_UI_SCREEN_AUDIT.csv; native counts are screenshots/targetUiAudit.json. Screenshot files use target- prefixes. Build/install and data preservation reports accompany the final APKs. Historical physics milestone reports remain separate.

Visual review corrected clipped second parameter rows, compressed graph axes, mismatched Home/Learn labels, inconsistent heading numbering and extra studio heading lines. At 200% text in short landscape, overview tools scroll their bounded working area instead of overflowing. Small-phone chart workspaces scroll a minimum-height experiment stack; axes retain at least 90 logical pixels instead of collapsing. The final native sweep captures every compact graph after scrolling. Compact layouts retain access to every control through Controls & investigation; camera controls scroll horizontally and no longer cover the Micrometer magnifier button.

Remaining visual differences are material: the live apparatus remains procedural artwork rather than the photographic apparatus shown in the reference panels. The six overview tools retain their real interactive maps, saved filters, learning paths, comparisons and assessment results rather than displaying static reference compositions or fabricated progress. Scientific values, instrument least counts and uncertainty definitions follow the existing models rather than incorrect or illustrative values embedded in the supplied pictures. Therefore this build is a reference-style implementation, not a certified pixel-for-pixel match. No pixel-difference acceptance test, physical-device/iOS certification, production signing or store publication is claimed.

Image generation used the built-in image_gen mode; the final saved asset and exact final prompt are recorded in TARGET_UI_TEXTURE_PROMPT.txt.

Final checks: 322 unit/widget tests passed; flutter analyze reported no issues; 266 native captures completed, including all 90 readable compact graphs. Both ordinary lib/main.dart APKs installed with -r, installed bytes matched SHA-256, and launched with Wi-Fi/mobile data disabled. All 428 trial bodies, 123 challenge bodies, 108 session states and five preferences exactly match the pre-UI backup; SQLite integrity is ok and schema remains 3. See TARGET_UI_VALIDATION.json for the combined evidence.

Deliverables: deliverables/physics-atelier-target-ui-debug.apk (development build), deliverables/physics-atelier-target-ui-release-dev-signed.apk (development signing), and deliverables/target-ui-screenshots.zip. Source changes are saved locally; this task does not publish the app or push to GitHub.
