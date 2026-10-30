# 4.1 — A Painting Come to Life

## Reference findings

The original young_front, young_right and young_actions_jump paintings establish
Mark's warm rounded cheeks, swept brown fringe, navy jacket/gold shirt and open,
curious expressions. Bark's front, right and cheer paintings establish a tall,
irregular trunk, loose branch hands, root feet, expressive brows and a large
friendly grin with an ivory upper tooth band. These files are kept unchanged.

## Implementation

Shallow, smooth almond geometry replaces the circular eye surrounds. Warm iris
rings, smaller pupils, restrained highlights, happy eyelid compression and
asymmetrical brows retain the illustration's readability. Mark has a mischievous
closed smile, a talking mouth and a broad delighted smile with an ivory tooth
shape. Goggles move from his forehead to his satchel, clearing the swept fringe.
Bark has a generous warm mouth, a simple upper tooth band and tongue, with a
quieter leaf crown and a gentle bias in his eyebrows. Facial geometry remains
attached to real head pivots; clothes, wood, hands and accessories retain depth.

A small spatial pigment shader adds restrained, stationary color variation to
opaque body surfaces. It keeps specular highlights disabled. Shallow face ink is
unshaded for clarity; double-sided leaves/scarf keep their established materials.
Materials are cached once per actor during construction, not recreated per frame.

Existing stride, jump anticipation, landing and spring poses remain. Curiosity
adds a held head tilt; waves use an articulated raised arm and wrist; Bark's trunk
stretches gently on spring and celebration poses. Optional library discoveries
trigger greetings and mutual head/eye glances. Their timers freeze during pause.
Reduced motion holds gestures, settles foliage, and suppresses celebration flecks,
including when the setting changes while paused. Petals/paper flecks are reused.

## Comparison and review

The delivered comparison uses original front paintings and actual 4.0/4.1 native
idle renders. Each character is fitted to the same displayed height across its
row so the comparison focuses on design. It does not imply changed world scale.
The pose sheet uses native 4.1 idle, walk, jump, talk and celebration renders with
small readability samples. Gameplay views are also checked in the library and
other existing scenes by character_3d_review.

The world remains a painted 2D game with genuine articulated 3D characters. No
stage, physics, save schema or new progression requirement is introduced.

## Validation

Use tools/verify.py for source tests and tools/verify_android.py for the signed
APK and packed resources. Native character_3d_review --screenshots checks framing,
transparency, floor anchors, style switching and scene integration. The expanded
painted_review checks flourish lifetime, pause/reduced motion, wave, expressive
state, friend gaze and return to idle. Physical Android testing is not performed
by these desktop checks.
