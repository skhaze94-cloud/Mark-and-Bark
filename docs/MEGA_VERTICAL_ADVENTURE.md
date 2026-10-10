# Mega Vertical Adventure

The default scene is now a three-level vertical campaign. The earlier Big Idea story/workshop remains an independently playable scene with its original save.

## Gameplay design

The school has eight broad main platforms, the bedroom has nine medium platforms and the attic has eleven narrower platforms. Every level includes one optional side shelf. Later rises exceed the first jump's roughly 150 px reach, making the Bark spring essential. Adjacent horizontal placements alternate across the climb. Sequential vertical rises prevent skipping the main ascent wholesale.

The routes are authored through `RISES` and `CENTERS` in `mega_level.gd`; no random layout generation occurs. Books, pencils and the leaf shelf share their painted landing edge with one-way collision geometry. Scenery uses separate world geometry. The safe floor catches falls; checkpoint bulbs save the highest reached safe landing without changing inventory. Required pickups are stationary, have generous 125 px interaction ranges and require a safe landing. Automatic optional pickup ranges are 80 px.

Each climb has its own quest item and delivery. Quest collection changes the objective; delivery unlocks the next level. Eight leaves and one Bark token per level reward exploration without gating completion. Fresh replays preserve best scores. The campaign has its own atomic save file and bounded loaded values, so old chapter saves remain usable.

## Teamwork animation

The second jump emits the existing player's `jumped(true)` signal. Mark uses the supplied crouch key pose during the initial 100 ms contact. Bark's hop export has a head-to-foot distance of approximately 301 native pixels. Its 0.18 contact scale puts the leafy top about 54 px above its foot, matching the anchor placed below Mark's feet. Bark then springs from the contact anchor while Mark releases into the jump pose. Both characters preserve their original pivots; animation does not move collisions or pickup positions. Reduced motion retains the contact and release poses with a stable scale.

## Presentation and access

School architecture uses bookcases, lockers, a single classroom board, oak library alcoves and window shafts. The bedroom includes a quilted bed, oak wardrobe, framed drawings, toy chest, mug and writing desk. The attic uses layered timber, beams, crates, books, a science volcano and lamps. Procedural furniture uses material grain, shadows and highlights. All scenery is anchored to world coordinates and the camera follows only the player.

The HUD shows the current level, one quest objective, leaf/Bark counts and jump readiness. Numbered shelves, checkpoint bulbs and a requested hint marker make progress readable. Keyboard shortcuts, multi-finger touch, pause, focus-loss recovery, adjustable audio, reduced motion, save/replay confirmation and skippable story are included. Brief jump banter is non-modal so it never interrupts a climb. Longer story exchanges pause physics.

The opening visibly shrinks both characters; the final ray visibly restores their size before the completion screen. Continued exploration returns to the miniature route. This is a 2D storybook game with layered depth effects, not new 3D character models.

## Validation

The automated campaign suite physically traverses every required shelf and all three secret branches, without teleporting through the main route. It checks quest pickup and delivery, all 24 leaves and 3 Bark tokens, increasing checkpoints, keyboard dialogue and navigation, pause, retries without inventory loss, unlocking, ending and post-ending exploration. Actual viewport touch events exercise movement plus jump with two fingers. Save/reload, original pivots, reduced-motion contact and the two-jump limit are checked.

Native OpenGL rendering and captured fixtures are used to inspect the themed floor/middle/top views, intro, ending, HUD and contact/release poses. The verified source is also extracted into a fresh folder and imported/run again before delivery. Results are recorded in `mega_verification.json`.

Physical phone/tablet validation and operating-system executable exports are not claimed. The downloadable project runs through the standard Godot editor without external dependencies.
