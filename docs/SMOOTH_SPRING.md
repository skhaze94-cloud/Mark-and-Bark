# Spring Polish 2.0.2

This focused update further improves Mark and Bark's teamwork jump in the three-level campaign.

Bark anticipates the first jump and moves toward Mark's feet. The second jump no longer teleports him. His movement updates after Mark's physics movement, with a small velocity lead to keep contact aligned. Contact eases into a braced squash, followed by release, stretch and a soft return to his companion position. Recovery begins at the actual contact position instead of snapping to a separate animation anchor. Facing stays consistent during release; Mark's contact and early release remain opaque to avoid duplicate silhouettes.

The jump impulses, gravity, air control, collision shape, coyote time, input buffer and two-jump limit remain unchanged. There is no animation delay before launch. Keyboard and touch use the same jump request. Checkpoints reset the sequence; pause freezes it. Reduced motion omits the additional squash and lean.

## Final polish

A landing cancels the airborne choreography even beneath a low ceiling. Mark's standing pose returns immediately. Checkpoint resets clear contact poses, opacity, lean and squash. Bark rests within the same shelf when Mark stands near its edge. The launch uses the current direction, and Bark's release drift remembers the launch direction while Mark remains free to steer.

## Verification

- `tests/jump_review.tscn`: 21 focused checks for anticipation in both directions, no launch teleport, immediate impulse, continuous motion/scale, pause/resume, reduced motion, rapid taps, direction changes, low ceilings, shelf edges and checkpoint interruption. Also run with the native compatibility renderer and inspected contact/release screenshots.
- `tests/mega_playthrough.tscn`: 93 checks including physically climbing every required shelf in all three levels, optional routes, quest deliveries, keyboard, multi-touch and save/reload.
- `tests/polish_review.tscn`: 60 interface and interaction checks.
- `tests/playthrough.tscn`: 175 original-chapter regression checks.

Run a test with Godot 4.4.1, for example:

```sh
godot --headless --path . --fixed-fps 60 res://tests/jump_review.tscn
```

Import `project.godot` and press F5 to play. Existing saves are compatible.
