# Phase 1 handover

Working source is in `C:\Indian Servers\Android Physics`; the original 17 target PNGs are preserved locally. The project is associated with https://github.com/indianservers/PhysicsFlutter . Changes are local unless explicitly pushed separately.

## Available

The home catalog contains all 17 studios. Every studio has six exact entries, recommended order, availability and locally earned completion. All 102 entry IDs are unique and routable. Search and Continue Learning use the same catalog and actual local activity. Six basic Concept Overview tools provide navigation, a path, introductory relationships/comparison and an explained question.

Measurement has six interactive labs using SI scientific models and state-linked procedural scenes. Instruments include a ruler with endpoint/object movement and zoom; an external vernier with bias calibration and coincidence; a contact-constrained micrometer with pitch/turns; a signed spherometer with plane zeroing; a simulated balance plus monotonic track timer; and uncertainty analysis with manual/imported readings, error bars and independent propagation. All have learning material, equations, assumptions, guided steps, actual trial recording, notes, reopen and CSV export. The notebook and settings are local and offline.

## Handoff files

- `deliverables/physics-atelier-phase1-debug.apk`: installable debug build from `lib/main.dart`, not the integration-test entry point.
- `screenshots/01-home.png`, `02-measurement.png`, `03-lab-0.png` through `08-lab-5.png`, `09-notebook.png`: actual Flutter-rendered Android integration captures.
- `screenshots/verified-results.csv`: actual observations recorded by the integration workflow, including SI units, optional resolution, model version and configuration. It is test evidence, not seeded application data.
- `docs/SCIENTIFIC_MODELS.md`: calculations, idealizations, examples and references.
- `docs/ASSETS.md`: provenance and visual limitations.
- `docs/VALIDATION.md`: executed checks and remaining QA.
- `docs/IOS_VERIFICATION.md`: macOS/Xcode follow-up.

## Remaining work within product-quality acceptance

The procedural apparatus and studio illustrations are functional and scientifically connected but do not meet the targets' photorealistic visual fidelity. Photographic thumbnails, more realistic instrument assets, final iOS icon branding and design review remain. No missing assets are represented as already available.

Dedicated physical Android mid-range performance profiling, a complete manual TalkBack/VoiceOver audit, platform export destination testing across device vendors, wider tablet/landscape hardware QA and all iOS compilation/device validation remain. The available emulator validates behavior, not real-device performance or every Android version.

The non-Measurement studios intentionally contain learning/theory/formulas only, with explicit later-phase Experiment and Visualization notices. Their physical models and advanced Concept Overview tools are not complete. No Phase 2 work has been started. Do not market this build as all 96 physical labs being interactive or as store-ready.

Use the README commands to continue. The user-provided references must remain outside distributable assets until their licensing is established.
