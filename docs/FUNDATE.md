# The Fundate — Small friends, giant possibilities

Built directly on grounded-interactions commit `ba128b781398759fd5b7a7e38dce9df277fc2332`. The anchored paintings and furniture, single live invention board, Godot 4.7 loading fix, original seven-step quest, room exits, invention retries and ending remain in place.

## Opening

A 15-second ray sequence plays for a first/new adventure and Play again. Bark promises to make everything bigger, then discovers his ray dial says SHRINK. Both character sprites scale smoothly around their supplied feet, from Mark 0.42 / Bark 0.35 to Mark 0.24 / Bark 0.20. The world is fixed throughout the reveal. A book-supported oak-and-pencil ray and a soft, sustained gold beam are drawn with native Godot geometry; existing artwork supplies the room, characters, books and pencil.

Skip with E, Enter, Escape, or the large touch control. Skipping produces the same tiny-character state and hands off to the tutorial. Reduced motion uses a static size change and a steady beam instead of animation. The optional campus film remains accessible separately. Watching either sequence does not consume supplies, complete quests or remove discoveries.

## Double jump

- First jump: upward speed 620 px/s; air jump: 590 px/s; gravity: 1250 px/s².
- Up to one additional airborne jump; a third press cannot add lift.
- Landing recharges both jumps. Walking off a ledge retains one rescue jump.
- Existing 140 ms coyote time and 160 ms input buffering remain. Keyboard echo cannot auto-trigger the air jump.
- The same Space, W, Up or touch Jump control performs both jumps.
- A gold wind ring, slightly higher audio pitch, remaining-jump text and Bark's cheer explain the lift. Rings stop under reduced motion.
- The tutorial teaches the air jump as its own step after the log. That step requires a fresh air jump, even if the player already double-jumped over the log. Skipping the tutorial enables both jumps immediately.

Mark's collision capsule matches the smaller sprite: 96 px tall, radius 14, foot anchored. Movement speed, smooth acceleration, safe floor, generous interaction ranges, collectible persistence and nearby restarts remain unchanged.

## Higher routes

| Room | Optional route | Landing heights above the 610 px floor | Discoveries |
|---|---|---|---|
| Hallway | Book-Spine Skyway | 90, 205, 325 px | Leaf 1 |
| Garden | Leaf-Top Lookout | 355, 360, 325 px, reached from the original branch route | Notebook page 1, Bark token, leaf 4 |
| Workshop | Pencil Express | 140, 260, 350 px | Leaf 6 |

Books have cream pages and gold covers; pencils have an eraser and bright landing seam; leaf ledges have oak outlines, veins and a broad landing edge. A diamond landing mark helps distinguish playable surfaces from the flat background. One-way collision aligns with each painted top. All routes are optional; original required books, plant, notebook and pencil stay on the accessible quest route. There are still exactly six optional leaves, two notebook discoveries and one Bark token.

The camera follows high jumps vertically, anticipates ascent, stays inside the current room horizontally and extends the workshop ceiling above the painting. Bark follows the player's elevation and provides the lift pose. Both character shadows project to nearby supporting geometry rather than floating beside airborne feet. Furniture and backdrops stay fixed in world space.

## Save compatibility

The application name and `user://big_idea_save.json` path remain unchanged. Version-1 saves continue to load. The new `shrunken` boolean defaults safely for old saves; tutorial completion still determines whether Continue resumes the campus. Story progress, discoveries and accessibility settings survive room changes, checkpoints and tutorial replay.

## Verification

See `fundate_verification.json` for the full automated result. The runtime path covers title, ray animation/skip/reduced motion, tutorial, actual keyboard and native touch jumps, third-jump blocking, landing recharge, walking-off rescue, physics-driven climbs of all nine new ledges, high-jump camera tracking, every quest step, missed-flight retry, successful delivery, ending, optional discoveries, room return trips and disk save/load.

Rendered OpenGL Compatibility fixtures cover the ray before/after shrinking, tutorial, rooms, high platforms, camera ascent, touch UI, live board, workshop controls and optional film. The displayed native character pivots and shadows were reviewed. Tests use Godot 4.4.1 on Linux/Mesa. This release retains the existing 4.7 compatibility fix; it has not been re-tested in a separate Godot 4.7 installation or on a physical phone. Children's play duration has not been measured.

No new generated raster artwork or external dependencies are required for this update. Platform and ray art are editable native draw code; all original artwork is bundled.
