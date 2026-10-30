# 3.7.0 — Character 2.0

Mark and Bark now have real 3D bodies and performances within the painted adventures. Mark keeps his chestnut hair, navy hoodie, golden shirt, denim and sneakers. Bark keeps his friendly living-tree identity, with a broader trunk, carved grain, an uneven crown, branch hands, root feet and folded leaves. Their silhouettes have more substance without changing the platforms or the collision bodies that determine play.

![Native Godot capture of the 3D celebration pose](previews/character_2_0_3_7.jpg)

## Shape, lighting and expression

The models are built from native Godot meshes and articulated `Node3D` pivots. Mark has 27 named joints; Bark has 28. Layered clothing, shaped hands and shoes, bark grooves and leaves give the lighting actual surfaces to reveal. Warm key light casts self-shadows; fill and rim light keep the shaded sides readable.

Eyes, lids, pupils, eyebrows and mouths are separate modeled parts. Both characters blink, look around and change their expressions during conversation and celebration. Mark's notebook is a modeled prop attached to his hand during the notebook pose.

Each actor renders in its own transparent `SubViewport` and places that image at the existing 2D foot position. Facing changes rotate the model through a real angle. The established world shadows continue to ground the friends on platforms; the model lighting adds depth within each character. Dialogue portraits center on the projected face joints.

The characters are 3D inside a painted 2D world. This update does not convert the levels, camera, physics or movement into a free-roaming 3D game.

## Performance

`character_performance_3d.gd` drives the named pivots from the existing actor states:

| State | Character performance |
|---|---|
| Idle | Planted feet, breathing, small head and hand movement |
| Walk and run | Two-bone leg solving, alternating stance and swing, arm movement |
| Jump | Reach, tuck and airborne balance |
| Bark spring | Brace, contact, release and recovery |
| Landing | Brief compression and settling |
| Talk and hint | Face expression, gaze and small gestures |
| Notebook | Mark holds a modeled notebook |
| Cheer | Raised arms, smiles and canopy movement |

Clothing and leaves follow the main movement. Sole placement is solved relative to each model's floor; it is not a world-space foot-locking system. Jump impulses and collision response still come from the established 2D controllers, so animation does not delay input.

Pause freezes the performance. Reduced motion removes idle and secondary flourishes while retaining readable movement poses. Invisible/off-screen character viewports stop rendering; frozen performances request a frame when their visible state changes. Models build once and reuse their geometry, with static pieces batched by joint and material.

The presenter uses a 256 × 320 render texture for small gameplay actors and 384 × 480 for larger actors and portraits. Both resolutions project onto the same logical canvas and floor anchor. This reduces rendering work for distant characters without changing their world size.

## Choosing a style

The shared Settings panel offers one **Character style** selector:

| Style | Presentation |
|---|---|
| **3D storybook** | New default: lit models, articulated 3D motion and expressions |
| **Original painting** | Supplied painted character artwork |
| **Articulated painting** | Earlier 2D skeleton and face presentation |

The opening menu also has a quick Character 2.0 / 3D switch. The original PNGs, pose profiles and earlier renderer remain bundled. Unknown character profiles retain their original-source fallback.

The boolean `characters_3d` setting defaults to `true`, persists with the shared preferences and is sanitized with the existing settings loader. Existing saves without that field gain the new default. The `painted_characters` preference is retained for the two painting styles. The application name and save locations remain unchanged.

## Character studio

Open **Character studio** from All adventures, or run `scenes/animation_studio.tscn` in Godot. The studio uses the selected character style.

| Control | Action |
|---|---|
| **1–7** or pose buttons | Idle, Walk, Run, Jump, Bark spring, Talk, Cheer |
| **Space** | Pause or resume |
| **Speed** | Full or half speed |
| **P** | Show projected joint points |
| **Next frame** | Pause and advance one animation frame |
| **O** | Turntable for the 3D models |
| **Esc** | Return to All adventures |

The turntable pauses with the studio and honors Reduced motion. Turning it off restores the normal facing angle. The studio is a performance inspection room; its jump demonstration does not replace a live physics test.

## Editing

- `scripts/characters/mark_model_3d.gd` defines Mark's geometry, joint pivots, face parts and notebook.
- `scripts/characters/bark_model_3d.gd` defines Bark's geometry, branch joints, root feet and canopy.
- `scripts/characters/character_performance_3d.gd` binds the joint dictionaries and drives poses and expressions.
- `scripts/characters/character_presenter_3d.gd` owns the transparent viewport, camera, lighting, model rotation and projected joints.
- `scripts/character_rig.gd` selects the 3D or legacy presentation while retaining source textures and existing gameplay state.

Model coordinates use +Y up and +Z forward, with the floor at Y=0. Preserve the named joints and expression methods when editing a model. The presenter cancels the old flat-image mirror, lean and squash while retaining the actor's world position and uniform scale.

The release uses Godot 4.4.1's Compatibility renderer and repository-native geometry. The new character models do not require an external model download, paid plugin or generation service at runtime.

## Verification scope

`tools/verify.py` imports a fresh project with isolated saves and runs thirteen source suites. `tests/character_3d_review.tscn` adds dedicated checks for model volume, joints, animation, real facing changes, projected floor alignment, pause, Reduced motion, source textures, style switching, persisted preferences and both adventures. With `-- --screenshots`, it also captures native scene and transparent-model images and verifies framing.

The GitHub workflow runs the source suites, native visual checks, production Web and Windows exports, packed save/resume/recovery checks, Chrome gameplay and the exported Windows executable. The native character step requires its final `CHARACTER 3D RESULT:` marker as well as an error-free log. Screenshots and logs are retained as workflow artifacts.

The complete original story, three climbs, 3.6 minimal HUD, painted scenery, quests, controls, jump physics and save formats are retained. Hardware performance measurements, physical mobile-device testing and macOS exports remain separate work. Software-rendered browser and native fixtures establish behavior and appearance in those test environments, rather than a frame-rate guarantee for every device.
