# 3.4.0 — Painted Depth

A complete presentation pass for both adventures, using the supplied paintings and native 2D lighting techniques. The original character PNGs, animation controls, collision shapes, routes, discoveries, quests, save formats and both adventures remain intact.

## Environments
All three climbs receive composed 760-pixel scenery bays with distinct ascent zones, painted furniture and soft directional shadows. Library light is warm; bedroom light is cooler and gentler; the attic uses amber desk-lamp tones and darker timber framing. Only five nearby bays are painted. Furniture stays at fixed world coordinates; scenery adds no collisions.

The original school, discovery garden and workshop gain feathered window light, soft ambient glows, floor contact shade and projected decorative shadows. Only distant garden silhouettes have restrained parallax; gameplay objects and furniture remain anchored. Reduced motion removes that parallax and foliage movement, and pause freezes ambient clocks.

## Shadows and finish
One shared contact-shadow renderer follows each actor in the correct coordinate space. It keeps the footprint on its supporting surface, reduces the footprint and opacity as the actor rises, adds a gentle directional cast and a dark contact core, and follows source visibility. Fixed prop shadows stay at their anchor. The old player-drawn shadow is disabled only in the two controllers using the replacement, preventing double shadows; player mechanics are unchanged.

The atlas renderer supplies soft shadows and a quiet underside band for climbing platforms and inherited original-story platforms. Painted top edges, landing seams and collision surfaces do not move.

A restrained five-tap highlight bloom, gentle contrast and room-specific grading sit below the HUD. Menus and text remain outside the world finish. There is no requirement for a 3D renderer, HDR or hardware ray tracing.

## Verification
The existing nine suites remain, including the complete original story and all three climbs. A new graphics suite tests every actor's grounded/airborne shadows, transformed source parents, visibility, cleanup, one-shadow ownership, exact route/collider preservation, pause, reduced motion, touch HUD layout and missing artwork. Native tests also compare rendered shadow alpha/footprint and capture floor, middle and summit fixtures for each climb plus the three original rooms. Screenshot staging freezes physics and verifies that no progression changes.

The same CI run compiles Godot 4.4.1, exports production Web and Windows builds, exercises the release packs in fresh save/resume/recovery processes, plays the Web build in Chrome and executes the Windows release on Windows. Logs, native images, review sheets, editable source and builds are published as artifacts. Hardware performance and physical mobile-device measurements are not claimed.
