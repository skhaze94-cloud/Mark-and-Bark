# Mark & Bark — Mega Variety 3.1: The Complete Climb

A finished, child-friendly 2D platform adventure for Godot. A shrinking-ray mishap turns school and home into three towering playgrounds. Mark and his mischievous tree friend Bark must recover a design, a power cell and a lens, then repair the ray together.

**This release rebuilds the unpublished Mega Variety expansion on the verified 2.0.2 source and adds a full gameplay, visual, interface and save-recovery pass.**

## Play

1. Extract the ZIP into a fresh, writable folder.
2. Open **Godot 4.4.1**, choose **Import**, and select `project.godot`.
3. Let the bundled art and font import. Press **F5**.

Everything needed to play is bundled. No paid plugins, .NET, Python or extra asset downloads are required for the game. This is an editable Godot project, not a standalone executable. Python is only needed for the optional verification tool.

## Three much bigger adventures

| Climb | Setting | Main platforms | Ascent |
|---|---|---:|---:|
| The Library Ladder | School reading nook, pencil crossing and roof library | 24 | 4,410 px |
| The Bedroom Beanstalk | Toy corner, wardrobe trail and window garden | 27 | 5,400 px |
| The Invention Attic | Workshop floor, thread loft and ray observatory | 33 | 7,080 px |

Each ascent is **three times the height of 2.0.2**. Every level has 24 optional leaves spread through its full height, three reachable side nooks and one hidden Bark token. The quest item is on the platform just below the summit. Land beside it, collect it with **E / Use**, then deliver it at the summit.

The route has six new painted platform materials: books, pencil bridges, rulers, erasers, thread spools and timber ledges. Cream landing seams, numbered shelves and checkpoint bulbs make the way readable. Broad bridges offer breathing room between higher jumps.

![Mark, Bark and a dodge encounter in the attic](docs/previews/complete_climb_3_1.png)

## Two jumps, one team

Move with **A/D or arrows**. Press **Space** to jump, then press again near the first apex to spring off Bark. Bark anticipates the first jump, braces beneath Mark and eases back into position after release. Jump input responds immediately. Landing recharges both jumps; walking off a ledge still leaves a rescue spring. There is no third airborne jump.

| Action | Keyboard | Touch |
|---|---|---|
| Move | A/D or Left/Right | Hold an arrow |
| Jump / Bark spring | Space, W or Up | Tap Jump, then Jump again |
| Collect / deliver | E or Enter | Use |
| Hint | H | Bark’s hint |
| Notebook | N | Notes |
| Highest checkpoint | R | Checkpoint |
| Pause | Escape | Pause |

Touch controls appear after a touch event or through **Always show touch controls** in Settings. Hold movement with one finger and jump with another. Use landscape orientation.

## Small pests, forgiving retries

Eraser beetles pace, dust bunnies bob and paper moths flutter. Mark gives a practical dodge tip when approaching. Enemies occupy the far side of a landing, leaving room to arrive safely. Jump or spring past them. Mark has **no attacks, weapons or powers**.

A bump returns Mark to his last safe shelf with every quest item and collectible intact. A recovery window prevents immediate repeated bumps. **R / Checkpoint** returns to the highest saved rest shelf. Both recovery paths place feet above the platform, then settle safely on it.

**Calm climb** lets players pass pests harmlessly. It does not alter jumps, routes or collection rewards. This preference remains available across new adventures. Pause and dialogue freeze patrols and recovery timers.

## The 3.1 quality pass

- Clearer title, illustrated level selection and a redesigned notebook with objective, discoveries, nooks and checkpoint progress.
- Practical return hints for all nine side routes; important tips remain readable when a leaf is collected.
- Smooth Mark-on-Bark contact and release, quick double taps, direction changes, low-ceiling landings and clean checkpoint resets.
- Bark leaves pests visible instead of standing over their silhouettes.
- Correct desk, mug and lamp placement using supplied prop pivots; bracketed wall shelves support the attic lamps.
- Layered timber, window lighting, soft grounding shadows and independently anchored scenery.
- Backdrop coverage includes jumps above the summit. Nearby scenery bays draw at fixed world positions with generous overlap, bounding rendering cost.
- Master volume, music, reduced motion and touch settings. Reduced motion removes extra bobbing, wing flutter, dust and camera easing while preserving readable gameplay.
- Atomic saves, compatibility with earlier campaign saves, validation of malformed values and recovery from the previous valid backup.

## Ending and replay

The final delivery repairs the ray and plays the restored-size story ending. Explore afterwards, revisit unlocked levels, or Replay a climb for a fresh collection run while keeping best scores. Optional discoveries never block the story.

The original school adventure, tutorial and paper-plane workshop are still included: open `scenes/main.tscn` and press **F6**. Its progress and sound settings remain separate from the campaign.

## Saves

The campaign uses Godot’s standard user-data folder for **Mark & Bark: The Big Idea**. `mark_bark_mega.json` stores campaign progress and calm mode; `.bak` holds the previous valid save. Version 1 saves retain unlocked levels, earlier checkpoints, discoveries and best scores. Version 2 supports the extended upper checkpoints and all 24 leaves. Settings for sound, touch and reduced motion use the existing original save.

The application name stays unchanged so previous save locations remain compatible. New adventure asks before resetting this campaign and its scores; accessibility preferences and original-chapter progress are preserved.

## Verification and editing

The complete, isolated check suite runs with:

```sh
python3 tools/verify.py --godot /path/to/Godot
```

It imports a fresh project, uses temporary test saves, runs all five suites and writes logs to the ignored `test_output/` folder. **540 checks pass**: 198 campaign checks, 85 variety/recovery checks, 61 interface checks, 21 teamwork-jump checks and 175 original-chapter checks. The campaign test physically climbs every required shelf and all nine side routes, collects all 72 leaves, delivers all three quest items, exercises keyboard and multi-touch input, checks safe checkpoints and completes the ending.

Native Godot compatibility-renderer playthrough and visual fixtures were also reviewed. See [release notes and artwork provenance](docs/RELEASE_3_1.md) and [verification results](docs/release_3_1_verification.json).

Physical Android/iOS device testing and standalone platform exports are outside this source-project delivery. The tests cover keyboard, mouse and injected multi-touch events in Godot.
