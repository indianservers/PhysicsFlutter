# Phase 3 of 9 handover

Version 1.2.0+3 continues the existing project. Eighteen new labs cover Work/Energy/Power, Gravitation and Oscillations. Together with the six Measurement and eighteen Dynamics labs, the catalog exposes 42 interactive labs across seven studios. All seventeen studio pages and 102 destinations remain accessible. No Phase 4 experiments were added.

The new labs have specific lessons, validated numeric/gesture controls, actual calculations, deterministic playback where applicable, bounded graphs/cursors, analytic curves labeled separately, formulas, guided predictions, notes, saved configurations and actual-trial CSV export. Static gravitational force/field/probe investigations remain manipulable supported-body experiments rather than pretending to animate orbital physics. Orbit and oscillator labs implement physical trajectories with the methods and limits described in the science notes.

Visual work includes distinct dimensional studio previews, shared brushed-metal/brass and timber details, crate fasteners/contact shadows, aspect-preserving Measurement rendering, articulated spring/motor/rope geometry and an original generated planet surface texture. Before/after captures preserve the earlier screens separately. Procedural apparatus remains stylized; this is not a claim of photographic parity with all target boards.

Install the ordinary `lib/main.dart` build at `deliverables/physics-atelier-phase3-debug.apk`. The adjacent SHA-256 file identifies the delivered binary. This is a debug-signed installable APK, not a store-signed release. Earlier APK deliverables remain available.

Validation: clean analysis, 73 passing unit/widget tests, all eighteen new labs verified natively, all twenty-four earlier labs passing native functional regression, limiting-mode/lifecycle/navigation checks, and final Android build/install/default-renderer launch. Original and isolated notebooks were reconciled to 80 exact preserved trial records; twenty-four earlier sessions were retained. A fresh native read reported no recovery warning. Profile data is documented honestly: p95 total frame times ranged from 27.8 to 43.8 ms on the available emulator, so physical midrange 60 fps remains unverified.

- [Scientific models, constants, methods and primary references](PHASE3_SCIENCE.md)
- [Asset provenance, generation prompt and previous-module audit](PHASE3_ASSETS_AND_AUDIT.md)
- [Validation, preservation and actual performance evidence](PHASE3_VALIDATION.md)

New source: `lib/core/physics/advanced.dart`, `lib/features/advanced/`, and shared rendering helpers. Existing physics was retained; the existing schema-3 JSON tables accommodate the new model without destructive migration. Previous record model versions remain accepted.

Remaining checks: physical midrange Android performance/accessibility QA, iOS compilation/device checks on macOS/Xcode, photographic visual refinement, and the final Phase 9 release validation. Emulator profiles do not establish physical-device frame rates. Model-specific restrictions include exterior spherical gravity, fixed-source satellites, no slack-string pendulum transitions, constant-speed lift segments without transients, linear oscillator materials and a bilateral captive track.
