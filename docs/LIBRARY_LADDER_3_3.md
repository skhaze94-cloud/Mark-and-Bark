# 3.3.0 — The Library Ladder

This focused visual pass upgrades the first Giant Climb while preserving the complete adventure and existing artwork. The bedroom and attic retain their existing presentation.

- Painted bookcases and reading nooks replace the library's procedural book alcoves. Three alternating bay arrangements use existing illustrated furniture, lamps, noticeboards, books and plants. Only nearby bays are drawn, with fixed world coordinates and generous coverage above the summit.
- Warm, static window light and subdued background props create depth behind the brighter playable shelves. Existing atlas platforms gain a soft cast shadow without moving their top edge or collision surface.
- Both friends retain their painted sprites and existing scale. Independent ground shadows follow the supporting surface, shrink and soften as the character rises, and do not inherit character animation deformation.
- A narrower header separates the objective and counters. Shorter keyboard buttons and a bottom progress strip open the view. Touch mode moves progress clear of the unchanged movement, Jump and Use hit areas. Other levels restore their original HUD arrangement.
- Small rings mark Bark's spring, strong landings and saved checkpoints. These are bounded, pause with gameplay, clear between levels and disappear with Reduced motion. Existing pickup sparkles, checkpoint icons and sound cues remain.

The library keeps 24 main shelves, all three side nooks, its original 24 leaves, Bark token, quest item, delivery point, enemies and story. No character PNG, collider, route constant or player physics script is replaced.

Verification adds a dedicated 14-check library suite to the existing eight suites. It checks preserved collision landmarks, discoveries, painted presentation, both shadows, HUD separation, touch layout, pause/reduced-motion feedback and restoration of other levels. Native fixtures cover the first shelf, both district transitions and the summit. The existing complete climbing playthrough still physically traverses all required shelves and side routes, collects all leaves and finishes the story.

The official Godot 4.4.1 Web/Windows export workflow remains active. Its browser checks use the actual exported game and its Windows job executes the packaged release. This is a 2D art and presentation upgrade using supplied artwork; it does not introduce newly generated character designs.
