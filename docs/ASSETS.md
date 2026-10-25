# Asset provenance

## Supplied references

All 17 PNGs in `Target UI/` were supplied by the user. They were inspected as a complete contact sheet; `02_Measurement.png` was additionally inspected at full size. Their source and license beyond user supply are unknown. They are preserved unmodified, are not declared as Flutter assets, and are not rendered as app screens. `mockup-contact-sheet.jpg` is a locally generated inspection derivative only. Do not redistribute the references without establishing rights.

## Original application graphics

- `lib/core/rendering/apparatus.dart`: original procedural Flutter CustomPainter apparatus. Intended use: rulers, caliper, micrometer, spherometer, balance/track and error bars; simplified studio illustrations. No downloaded bitmap, texture or external 3D model. Metal/glass/wood appearances are gradients and repeated vector strokes. Movable components derive from experiment state. No third-party asset attribution applies to these original project drawings.
- `android/app/src/main/res/drawable/physics_icon.xml`: original vector flask mark in cobalt, white and teal, created for this application.
- Flutter-generated launcher and web icon PNGs remain in platform scaffolding; Android uses the original vector above. iOS icon replacement/branding still needs final review before distribution.
- UI icons: Material Icons bundled by Flutter (`uses-material-design: true`). Source https://github.com/google/material-design-icons , Apache License 2.0. No modifications to glyphs.
- Font: platform `sans-serif`, supplied by the operating system. No external font files or network font loads.
- Equations: flutter_math_fork's bundled math rendering assets, under that dependency's included license. Flutter collects dependency licenses through its normal license registry.

## Known visual gap

The app is implemented with actual widgets, controls and procedural scenes. It does not reproduce the mockups' photorealistic 3D apparatus or photographic studio thumbnails. The current representations are schematic with material shading. Unique licensed photorealistic assets, a final iOS icon set and additional apparatus art polish remain product-quality review items. No unsupported 3D plugin was introduced.
