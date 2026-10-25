# iOS handoff — verification still required

This project was developed on Windows. No iOS compilation, simulator run, signing, VoiceOver check or iOS share-sheet check has been performed. Do not report otherwise.

The generated iOS Runner/Xcode project is present. Display name is Physics Atelier. Shared UI uses SafeArea, platform back gestures through Flutter routes, keyboard resize behavior and Material controls with native text editing. sqflite, preferences, equation rendering and file sharing all support iOS. There are no sensor permissions or Android-only dependencies in the shared scientific code. iPad sharePositionOrigin is supplied.

On macOS with current Xcode and Flutter stable:

1. Run `flutter doctor -v`, install platform dependencies, and `flutter pub get`.
2. Run `flutter build ios --simulator` and fix any toolchain/plugin issues. share_plus requires iOS 13 or newer; use a deployment target satisfying all resolved plugins.
3. Run `flutter test` then `flutter test integration_test/phase1_test.dart -d <ios-simulator-id>` (adapt Android-specific screenshot conversion in the test for iOS).
4. Exercise all six labs, keyboard input, interactive back swipe, background/pause/resume, force-close/relaunch, SQLite restoration and offline launch.
5. Verify file export on iPhone and iPad, cancellation, filename/type and an actual Files save. No external messaging is required.
6. Check VoiceOver descriptions and numeric controls; large Dynamic Type; small iPhone portrait; iPad split view; landscape/safe areas. Verify reduced motion and haptics on a real device.
7. Replace/review generated iOS icon PNGs with the final brand mark. Set signing team and release identity; run on hardware and profile before store distribution.

Phase 1 is an iOS-ready source foundation, with iOS verification explicitly pending.
