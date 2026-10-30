# 4.2 — Full of Character

## Honest benchmark

The original young_front/right/jump and bark_front/right/cheer paintings are the
visual authority, preserved byte-for-byte. The 4.1 renders retained large circular
resting eyes, short rounded hair clumps, small rigid fingers and a mouth that
remained open on Bark. Those choices weakened the quiet warmth of the paintings.
The revision concentrates on shapes and coordinated poses rather than accessories.

## Character treatment

Mark: fourteen longer, swept locks and a loose forelock replace thirty small
clumps. Smoother lock geometry and fine following contours describe the same
flow. The chin tapers into broad cheeks. Soft separate fingers allow index-led
pointing, a relaxed palm, a spread wave and a notebook hold. A closed friendly
smile, tilted mischievous grin, curved delighted mouth and brief round surprise
are prebuilt, with eyelids, independent brows and cheek lift moving together.

Bark: curved mouth and bowed tooth band raise the grin's corners. The grin relaxes
at rest, narrows in thought, opens for laughter and switches to a brief round
surprise. Raised grain stays behind the smooth facial region. Roots spread wider;
resting arms invite approach and the trunk has a slight lean. Branch hands,
shoots, bark edges and the existing keepsakes preserve his living-tree identity.
Leaves lift for curiosity and settle after laughter or a landing.

Both characters retain warm matte pigment, shallow facial ink, real articulated
3D depth, supporting-surface anchors and their original 2D painting options.
There are no physics, save-schema, scoring or HUD changes.

## Performance

Curiosity, uncertainty, concentration, delight, surprise, wave, presentation and
laughter have distinct coordinated face/body states. Surprise transitions once
to curiosity after 0.65 seconds. Idle remains calm. Existing strides, airborne
tucks, anticipation, spring and landing recovery remain display-only.

At an existing optional library discovery, Mark notices and points while Bark
thinks and leans in; they exchange a look, then Mark presents and Bark delights.
The 3.2-second sequence is optional and never locks movement. It is visible while
resting and does not override an airborne action. Pause freezes all sequence
clocks; reduced motion uses a single held presentation/delight pose. Existing
flecks are reused and suppressed by reduced motion. The studio exposes an
expression selector and a shared-discovery preview.

## Visual review and reproduction

The comparison uses original front art and actual 4.1/4.2 front renders at equal
displayed heights per character. This does not imply changed game scale. The
study sheet shows front/three-quarter rest and delight with black silhouettes.
The pose sheet shows curiosity, uncertainty, surprise, delight and presentation,
including small readability samples. Normal native scene checks also cover
walk, jump, talk, celebration, gameplay and dialogue portraits.

Run tools/character_showcase.gd in a native Godot window. Pass -- --baseline on
the 4.1 source for baseline captures; the 4.2 source captures into
res://test_output/character_showcase. Run tools/character_review_board.gd after
both captures to assemble sheets. For the short native animation use:

    godot --fixed-fps 24 --write-movie preview.avi --script res://tools/character_showcase.gd -- --movie

This offline render demonstrates animation timing, not real-device performance.
Original source PNGs and all adventures remain in the source package.

## Verification

Run tools/verify.py for source gameplay and regression suites;
character_3d_review --screenshots for native framing, transparency, floor anchors,
style switching and world integration; painted_review for expression/gesture
lifetime, shared sequence ordering, pause, reduced motion and calm recovery.
Run tools/verify_android.py on the signed APK for signature, alignment and packed
resources. Physical Android device/emulator testing is separate and outstanding.
