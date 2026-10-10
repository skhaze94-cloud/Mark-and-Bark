# Mark & Bark: The Big Idea

A playable Godot 4.4.1 project: a garden tutorial, one connected school campus, a seven-step story quest, optional discoveries, and a retryable paper-plane invention workshop.

## Open and play

1. Extract the project ZIP into a folder.
2. Open Godot **4.4.1 or a newer compatible Godot 4 release** (the standard editor; no .NET requirement).
3. In the Project Manager, choose **Import**, select `project.godot`, and open it.
4. Wait for the supplied textures and font to import, then press **F6** with `scenes/main.tscn` open or **F5** to run the project.

No paid plugins, external services, build tools, or asset downloads are needed. The used artwork is bundled in `assets/`. The project ZIP contains editable source, not a standalone operating-system executable. Godot is required to play it this way.

## Controls

| Action | Keyboard | Touch |
|---|---|---|
| Move | A/D or left/right arrows | Hold left/right controls |
| Jump | Space, W, or up arrow | Jump |
| Interact / next dialogue line | E or Enter | Use / Next |
| Bark's hint | H | Hint button |
| Pause | Escape | Pause button |

Enable **Always show touch controls** in Settings for touchscreen testing. Movement and jumping support separate fingers. Dragging out of a movement control releases it. Native screen-touch events are handled explicitly rather than relying only on first-finger mouse emulation.

Settings include sound volume and reduced motion. Every sound has a visible counterpart. Story dialogue can be skipped, the tutorial can be skipped or replayed, and mistakes do not remove inventory or discoveries.

## Adventure

Learn movement, jumping, notebook interaction, leaf collection, hints, and plane launching in the quiet garden. Then explore a connected hallway, discovery garden, and classroom workshop.

Recover Mark's notebook, return Bark's misplaced plant, gather the books and pencil, assemble the machine, and deliver the invitation to the fair board. The garden includes an elevated route, six optional leaves, two comic notebook entries, a hidden Bark token, and a shortcut unlocked by helping the garden.

The launcher has three angles and three power choices. Missed planes return automatically. A hint reveals a reliable combination and its trajectory. The ending celebrates discoveries and leaves the campus open for exploration.

The main route is a compact introductory slice. The requested 15–20 minute experience is a design target for relaxed exploration; it is not a measured child playtest result. Experienced players can finish substantially faster. Dialogue and exploration can be expanded through the editable scripts.

## Saves

Quest progress, discoveries, completed tutorial, settings and safe ground checkpoints are stored in `user://big_idea_save.json`. Save writes use a temporary file followed by replacement. New Adventure and Play Again explicitly reset the quest; tutorial replay preserves the existing main quest. Restart Checkpoint preserves inventory and discoveries.

## Project structure

- `scenes/main.tscn`: main scene.
- `scripts/main.gd`: story, tutorial gates, quest interactions, UI, touch input and launcher.
- `scripts/player.gd`: CharacterBody2D movement, coyote time, jump buffering and aligned key poses.
- `scripts/campus.gd`: connected level layout, props, platforms, pickups and collision geometry.
- `scripts/progress.gd`: persistent state and save validation.
- `scripts/art.gd`: manifest-backed texture access and missing-image fallback.
- `assets/index.json`: the subset of the supplied pack used by this introduction, including pivots.
- `tests/playthrough.tscn`: deterministic runtime regression scene.
- `docs/`: validation report, asset provenance and implementation notes.
- `export_presets.cfg`: optional Web export preset. Export templates are required only if you choose to export.

## Verification

Tested with Godot 4.4.1 on Linux. Run the regression suite using:

```sh
godot --headless --path . res://tests/playthrough.tscn
```

The suite exercises a complete tutorial and campus playthrough with keyboard input and actual CharacterBody2D physics, GUI touch events, assembly, a missed launch and successful retry, ending, optional discoveries, checkpoints, save/load, reduced motion and missing-art fallback. Results are written to `test_output/playthrough.json`; the test restores any pre-existing save after completion.

This is single-player. There is no combat, timer, punishment meter, online service, 3D content, or complete multi-age game. The character art is supplied animation key poses, so pose transitions use deliberate low-frequency steps and stable foot pivots. Future production animation can replace those frames without changing the quest systems. Actual tablets and phones have not been physically device-tested. A graphical visual review could not be completed in this environment; native headless execution and Web export compilation succeeded.

## Art and sound

Mark and Bark artwork comes from the supplied detailed asset pack. Original pack metadata and art notes are retained in `docs/source_asset_manifest.json` and `docs/ART_ASSETS.md`. Character foot anchors use (256, 612) on the supplied 512×640 canvases. Surface tiles use mirrored repeat; all walkways and collision shapes are separate from the flattened backdrops.

Short audio cues are original generated sine-wave tones. `assets/readable.ttf` is DejaVu Sans; its license notice is included. No rights to third-party logos, franchises, or unrelated assets are implied. The repository contains the supplied creative material and the implementation; no new license is imposed on the owner's game or artwork.
