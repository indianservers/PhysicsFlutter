# Ten new studio UX enhancements — recorded-evidence investigations

Version 1.19.0+22. This adds ten new guided investigations beyond the ten interactive concept previews in [the previous studio upgrade](PRIORITY_STUDIO_UX.md). The same subjective introductory-learning ranking is used: prerequisites, cross-topic usefulness and opportunities for scientific reasoning. It is not a popularity ranking or a published ranking from a textbook.

The existing studio pages already had lab search, filters, artwork, guides, studio tools and prediction previews. The new gap addressed here is the handoff from choosing a lab to collecting real evidence and writing a defensible explanation.

## Ranked studios and the ten new enhancements

1. **Measurement — Instrument decision guide.** Choose thin-object, curved-surface or repeatability work. Route to Micrometer, Spherometer or Uncertainty with a procedure-specific evidence task. Check the distinction between repeatability, calibration and resolution; attach actual recorded readings.
2. **Mechanics — Choose the system boundary.** Choose sliding-body, lever or collision investigations. Identify external forces on the selected system before collecting incline, torque or momentum evidence.
3. **Motion & Kinematics — Build a graph evidence trail.** Choose slope, signed-area or trajectory questions. Link Position–Time, Velocity–Time and Projectile Motion evidence to velocity, displacement and controlled launch conditions.
4. **Force & Newton’s Laws — Identify force evidence.** Choose net-force, interaction-pair or contact-constraint questions. Distinguish forces on one body from third-law partners, then collect acceleration or force evidence from the relevant lab.
5. **Work, Energy & Power — Account for energy transfers.** Choose work transfer, conservation or transfer rate. State the energy account, include dissipative transfers and distinguish energy from power when attaching records.
6. **Electricity — Diagnose a circuit with evidence.** Choose charge flow, wire resistance or connectivity faults. Inspect topology/switch state before interpreting current; keep wire geometry/material changes controlled and record valid solver outcomes.
7. **Waves & Sound — Separate source, medium and signal.** Choose propagation, resonance or spectrum questions. State whether the medium/speed was held fixed; compare frequency evidence without confusing peak frequency, amplitude and independent model parameters.
8. **Thermodynamics — Plan a fair thermal comparison.** Choose conduction, calorimetry or heat/work. Hold geometry and reservoir temperatures fixed when isolating conductivity; document calorimeter assumptions and the work sign convention.
9. **Optics — Map optical claims to evidence.** Choose ray images, interfaces or fringes. Use signed image/vergence evidence, distinguish physical rays from backward extensions and state the limits around total internal reflection/coherence/focal cases.
10. **Magnetism — Connect field evidence to flux change.** Choose solenoid fields, changing linkage or magnetic circuits. Separate steady field/flux from the rate of flux-linkage change and distinguish open-receiver EMF from current.

There are **ten enhancements total, with thirty goal-specific lab handoffs**. All handoffs use existing canonical lab IDs. Every studio has its own reasoning question, distractors, explanation and evidence tasks. The foundational coverage follows the topics in [OpenStax University Physics](https://openstax.org/books/university-physics-volume-1/pages/index); active exploration and explanatory feedback are consistent with [PhET’s teaching approach](https://phet.colorado.edu/en/about). The ranking and chosen app features are product judgments.

## How to use them

Open **Guided investigation • real evidence** at the top of any ranked studio:

1. Select an investigation goal and read its tailored task.
2. Check the reasoning question and inspect its explanation.
3. Open the recommended working lab. Use its **Record Trial** action, then return with Back. New notebook records appear in the guide immediately.
4. Attach two distinct recorded Trials as evidence A/B. No sample, predicted or placeholder measurements are inserted.
5. Inspect the source values, units, model, saved clock and recorded settings. Explain what the evidence supports, the controlled variables and the next test.
6. Explicitly **Save investigation**. Reopen it from the same studio later.

Changing goals changes guidance, not a lab setup. Existing evidence choices remain visible with their source lab names so the learner can assess relevance or clear them. Neither selecting a route nor answering a reasoning question awards lab completion or mastery.

## Evidence and persistence safeguards

- Evidence selectors contain only finite, actual Trials from the selected studio. Duplicate IDs are deduplicated; the same Trial cannot occupy both A and B.
- Numeric B−A is permitted only when lab, calculation model, quantity, units, mode, frame and selected component match. Otherwise the guide supports a qualitative comparison and withholds the numeric difference. Overflow is handled as unavailable.
- Even a permitted difference is explicitly descriptive. Source time, topology and inputs can differ; the guide never treats two records as proof of causation or fits a curve.
- Evidence cards expose only the recorded outcome, relevant source metadata and numeric/boolean settings. Source notes and full configurations are not copied into an investigation document.
- Saved documents use `studio-evidence:<studioId>` and version `studio-evidence-1.0`. They contain goal/answer choices, Trial ID references and the learner’s separate claim/reasoning. Lab notes, original Trial JSON, sessions and mastery records are not rewritten.
- Missing source records are shown as unavailable. A guide never fabricates a replacement value.
- Incompatible/corrupt stored investigations are retained unchanged until an explicit save. Before replacement, the raw original is backed up under `studio-evidence-backup:<studioId>:<timestamp>`; failed backups prevent replacement.
- Failed saves retain dirty edits and existing stored data. A save snapshots its document, so edits made during a pending save remain dirty. The 4,000-character fields count Unicode graphemes consistently with Flutter text input.
- Closing, Back and lab handoffs protect unsaved changes with Keep editing / Leave without saving / Save and continue. Unsaved drafts remain in memory during the studio visit; persistence requires Save. No automatic Trial, completion or mastery insertion occurs.

## Layout and verification

The sheet scrolls and keeps Close outside the scroll view. It uses a compact header for the keyboard, short viewports or large text, with the complete activity title in the scrollable content. Evidence choices, reasoning answers and navigation use labeled standard controls.

`test/studio_evidence_test.dart` covers the ten content definitions and thirty real lab routes; source filtering and comparison guards; same-record rejection; save/reload; source-note/Trial/session preservation; missing evidence; corrupt/future-version backups; duplicate references; Unicode round trips; failed saves; real dropdown selection; unsaved-work dialogs; and live notebook updates. Layout checks include all ten populated sheets at **320×568 portrait** and **640×320 landscape**, **200% text**, with the keyboard visible.

Final suite, analysis and APK results are recorded in `STUDIO_EVIDENCE_UX_VALIDATION.json`. Tests use isolated synthetic notebooks. No emulator/user database was modified, and no native screenshot, physical-device, iOS runtime or release-performance certification is claimed.
