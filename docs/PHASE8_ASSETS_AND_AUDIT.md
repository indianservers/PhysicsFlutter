# Phase 8 assets and earlier-module audit

Inspected all six panels on each supplied board: `17_Astronomy_and_Astrophysics.png` and `01_Concept_Overview.png`. The originals remain untouched in excluded `Target UI/`; no entire mockup is a working screen or bundled app asset. Scientific values are calculated/reference data, never copied from decorative board readouts. In particular, a named Kepler-22b image/parameter combination was not invented, cosmological distance types are separated, and heuristic practice correctness is not labeled as a validated ability score.

## Planet surface graphics

Eight small maps originate from the [NASA/JPL Solar System Simulator texture pages](https://space.jpl.nasa.gov/tmaps/). Per-file source URL, source checksum, processing/classification and credits are in [the texture manifest](phase8-texture-sources.json). Modification: resize at most512×256, JPEG88, educational sphere projection and directional sunlight/shadow. They are not scientific surface-analysis data, current atmospheric appearance or live sky photographs.

- Mercury: Mariner10 partial mosaic; Caltech/JPL/USGS, processed at USGS; limited longitudes and gaps.
- Venus: JPL/Caltech Magellan **radar composite**, gaps filled; not a visible-light view through clouds.
- Earth: Caltech/JPL/USGS processed topographic land/ocean illustration; underlying source listed unknown by the source page. Marker represents the Earth–Moon barycentre, not a resolved lunar ephemeris.
- Mars: Viking mosaic, Caltech/JPL/USGS processing.
- Jupiter: heavily processed Voyager representative mosaic, David Seal, JPL/Caltech.
- Saturn: **Don Davis artist impression**, fictional storm features, owner JPL/Caltech.
- Uranus: **David Seal solid-blue artist impression**, owner JPL/Caltech.
- Neptune: **Don Davis artist impression**, fictional clouds, owner JPL/Caltech.

The selected type is explicitly labeled in the viewport. Courtesy NASA/JPL-Caltech; USGS and named creators credited. [JPL Image Use Policy](https://www.jpl.nasa.gov/jpl-image-use-policy/) permits credited uses subject to its stated exceptions; no logo/person appears and no NASA/JPL endorsement is claimed. This is permission under that policy, not a blanket assertion that every JPL image is public domain.

## Original scientific illustrations

Star: original schematic surface/illustrative color/log-compressed radius driven by actual MIST luminosity/temperature/radius, not a photographic observation or arbitrary image-morph track. Telescope/spectrograph, detector, supports and material highlights are original Canvas apparatus using existing LabMaterials. The synthetic spectral strip is a false-color visualization, not eye color/observed stellar flux. Galaxy is an original labeled schematic morphology with a physical model-radius probe, not a NASA galaxy photograph or photometric fit. FLRW grid is explicitly schematic and homogeneous; spacing follows scale factor without a preferred explosion origin. Transit star is intentionally uniformly bright to match the exact supported model; no decorative limb darkening.

Existing dimensional studio icons/materials remain original procedural artwork. All17 studio icons, home/studio pages and representative earlier labs were inspected/captured before and after. Coverage includes instruments, free bodies, projectiles, friction, gravitation/orbits, oscillations, waves, optics, circuits/fields and ordinary-temperature thermal apparatus. No unjustified thermal steam/glow or literal quantum orbits were introduced. Existing calculations/data retained; baseline223 tests passed before changes.

## Significant corrections and evidence

- Home studio cards previously advertised only studios1…11 as interactive, leaving Electronics/Thermal/Fluid/Modern looking unfinished despite Phase7 availability. Cards now use actual catalog availability for every lab studio; tools have their own availability. Compare `phase8-before-home.png` / `phase8-after-home.png` and relevant studio captures.
- Introductory Concept Overview placeholders became six real tools, with exactly the original IDs and distinct tool activity criteria. Before/after files cover each `s00-e00…05`; full map/list, relationships, paths, saved/favorite launcher, five comparisons and real challenge attempts are captured.
- Astronomy introductory placeholders became six model/data-backed workspaces, all five sections. Captures cover `s16-e00…05`, every model selection verified; extra physical/compressed-scale, artist-impression, late stellar, high-resolution spectrum, no-transit/grazing and actual graph examples.
- Shared plots gained opt-in uncertainty bars for the real SPARC observations; old plot calls preserve behavior. Planet sphere geometry cache expanded from4 to bounded12 resources so eight textured planets do not churn the old cache every frame; owned image meshes are explicitly released on dispose. Orbital paths and ellipse circumference values are bounded/cached. No new dependency/permission.
- Fixed an actual overview ExpansionTile/PageStorage collision found in tests: expansion state now has unique keys rather than interpreting a scroll offset as a boolean. Atlas cards grow to their text instead of clipping large labels. Current scientific units and profile axes remain explicit.

Raw native PNGs are in `screenshots/phase8-*`; contact sheets are QA aids, source screenshots unchanged. Neither the supported model labels nor shaded graphics claim photorealistic target-board parity. Remaining art gaps: original vector telescope/galaxy/star renderings have less photographic detail than the boards; older apparatus/icon style could receive further consistent polish in Phase9. Accessible lists, numeric controls and large-text layouts are tested; independent TalkBack/VoiceOver user review is still required.
