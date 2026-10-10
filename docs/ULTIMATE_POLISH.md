# Ultimate Polish

Based on Fundate commit `d683ffb4d79629ce8fad47c41fc1913c5f3dc600`. This is a refinement of the same complete introductory chapter. The shrinking ray, double jump, campus skyways, required quest, room exits, single live invention board and ending are preserved.

## Presentation and animation

The title now stages both original characters in the garden, with a small imagined paper-plane arc and a clean edition label. Gameplay keeps Mark at miniature scale. The world-only highlight halo and corner vignette are gentler, retaining the original painted detail and crisp UI above the shader.

Mark uses the supplied running key poses at full speed and walking key poses during acceleration. A 65 ms crossfade uses a second Sprite2D with the same supplied `(256,612)` foot pivot, scale and position. A small jump stretch and existing landing squash stay foot anchored. Reduced motion removes the crossfade and extra stretch/landing effects. Physics values and the maximum two-jump rule are unchanged.

The new platform surfaces have layered shadows, book binding and ribbons, pencil grain and an eraser, and leaf veins and edge highlights. Landing produces a brief seam light and two quiet motes, with no movement of the platform or its collision top. Character shadows still use supporting geometry.

## Interfaces and interactions

The objective card adds task art, a numbered step or lesson count, and check-mark progress. Text, icons and shapes communicate progress together. The jump meter and toast text sit on dark cards with readable cream lettering. Dialogue shows a page count and keeps its short, skippable exchanges.

Gameplay HUD buttons cannot steal keyboard focus from Space. Menu buttons remain keyboard focusable and show a gold focus outline. Prompts follow the latest touch or keyboard input even when touch controls remain visible. Modals have a navy veil that blocks clicks through to the gameplay UI.

Pause freezes the real character position and velocity in midair, then resumes the same jump when closed. Inventory and quest progress are retained. The workshop uses three illustrated component cards. TextureRect expansion is configured before assigning item art, so both the small component icons and the ending rosette stay inside their specified bounds.

Pickup rewards use short-lived duplicate artwork and a gold ring after collection. The original world object remains anchored and is hidden through the normal inventory state. The invention plane has a restrained 14-point gold trail; misses and success clear it immediately. Reduced motion disables the moving trail and reward drift. The success screen has a static wreath-like confetti arrangement in reduced motion; otherwise a bounded set of paper leaves drifts only along the margins, outside the text and buttons.

Settings use the supplied readable font, navy text, explicit On/Off labels and two small native SVG toggle icons. The icons use the existing navy, gold and cream palette and do not depend on colour alone.

## Original soundscape

`assets/campus_music.wav` is an original, soft, 17.28-second plucked melody with warm chord tones. `assets/garden_ambience.wav` is an original 12-second wind/bird loop. Both are deterministic procedural recordings with no third-party samples. The optional reproduction source is `generate_soundscape.py` (requires NumPy only to regenerate; playing the game has no Python dependency).

Master volume affects both loops and action feedback. A separate music toggle is stored in the existing save settings, defaulting safely for older saves. Garden ambience fades in outdoor rooms and away indoors. Gameplay dialogue, pause and workshop panels pause the loops so reading stays calm. Missing loop files safely leave their players silent.

Window closing saves progress, stops all audio, and gives AudioServer 200 ms of real time to finish releasing its fading voices before quit. This avoids the resource-at-exit warnings observed during the first audio test. The test runners use the same drain method, and the separate window-close smoke test verifies the actual notification path. Related upstream context: https://github.com/godotengine/godot/issues/76745.

## Validation

- **141 full runtime checks passed**, both headlessly and with OpenGL Compatibility rendering on Linux/Mesa.
- The route covers title, shrinking intro and skips, tutorial, keyboard/touch double jumps, ledge rescue, every high route and discovery, all quest stages, assembly, missed/successful flights, ending, return room travel, checkpoints, save/load, input switching, menu focus, pause/resume and music preference persistence.
- UI regression checks verify assembly image limits, a 175×175 ending rosette, high-contrast settings labels and fully opaque reduced-motion poses.
- A separate close smoke test exits cleanly with no script, resource or audio-leak errors.
- **23 native render fixtures** cover title, ray, tutorial, rooms, high-route camera ascent, component cards, workshop, settings, touch UI, ending and optional film. Key scenes were manually inspected and corrected.
- Audio files were checked for finite samples, non-clipping levels and valid loop lengths. Original source is included for inspection.

See `polish_verification.json` for the full check list. Tests use Godot **4.4.1**. The previous Godot 4.7 loading fix remains, but this update has not been separately retested in Godot 4.7, on a physical phone, or in a timed children's playtest. The music is synthesized rather than a studio recording.

No new generated raster art is required by this update. All existing painted artwork is bundled; new platform detail, UI icons and effects are editable native drawing code or SVG.
