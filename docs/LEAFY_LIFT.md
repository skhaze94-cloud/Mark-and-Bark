# Leafy Lift update

Platforming is now part of the main story rather than just an optional reward route. The original characters, storybook palette, foot pivots, lighting, fixed scenery, live board, room transitions and workshop remain intact.

## Main route

1. Read the hallway invitation and enter the garden.
2. Climb the entrance log (top 550), then double-jump onto the book tower (top 290). Land beside the design and interact.
3. Collect the misplaced plant on the safe ground and restore the stump display.
4. Climb the rightmost garden log (top 490), double-jump left onto the leaf ledge (top 240), then hop right onto the book shelf (top 190) and collect the base.
5. Drop to the ground and use the unlocked shortcut or the classroom entrance. Climb the first classroom book ledge (top 470), double-jump onto the pencil platform (top 250), then hop right to the shelf (top 260) for the pencil.
6. Return to the desk, assemble, test and deliver the plane as before.

The first jump rises approximately 154 px. Required 260, 250 and 220 px steps make Bark's second jump useful and necessary on these routes. Hold direction, jump, then press Jump again near the first apex. Wide platforms and floor landings allow unlimited retries. Supplies must be collected while standing beside them; smaller vertical pickup reach prevents ground grabs. Quest inventory persists between rooms and after checkpoint restarts.

Bark supplies the leafy lift and increasingly ridiculous advice. Mark responds with curiosity and sensible alternatives. Dialogues are skippable; airborne banter uses a brief toast, rotates across four exchanges, and is limited to once per seven seconds. Hints provide the real route without joke directions.

## Verification

Godot 4.4.1 full-path regression checks cover tutorial completion and skipping, real-input climbs on the required routes, ground pickup prevention, keyboard and emulated touch double jumps, camera tracking, stable scenery, room persistence, safe retries, workshop misses and success, ending exploration, local saves, settings, and missing-asset fallback. Physical mobile hardware and child playtesting have not been tested.

Result: **153 passed, 0 failed** in both headless and native OpenGL Compatibility runs. Window-close audio shutdown also passes.

Native visual review renders 26 fixtures, including the three required supply routes. Labels were moved clear of characters after visual inspection.
