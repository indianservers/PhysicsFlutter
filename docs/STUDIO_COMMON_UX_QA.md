# Shared and studio-specific exploration — 1.16.0+19

This pass implements **10 common workbench enhancements for all 116 physical laboratories**, plus **10 curated tools in each of 17 studios**: **180 review items**. The studio tools comprise 160 physical-lab setup/readout investigations and 10 Concept Overview discovery actions. They use the existing scientific models; the catalog still contains 116 physical labs and six overview tools, with stable identities.

The [complete suggestions](STUDIO_COMMON_UX_SUGGESTIONS.md) list every item by studio. The [checklist](STUDIO_COMMON_UX_CHECKLIST.csv) maps each item to a lab and implemented behavior. These are current refinements of the application, alongside the earlier screenshot review and the previously delivered 580 per-lab learning-tool configurations. They are not a claim that 180 separate physics engines were added.

## Finding and using the changes

- In a physical lab, open **Lab options → Exploration workbench**, or its button inside Inspect.
- On a studio page, select **10 studio tools**. Search by lab or tool name and open a focused investigation.
- Opening a physical investigation previews its setup without applying parameter values. Expand **Preview studio setups**, inspect A/B values and their actual units, then explicitly apply a setup.
- Controls, Readings, Compare and Guide share the current source model. Supported dynamic labs expose Run/Pause and Step; captures pause the actual model.
- Captures survive closing and reopening the workbench during the same lab visit. This lets a learner return to the apparatus for calibration, timing or another procedure before capturing B. They are temporary evidence, distinct from recorded trials and saved explanation worksheets.

## The ten common changes

1. **Control search:** names, symbols and units, result count and clear action; search stays at the top rather than behind long setup previews.
2. **Precision entry:** each input retains its current range and unit, using reversible engineering-unit conversion for the existing precision dialog.
3. **Fine adjustment:** named decrease/increase targets and selectable 0.01%, 0.1% and 1% range steps. Bounds are enforced; discrete inputs retain the source model's rounding.
4. **Paired setup previews:** inspect both recipes before acting. All requested fields must be available and in current bounds; a failing application requests restoration of the prior complete configuration.
5. **Undo/redo:** full source configurations rather than just one visible slider. Changing the setup after Undo starts a new history branch.
6. **Reference ledger:** review changed visible inputs and unavailable fields, replace the temporary reference explicitly, or restore its complete setup with Undo available.
7. **Reading focus:** search actual calculated quantities, pin useful readings and filter to the curated investigation focus.
8. **Capture readiness:** expose validity and the source notice. Undefined values remain undefined; measurements requiring a procedure do not become fabricated evidence.
9. **Controlled comparisons:** actual paused A/B captures, changed-input disclosure and a secant only when exactly one visible input changes, units/model context match and available model time is equal. Numeric category codes are excluded. This describes two captured states, not a fitted curve or an independently proven causal derivative. Secant units are the stated source units; dimensionless percentages use their underlying fractions.
10. **Deliberate sharing:** an explicit Copy action includes selected setup inputs and calculated evidence, while excluding source notes, history and private full undo configurations. Clipboard behavior is tested with a mock rather than overwriting the device user's clipboard during native QA.

## Studio-specific content

Every physical lab has at least one studio entry. Forty-four additional scenarios use distinct, reviewed control combinations and their own questions. Examples include translating both ruler endpoints at fixed span, swapping unequal interacting masses, varying mass at fixed kinetic-energy speed, moving an energy reference, changing pendulum gravity, comparing pulse widths, moving a lens screen through focus, reversing one electric charge, parallel/perpendicular magnetic motion, retarding photoelectric bias, specimen mass/volume and visual-scale independence of orbital data.

The 10 overview actions set real atlas/map views, search terms, concept focus, learning paths, launcher filters or a validated mastery topic. They reset unrelated view filters to avoid accidental empty intersections, while preserving notes, attempts and completion. Choosing a question does not submit an answer or award progress.

Definitions are in `tool/studio_investigation_definitions.json`. `tool/build_studio_experience.py` compiles the offline registry and the 180-item list/checklist. Primary model callbacks, validity rules, clocks and readouts remain in their existing workspaces. The earlier Tune/Compare/Watch/Plot/Explain tools and saved worksheets remain available. The worksheet shortcut opens that existing worksheet without replacing its saved evidence.

## Verification and evidence

Actual results are recorded in [the validation report](STUDIO_COMMON_UX_VALIDATION.json). Checks exercise all 160 physical recipes against real workspace controls, including apply/undo/redo/reference restoration, all 10 overview actions, all 116 common workbenches at 200% text and all 170 discovery cards. Short-landscape, keyboard, precision-entry, clipboard exclusion and dynamic playback/reopen regressions cover the interaction boundaries.

- Full regression suite: **395 passed**. Final focused suite: **9 passed**, including relative-tolerance input assertions for subatomic masses and charges. The combined short-landscape/keyboard regression also passed separately. Static analysis reports **no issues**.
- Repeated Android audit: **17 catalogs, 16 physical-studio representatives, 64 shared panels and 32 explicit setup applications** passed. **82 native PNGs** are retained, plus a final ordinary-app Home capture.
- Ordinary **1.16.0+19** debug APK installed with a checksum matching the deliverable. Test-only kernel markers and the private restoration fixture are absent; the default-renderer Home screen was visually verified.
- Original **428 trial bodies, 108 complete session states, 123 challenge bodies and all five preferences** are preserved; SQLite schema 3 and integrity remain unchanged.

The first Android run caught an expanded setup preview losing state after switching tabs. Its state now survives that transition, and a regression test applies A, switches to Compare, returns to Controls and applies B through the actual UI. Original data was verified after that run's cleanup before repeating native validation.

Native screenshots are local under `Target UI/studioCommonUXScreens`. Coverage is explicitly **17 studio catalogs and one physical representative in each of the 16 experiment studios**, including its four common panels and paired setup actions. Automated source/widget coverage is broader than this native sample; these are not screenshots of all 116 new workbenches.

The ordinary APK uses `lib/main.dart`; integration fixtures and test entry points are excluded. [Data preservation](STUDIO_COMMON_UX_PRESERVATION.json) compares original trial/challenge JSON bodies, complete parsed session states and preference type/value pairs. Session save timestamps may differ. Raw backups and fixtures remain private and ignored. API 37 emulator debug timings are not release-performance measurements; physical-device and iOS validation remain outside this run.

Final focused checks cover the categorical-code secant exclusion and the compact layout used when a landscape keyboard leaves very little height. Native screenshots show the regular-size workbench layout.
