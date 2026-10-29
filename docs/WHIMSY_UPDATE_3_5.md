# 3.5.0 — The Whimsy Update

This release adds a gentle storybook layer to both adventures. Original painted characters, furniture, routes, jump physics, collectibles, quests, input, contact shadows and save formats remain intact.

## A different kind of wonder in each room

| Setting | New details |
|---|---|
| Library Ladder | Flowering arch garlands, trailing vines, pressed-flower plates and folded paper swallows |
| Bedroom Beanstalk | Faded cloud murals, crescent-and-star mobiles, embroidered bedding and cool pastel washes |
| Invention Attic | Constellation charts, little ringed-planet mobiles, crescent sky windows and brass-toned accents |
| Original school | Botanical/paper garlands and a folded-paper bird display |
| Discovery garden | Wisteria at canopy edges and small painted flower borders |
| Invention workshop | A brass celestial mobile beside the original painted machinery |

Woven floor rugs tie the climbing rooms together. Small paper moths, petals and light accents appear throughout both adventures and the opening garden menu. They stay subtle around the active climbing lane; their silhouettes are distinct from discoveries and checkpoint icons.

## Motion, layering and cost

`whimsy_layer.gd` draws the moving accents in one canvas. Spatial cell IDs produce deterministic world anchors. Viewport culling limits work to at most 48 decorations, with no scene nodes or particle emitters created during travel. The scenery continues to render five nearby 760-pixel bays regardless of climb height.

The animation clock stops while a pause/modal is open. Reduced motion is read from shared settings on every frame, including while Settings is open: it immediately selects still poses and retains the decoration. Resuming normal motion resumes the clock. Menus remain above the new accents and keep their established focus/input behavior.

`story_whimsy.gd` records static drawings once, separately from the existing scenery's ambient clock. Foreground flower borders remain below the walking surface. The existing soft contact shadows, supporting-surface queries, room lighting and finish shaders are retained.

## Verification

The added Whimsy suite exercises actual menu, pause and settings paths across all three climbs and all three original rooms. It checks immediate reduced-motion changes while paused, stable anchors during camera travel, bounded decorations and node counts, collision-free integration and preserved progression. The existing graphics suite verifies original characters, collision routes, shadows, HUD layouts and native captures at floor, middle and summit heights.

The full source suite, native screenshot review, production Web browser checks and Windows release checks run in the repository workflow. This is a Godot 4.4.1 Compatibility-renderer release. Hardware-specific frame rates and physical mobile testing are outside the verification scope.
