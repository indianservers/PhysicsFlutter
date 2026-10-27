# Lab-specific learning tools — 1.15.0+18

The audit covers **116 physical laboratories across 16 experiment studios**, plus the separate Concept Overview studio. Each lab has five curated improvements: **580 lab-level enhancements**. The complete list is in [the suggestions](LAB_SPECIFIC_UX_SUGGESTIONS.md), with one implementation row per enhancement in [the checklist](LAB_SPECIFIC_UX_CHECKLIST.csv).

## What learners can use

Open **Lab options → Lab-specific tools**, or **Inspect → 5 lab-specific tools**. The five consistent tabs contain experiment-specific scenarios, quantities and learning prompts:

1. **Tune:** preview a named setup, apply its actual bounded source control, and undo the full setup change. Examples include a ruler's nonzero origin, a thin lens near its focal plane, friction near its threshold and transit geometry.
2. **Compare:** explicitly capture paused A/B states, with relevant controls, signed differences and changed-condition disclosures. Differences between fractional percentage readings use percentage points. Nuclear comparisons use the source nuclide selector.
3. **Watch:** inspect curated live, high-precision quantities from the current source model, with readable labels and actual units. Undefined quantities stay explicitly unavailable.
4. **Plot:** vary the selected source input and explicitly capture model snapshots into a scatter plot. Every point keeps input values, units, readings, mode, model version and available model time. The panel rejects incompatible axes, units and model contexts rather than blending them into one series.
5. **Explain:** answer the lab's specific claim/evidence/reasoning prompt, attach captured evidence and save a local worksheet. **Saved → Investigation worksheets** reopens Explain directly. Closing an edited worksheet requires Save, Keep editing or Close without saving.

For example, the ruler focuses on endpoint subtraction; the micrometer separates sleeve, thimble and signed zero correction; Hooke's law compares extension and force; damping uses displacement rather than an envelope that is undefined in some regimes; electrostatics focuses on signed force; circuits retain the selected component across setup undo; and stellar transit studies radius ratio and depth.

The panels reuse tested components, while `lib/content/lab_research_profiles.tsv` supplies the 116 individually reviewed scenarios, A/B settings, focal readings, plot axes and explanation prompts. `tool/generate_lab_research_profiles.py` generates the offline registry. `tool/build_lab_research_review.py` generates the complete list and checklist from the same definitions.

## Scientific and persistence boundaries

These tools call each laboratory's existing controls and read its actual calculated state; they do not introduce a second physics engine. They distinguish calculated snapshots from apparatus measurements. Scatter points are learner captures, not fabricated measurements or a fitted analytic curve. Existing Record Trial remains the route for a complete reproducible experiment record.

Some operations require apparatus work first. Spherometer curvature needs the reference and curved-surface contacts; timed speed needs a completed timing procedure; uncertainty needs sufficient observations. Those panels explain why capture is unavailable. Capacitor geometry controls remain unavailable in RC mode rather than being replaced by unrelated controls. No missing or undefined reading is replaced with zero.

Worksheets are versioned local preferences, separate from trial history and mastery. They deliberately exclude pre-existing source notes and histories. Invalid saved worksheet text remains retained; explicitly saving a replacement first keeps a local backup. Merely opening a panel, capturing evidence or saving a worksheet does not record a trial, favorite a lab or complete an activity.

## Verification

Actual run results and device coverage are recorded in [the validation report](LAB_SPECIFIC_UX_VALIDATION.json). The checks cover every lab's real control bindings, apply/undo, A/B capture, live readings, guarded point capture and saved-document restoration. Additional regressions exercise malformed documents, unavailable mode controls, circuit-component selection, dirty-close protection and Saved deep links.

- Full unit/widget suite: **386 passed**; final focused serial run: **7 passed**; static analysis: **no issues**.
- Android: **116 labs, 580 panels**, an A/B comparison, two captured plot points and a saved-worksheet round trip passed. **160 native PNGs** cover every lab's Watch panel and all five panels for ten representatives.
- Ordinary **1.15.0+18** debug APK built and installed with a matching checksum. Integration-test markers and the private restoration fixture are absent; the default OpenGLES Impeller Home screen was visually checked after startup.
- Existing **428 trial bodies, 108 complete session states, 123 challenge bodies and all five preferences** are preserved. Schema 3 and SQLite integrity remain unchanged. QA-created session rows and worksheet preferences were removed.

The responsive audit exercises all 580 panels at 320 × 568 logical pixels with 200% text, plus representative source families in short landscape and with the keyboard open. The native Android audit visits all five panels of every physical lab and tests an explicit A/B, two-point plot and saved-worksheet round trip.

Native evidence is local in `Target UI/labSpecificUXScreens`. Original screenshot PNGs remain unmodified. The all-lab captures precede final button/acronym wording polish and a defensive guard rejecting mixed experiment modes within one scatter series. The final unit/widget suite covers that guard, including invalid stored mixed-mode series; source callbacks and scientific models are unchanged. Final delivery uses the ordinary `lib/main.dart` entry point, not an integration-test entry point.

The exact post-install data comparison is recorded in [the preservation report](LAB_SPECIFIC_UX_PRESERVATION.json). Session save timestamps may differ; parsed states, notes and parameters remain identical. Raw notebook backups, restoration fixtures and device logs remain local and are not committed. A concurrent focused test repeat stalled in the host runner; the serial repeat passed. The API 37 emulator's cold debug startup was slow, so these checks make no release-performance claim. Android emulator checks do not establish iOS or physical-device coverage.
