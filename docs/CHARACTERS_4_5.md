# 4.5 — Soft & Springy

The sleeves and trouser legs on Mark, and the branches and leg roots on Bark,
now use continuous indexed surfaces with graded bone weights across elbows and
knees. Bark also has one trunk surface from the lower bark hem to the uneven
crown, weighted through hips, spine, neck and head. Grain and contour geometry
follow the same trunk deformation, while the illustrated face stays on the head.

`soft_skin_3d.gd` builds a real Skeleton3D and Skin with inverse rest binds.
Its hierarchy mirrors the established visual pivots, preserving Bark's
nonuniform squash and stretch during rotation. Existing performances and solved
foot contacts feed the skeleton after each pose. No geometry is rebuilt during
animation, and movement/collision remain owned by the original 2D controllers.

Mark's scarf tails are weighted ribbons with damped follow-through. They bend
on acceleration and settle after landing. Pause freezes both the ribbon bones
and the spring state; reduced motion clears overshoot and holds the tails.
The existing leaf settling and limited celebration petals remain event driven.

The original artwork, 4.3 proportions, expressive hands, root fans, painted
faces, adventures, save format, minimal HUD and three painting styles remain.
The 4.4 render sizes and 4x MSAA remain: 512x640 for inspection and 320x400 in
gameplay. Android is version 4.5.0, code 450, with the established package/key.

## Validation and boundaries

Release checks passed: 1,440 source assertions on Godot 4.4.1, 140 native
character checks plus 75 native skin checks on Godot 4.5.1, and 90 exact packed
APK checks across seed, resume and damaged-save recovery. The 16-second preview
is rendered by Godot. Original / 4.4 / 4.5 comparison and pose/view sheets use
native screenshots at equal displayed height. Physical-device and emulator
testing were not performed.

- Source suite includes `soft_skin_review`: normalized weights, continuous limb
  rings, finite deformations across seven performances, alignment with the solved
  pivots, pause, reduced motion and fixed surface counts.
- Native skin tests additionally bake posed vertices from the renderer and
  compare them with independent CPU evaluation of the weights.
- Native character review exercises game scenes, portraits, framing, movement,
  studio controls, painting styles and accessibility.
- Android verification checks signing identity, ARM64, API 35, 16 KiB alignment,
  offline permissions and the exact packed game resources.

This is a focused weighted-surface upgrade, not a replacement of every rigid
piece. Faces, hands, shoes, crown twigs and small accessories retain their
existing articulated construction. Separate shoulder/body, hand/cuff and
root/foot attachments still overlap. Skinning reduces exposed elbow/knee seams;
it does not provide general self-collision or guarantee every arbitrary pose is
intersection free. Physical Android device performance has not been tested.
