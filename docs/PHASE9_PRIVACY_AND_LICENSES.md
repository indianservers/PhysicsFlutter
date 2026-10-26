# Privacy, permissions and dependencies

The inspected implementation has no accounts, advertising, analytics, tracking SDK, application backend or cloud synchronization. Trials, notes, sessions, favorite/recent IDs, settings and attempts use the existing local SQLite/preferences repository. CSV export is explicitly requested by the learner and invokes the operating-system share flow. The app does not choose a recipient. Notes are user content and may be included in exported trials.

## Microphone

The only main-manifest permission is `RECORD_AUDIO`, used contextually by Sound Spectrum after the user starts microphone mode. Generated signal mode works without microphone permission. The recorder streams PCM16 into a bounded memory ring; analysis runs through the existing top-level isolate callback. Navigation, backgrounding and disposal stop capture and invalidate stale jobs. Raw microphone audio is not automatically written to a file or uploaded. Explicit saved analysis retains scientific spectrum/frame metadata within the documented bounds; it does not imply a raw recording. iOS has a contextual microphone usage description, but iOS permission behavior remains untested on this Windows host.

## Export and recovery changes

CSV quotes fields and escapes embedded quotes. Phase 9 additionally prefixes formula-like free-text cells with an apostrophe when they begin with whitespace followed by `=`, `+`, `-` or `@`. Numeric scientific cells remain numeric, including negative values; the underlying note stored in SQLite is unchanged. This mitigates spreadsheet formula execution when a recipient opens an export.

Malformed trial/attempt bodies remain stored and are skipped with recovery notices. Rejected saved configurations are backed up before defaults can replace their session row. Raw malformed session envelopes are retained in a backup as well. No destructive reset was used to fix migration failures. Android automatic backup is now explicitly disabled (`allowBackup=false`) to align with the local-data design. OS/device-transfer and iOS backup policies are platform-level behavior and need device review; no app cloud service was added.

## Dependency/license evidence

[PHASE9_DEPENDENCIES.json](PHASE9_DEPENDENCIES.json) records resolved package versions and local license-file hashes. [PHASE9_THIRD_PARTY_NOTICES.txt](PHASE9_THIRD_PARTY_NOTICES.txt) contains those package notices and the inherited Flutter SDK license. A new Settings link opens Flutter's runtime open-source notices. [phase9-pub-outdated.json](phase9-pub-outdated.json) preserves the actual `flutter pub outdated --json` response, including advisory/retraction flags available from Pub at the time of review. It is not a guarantee against all vulnerabilities. Dependency upgrades were not applied merely because a newer version exists.

Source scanning for common private-key/API-key patterns found no matches in `lib`, `android` and `ios`; credentials/keystores are not committed. This bounded pattern scan is not comprehensive security certification. Debug/profile manifests contain development network permission for Flutter tooling; check the release artifact's merged manifest separately. App source contains no application HTTP/socket client. An offline launch test demonstrates offline operation, not proof that every possible OS-originated packet was captured.

No project-level source LICENSE file exists. The intended public-source redistribution terms and any unresolved third-party/data rights should be established before publication; no developer identity, ownership or license grant is invented here. Asset permissions, required credits and known provenance limitations are consolidated in [PHASE9_ASSET_REGISTER.json](PHASE9_ASSET_REGISTER.json) and the earlier asset reports. The original user target boards remain excluded from the bundle and Git.
