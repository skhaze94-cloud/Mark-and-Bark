# Ultimate Polish 2.0

This release refines the three-level Mega Vertical Adventure while retaining its authored climbing routes, quest items, 24 leaves, three hidden Bark tokens, original artwork and compatible campaign saves. The earlier Big Idea chapter remains available through `scenes/main.tscn` and F6.

## What changed

- **Quest identity:** new native vector power-cell and golden-lens icons match the story, replacing mood tokens used as temporary supply representations. They use 256 × 256 canvases and a (128, 235) prop anchor in the asset index.
- **Campaign HUD:** a pictorial quest objective, a bounded height meter, current shelf/total count, existing collectible counters and two-jump readiness. Interaction brackets identify the current quest pickup or delivery point.
- **Readable feedback:** cream-on-navy notice and interaction cards, more room and reading time for long notices, and paused reading time while menus are open. Notices reset between levels so messages from the last room do not appear in the next.
- **Navigation:** three illustrated level cards show themes, difficulty, unlock state and best discoveries. Back returns to the active climb when opened from gameplay. The title offers a clear How to Play screen. Escape from the ending returns to exploration.
- **Teamwork:** Mark's contact pose is fully opaque rather than crossfading into a second ghost image. Bark's spring follows facing direction. The original sprite pivots, collisions, two-jump limit and landing recharge remain intact.
- **Recovery and rewards:** checkpoint bulbs become completion checks; retry restores the shelf counter. A hint from the secret branch directs players to the reachable return shelf. Discoveries collected after completion immediately improve best scores, without another delivery.
- **Transitions:** a short, input-safe fade joins consecutive levels; reduced motion switches immediately. The ending includes a correctly sized science rosette.
- **Scenery:** gentle room-specific lighting and a subtle frame vignette, more detailed book bindings, wardrobe side faces and attic beam hardware. The single classroom board updates after recovering the design. All furniture and collision geometry remain anchored to the world.
- **Performance:** static scenery retains its drawing between events. Only a separate, small dust layer redraws for decorative movement, capped at 20 updates per second. Reduced motion disables the particles. This is a rendering-work reduction, not a measured FPS claim.
- **Audio and controls:** master volume updates active feedback audio immediately. Visible touch movement arrows can also be held with a mouse. Keyboard and multi-finger touch remain supported.
- **Layout fixes:** dialogue portraits, level icons and reward pictures now set their texture after configuring sizing. This prevents native texture minimum dimensions from expanding them beyond the intended panels.

## Validation

`tests/mega_playthrough.tscn` physically climbs every required platform and optional branch, collects and delivers all quest items, obtains all leaves/tokens, completes the restored-size cinematic, and checks keyboard, multi-finger touch, checkpoints, retries, pivots and save/reload.

`tests/polish_review.tscn` checks menu bounds, portrait sizing, readable notices, paused reading time, checkpoint visuals, crisp contact, secret-route hints, post-ending best scores, level-select/ending Back, fade input protection, reduced motion, mouse-held controls and immediate mute. Run with `-- --screenshots` under a native renderer for visual fixtures.

`tests/playthrough.tscn` verifies the preserved original chapter. The packaged source is freshly extracted, imported and tested again. See `polish_2_0_verification.json` for results.

This remains a 2D storybook game with layered depth effects. The release is editable Godot source; physical phone/tablet testing and standalone operating-system executable exports are not claimed.
