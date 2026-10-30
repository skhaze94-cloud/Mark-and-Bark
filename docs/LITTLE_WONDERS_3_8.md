# 3.8 — The Secret Life of Little Things

Three optional miniature lives belong to the opening Library Ladder climb. They use softly shaded paper-and-felt illustrations within the painted world, alongside the existing 3D Mark and Bark. They are not new 3D character meshes.

| Encounter | Location | Interaction and aftermath |
|---|---|---|
| Pencil Patrol | Starting floor, x680 | A flower signal opens, a beetle family carries its post across the markings, and the captain keeps watch. |
| Snail Mail | Checkpoint shelf 10 | A snail receives a tiny invitation: tea at the roof. A letter remains on display after delivery. |
| Thimble Tea | Checkpoint shelf 22 | Two dust bunnies raise their cups beneath a leaf parasol. Their table gains a flower after the visit. |

Approach on the supporting surface and use the existing **E / Enter / touch Use** action. Interactions remain optional and leave movement available. Each reveal takes six seconds; repeats are available after a three-second cooldown. The quest and delivery interaction retain priority.

The three discoveries appear in Mark's Notebook. A new optional `wonders` integer array in the existing climbing runs stores them. Older version 1/2 saves receive an empty list; valid quest, leaf and checkpoint progress survives. Only IDs 0–2 belong to the first climb; duplicates, fractions, booleans, strings and out-of-range values are discarded. Replaying the climb resets its discoveries together with that run.

Pause and modal settings freeze both encounter time and ambient motion. Reduced motion resolves the reveal immediately into a still completed tableau. If an encounter is interrupted by leaving the level before completion, it can be started again. A failed save uses the existing visible retry flow.

The encounter layer has no collision objects and creates no nodes or particles while playing. Drawing is bounded to three authored anchors and culled outside the camera. Bark's normal companion position moves to the free side near a miniature resident so he does not cover it. The mailbox and party sit on quiet checkpoint shelves away from patrol hazards.

`scripts/little_wonders.gd` owns the illustrations, state, prompts and staging. `mega_level.gd` creates it only for level zero. `mega_main.gd` routes the existing interaction, touch affordance, companion placement and Notebook text. `mega_state.gd` validates and persists optional discoveries.

`tests/wonders_review.tscn` checks real E and touch input, supporting-surface reachability, companion clearance, repeat suppression, pause, reduced motion, Notebook entries, cold save reload, backup recovery and malformed/legacy saves. Native mode additionally captures waiting, reveal and aftermath for all three encounters. The existing thirteen regression suites continue to cover the story, complete climbs, characters, HUD and saves; the new suite is number fourteen.
