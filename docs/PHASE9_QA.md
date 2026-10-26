# Phase 9 and compact workspace QA

Status: working Android development builds; **not a release candidate**. Validation took place on 2026-10-26.

## Final checks

- `flutter analyze --no-pub`: clean. `flutter test --no-pub`: **290 passed**. Final logs are in `docs/validation/`. The final summary/history adjustment also passes focused scaffold analysis and the actual prediction→record→reopen→challenge-history regression.
- All 102 working destinations rendered at 200% text in 320×568 portrait and 568×320 landscape logical pixels. The studio accessibility tests additionally cover small phone, landscape and tablet arrangements; Home and all 17 launchers were reviewed in native contact sheets.
- Android native inventory completed all102 destinations in one traversal (14m27s): every physical lab changed a genuine model input, recorded a finite calculation, saved/reopened configuration fields and encoded CSV; all five content sections were rendered. These checks call real control/model callbacks and repository methods, not independent human science certification.
- Final running-app capture passed Home +17 studios +102 entries. The ordinary APK adds split and fullscreen interaction screenshots. Before and after examples cover every studio.
- Keyboard-open precise entry and observation notes pass. Pane changes/resizing, camera input separation and unchanged paused science are tested across all eight physical workspace families. Guided steps require actual changed input and a matching current record; final step survives reopening. Old completion evidence contracts remain in force.
- Scientific regressions cover units, reference calculations, conservation, boundaries, inverse scene mapping, actual circuit editing/wiring, graph cursors, seeded observations, microphone denial and model-version restoration. Scope/assumptions are linked per entry in the scientific register.
- Native focused journeys covered all17 Astronomy choices, six tools, five comparisons, exact seeded replay and real OS Home/background/resume. They predate the layout refactor; updated widget regressions and final native capture supplement those journeys rather than implying every tool interaction was manually repeated.
- SQLite v1→3/v2→3/fresh migrations, malformed-row retention, transaction rollback and500-record stress fixtures passed before the layout refactor. Repository fixes are unchanged by the layout adaptation.
- Ordinary main-entrypoint debug and release-development-signed APKs installed with `-r`; installed base APK hashes match. Both launched with Wi-Fi/mobile data disabled and remained alive without an AndroidRuntime fatal exception. No application-data reset was used.
- The ordinary debug APK opened the actual Android CSV chooser and one native Back returned to the notebook. No recipient was chosen, and delivery to another app was not tested. The integration harness earlier left the chooser task alive and once triggered a root-navigation assertion on Back; this was not reproduced by ordinary-APK cancellation.
- TalkBack was actually enabled on the dedicated Android emulator; service state and46 application semantic nodes in Compare Phenomena were observed and a screen-reader swipe delivered. Notification permission was temporarily granted to the Android Accessibility Suite to avoid its first-use prompt, then restored; original accessibility settings were restored. This does not certify spoken output, every lab, or independent blind-user usability.

## Device and build conditions

Dedicated emulator **emulator-5556**, Physics_Phase3, Android17/API37 x86_64,16KB pages,720×1280 at320dpi,2CPU cores/2048MB RAM, host RTX3050 graphics. Shared emulator5554 was not used. Flutter3.47.8/Dart3.13.7. Correctness captures use debug software rendering; performance uses profile mode and the actual default **Impeller OpenGLES** backend recorded in startup logs. iOS/Xcode/VoiceOver and physical Android device tests were unavailable.

## Performance observations

Seven demanding cases were measured with90 requested active/parameter-edit frames each, then40 actual zoom/divider callback operations while paused. The scientific clock stayed unchanged during every camera/divider series. Frame timing, rather than a model-only stopwatch, is recorded in `screenshots/workspace-after-default-profile.json`. Results remain above the16.67ms budget; no60fps claim is made.

- s10-e01: median build 3.791ms, median raster 51.687ms, p95 raster 105.109ms; camera/divider median raster 45.133ms, unchanged ticks 0.
- s08-e04: median build 2.142ms, median raster 39.664ms, p95 raster 84.341ms; camera/divider median raster 24.952ms, unchanged ticks 653.
- s16-e00: median build 2.468ms, median raster 40.996ms, p95 raster 87.269ms; camera/divider median raster 35.059ms, unchanged ticks 651.
- s16-e01: median build 2.490ms, median raster 39.301ms, p95 raster 69.415ms; camera/divider median raster 32.892ms, unchanged ticks 653.
- s16-e05: median build 2.156ms, median raster 20.945ms, p95 raster 61.280ms; camera/divider median raster 23.085ms, unchanged ticks 649.
- comparison0: median build 3.246ms, median raster 20.669ms, p95 raster 71.307ms; camera/divider median raster 24.265ms, unchanged ticks 698.
- comparison4: median build 3.247ms, median raster 33.909ms, p95 raster 63.620ms; camera/divider median raster 41.389ms, unchanged ticks 641.

The pre-redesign default-renderer run is preserved as `workspace-before-default-profile.json` (median raster roughly38–42ms). Different compositions, saved pane preferences and host conditions mean these descriptive runs are not a controlled speedup benchmark. These runs do not establish an overall rendering improvement. The final profile includes the corrected portrait vertical split. Its optional native-instrumentation reporting channel printed a warning after teardown; the Dart VM integration driver returned all seven timing series and the104-session restoration report successfully. Native Android instrumentation reporting is not claimed. Earlier Skia profiling of15 demanding cases and host model-construction benchmarks remain as supplemental evidence; host timings are not mobile solver timings. A pre-redesign10-cycle navigation memory sample declined from267714560 to261292032RSS bytes after warm-up, but is not proof that the final layout has no leak. Physical-device profiling and long-session memory/thermal testing remain release work.

## Fixed defects

Measurement now requires current changed inputs, prediction, matching recorded state and explanatory notes for earned completion; its route-covered timer pauses and bounded track clock cannot overshoot auto-stop. Rejected/malformed sessions are backed up rather than silently overwritten. Overview restoration validates dropdown/filter types. CSV free text is protected against spreadsheet formula interpretation. Comparison source links point to correct labs. Data graph semantics no longer mislabel observational SPARC data as calculated. Plot caching is opt-in for immutable revisions, material shadows avoid offscreen blur, contrast and launcher/splash branding are improved.

The layout refactor preserves original apparatus and models, moves primary work into bounded panes/docks, makes camera manipulation explicit, adds live formula/control links and selected-record comparison/export/reopen, and removes large default article headers. Responsive failures found during tests (narrow numeric values, notebook headings, map footers and large-text launcher cards) were corrected.

## Persistence and packaging

`screenshots/phase9-preservation.json` is the final binary-safe comparison against the local pre-work backup. It reports original trial and challenge bodies byte-for-byte, original session state equality, preferences and SQLite integrity. Extra explicitly recorded QA trials remain labeled simulated validation observations; no original records were deleted. Raw notebook backups and generated fixtures are excluded from Git.

Release `--no-pub` initially retained the debug/integration plugin registry and failed Java compilation. The normal `flutter build apk --release --target lib/main.dart` command regenerated the correct release registry and succeeded. Generated registry files were not hand-edited. Build modes must be sequential. Release mode uses the existing debug/development signing certificate; production signing remains the owner’s responsibility.

## Remaining limitations

Photographic/premium asset fidelity, physical-device frame budget, complete human accessibility review, iOS compilation/device QA and final redistribution/license review remain blockers. Reference/data/model assumptions are explicit in the scientific and asset registers. No AAB/store publication or remote push occurred.
