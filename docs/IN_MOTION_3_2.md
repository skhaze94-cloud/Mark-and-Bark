# Mark & Bark 3.2 — In Motion

This character-focused update adds independent body articulation and facial performance to the complete 3.1 campaign. Both characters keep their supplied painted identities, proportions, palette and `(256, 612)` foot anchor. All 24 action exports and 16 turnaround views were inspected. Their original PNGs are unchanged.

## Performance

Mark breathes and looks around while resting; his shoulders, elbows and wrists loosen while moving. Airborne poses add a reach, knee tuck, ankle response and toe follow-through. A landing settles through the body without moving the collision surface. Notebook and carried-object poses limit arm motion so their props stay held.

Bark uses multiple walking and running key poses rather than holding a single stride. His head, branch arms, hands and root legs move independently, with a little delayed motion in the crown and leaves. The existing Mark-on-Bark spring now drives anticipation, contact and release channels on both characters, followed by a restrained leaf burst at the launch point. Bark cheers on discoveries and performs in dialogue.

Calibrated expressive faces support staggered blinks, slight gaze shifts, brow movement and small mouth changes. The animated dialogue portraits frame the face and upper body. These are stylized gestures, not phoneme-based lip sync. The eyelid shader is enabled for the eight manually calibrated rest, jump, crouch and dialogue/cheer expressions; other key poses retain their painted faces. Back and side turnarounds use restrained breathing instead of forward-facing facial effects.

Input is immediate. Animation never delays the first or second jump, changes the impulses or adds another airborne jump. The original gravity, collision capsules, coyote time, jump buffering and all 84 main platforms remain intact. Pause holds the body and face; a checkpoint clears transient poses and particles. Reduced motion restores the joint rests, removes the facial deformation and suppresses the extra spring effects.

The missing legacy `young_actions_cheer` lookup now deliberately reuses Mark's expressive jump artwork with a celebration performance instead of creating the generic missing-texture square.

## Inspect and edit

Choose **Character animation studio** on the title screen, or open `scenes/animation_studio.tscn` and press F6. This scene is independent of the campaign and does not save quest progress. Its jump mode is a pose study; use the game for actual platforming and contact physics.

| Control | Action |
|---|---|
| 1–7 or pose buttons | Idle, Walk, Run, Jump, Bark spring, Talk, Cheer |
| Space | Pause or resume |
| Speed | Normal or half speed |
| Next frame | Pause and advance one frame |
| P | Show named joint points |
| Esc / Back to game | Return to the title |
| F8 in the campaign | Show or hide both characters' joint points |

`resources/character_motion.tres` exposes head, arm, leg, follow-through, face and tempo strengths, plus blinking. Edit these in Godot's Inspector. Both characters load the same tuning resource; the studio's playback speed is local to its actors.

`assets/rigs/character_points.json` contains 40 profiles in original canvas coordinates, measured from the top-left. Each profile stores joint positions, face regions and conservative constraints for held props and turnaround views. Adjust a profile to refine a particular painted pose, preserving the original canvas and foot anchor.

Every `Art.character()` actor now contains a real `Skeleton2D` and 26 `Bone2D` nodes. The hierarchy is visible in Godot's **Remote** scene tree while running:

| Group | Native controls |
|---|---|
| Support | FootLock, Hip |
| Head and follow-through | Head, Crown, LeafNear, LeafFar, Coat |
| Near and far arms | Shoulder, Elbow, Wrist on each side |
| Near and far legs | Thigh, Knee, Ankle, Toe on each side |
| Face | EyeNear, EyeFar, BrowNear, BrowFar, Mouth |

The original texture is drawn by a 475-vertex triangular `Polygon2D` mesh. Skin weights use at most four normalized influences per vertex and are cached per pose and grounded/airborne state. FootLock pins the base of grounded meshes. Physics remains on the parent character body. The procedural joint targets ease into one another rather than snapping their rotation values.

Select an actor's **Manual Pose** property in the Remote Inspector to stop its procedural bone animation and manipulate the bones directly. Facial bones drive matching shader parameters; mesh skinning drives the body. **Show Points** reveals the native joint locations and chains. Manual bone edits are a runtime inspection aid; save lasting changes in the tuning resource, calibration JSON or motion script.

Relevant implementation files: `scripts/character_rig.gd`, `scripts/character_motion_tuning.gd`, `scripts/character_portrait.gd`, `shaders/character_face.gdshader`, `scripts/player.gd` and `scripts/mega_main.gd`. `Art.character(id, false)` intentionally creates a plain sprite for the short pose-crossfade ghost.

## Recording

[Watch the 3.2 character and live-gameplay showcase](previews/in_motion_3_2.mp4). The first section uses the animation studio. The final section runs the real campaign player up three shelves using the same two-jump physics as normal play. The gameplay camera is zoomed for readability; no alternate jump trajectory is substituted.

To reproduce the raw capture with Godot's movie writer:

```sh
godot --path . --fixed-fps 60 --write-movie ../studio.avi res://scenes/animation_studio.tscn -- --showcase
godot --path . --fixed-fps 60 --write-movie ../gameplay.avi res://tests/animation_recording.tscn
```

The movie writer needs a graphical renderer; it does not record from the headless dummy renderer. The showcase exits automatically. Generated movies should stay outside the source folder, or inside ignored `test_output/`.

The delivered MP4 combines these native captures at 1280×720 and 60 fps. The studio section uses the bundled campus music quietly underneath; the gameplay section retains its captured game audio.

## Verification

Run `python3 tools/verify.py --godot /path/to/Godot` with Godot 4.4.1. The six isolated suites pass **629 checks**: 175 original chapter, 21 teamwork jump, 61 interface, 85 variety/recovery, 198 complete campaign and 89 animation checks.

The new checks cover every calibration profile, finite geometry, normalized skin weights, grounded feet, independent head/limb/face motion, blink closure, pause, reduced motion, reset behavior, moving Bark gait, world-anchored spring particles, actual contact-to-release choreography, animated dialogue portraits, F8 overlays, studio selection, slow motion and frame advance. Existing tests still physically traverse every main shelf and optional route, collect all 72 leaves, deliver the quest items and reach the ending.

Native rendering, fresh-package checks and recording results are documented in `release_3_2_verification.json`. This is an editable Godot source project. Physical mobile-device testing and standalone executable exports are not part of this release.
