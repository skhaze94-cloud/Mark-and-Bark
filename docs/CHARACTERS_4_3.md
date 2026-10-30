# 4.3 — Original Shapes

The original bark_front/right and young_front/right paintings are the reference.
The correction addresses the actual proportions rather than adding accessories.
Bark's previous straight upper/lower trunk, small palms, long arms and narrow feet
read as a humanoid block. Mark's broad head, level shoulders and straight clothing
contours obscured the softer child silhouette.

Bark's lower trunk radius is reduced from 0.21 to 0.13, and upper body radius from
0.36 to 0.29. The narrow irregular hem follows that taper. The head is slightly
narrower, with smaller eye surrounds and a less prominent facial panel. Shorter
curved branch arms hold large five-ray hands in an inviting rest pose. Each ray
has several curved segments, taper and rounded twig tips. Wider roots have thick
arches and knotted upper stems; they spread from the body rather than resembling
small shoes. Short layered bark chips replace long plank-like raised pieces.
Leaves sit around the broken crown's edges, leaving woody shoots visible.

Mark's head changes from a uniform 1.16 scale to (0.99, 1.12, 1.04): a narrower
outline with retained facial height and depth. The coat slopes at the shoulders
and widens gently at the hem. Smooth radius transitions round garment contours.
Hands are slightly fuller, elbows relax forward, and feet turn outward gently.
The skin keeps its painted blush while separate raised cheek patches are removed.

The established expression and shared-discovery systems remain. Bark's animation
targets compensate for his new bent branch-arm rest angles, so greetings, springs,
pointing and celebrations keep their intended poses. Changes are visual only.
Movement collisions, world size, scoring, jump behavior and save schemas do not
change. All original artwork and selectable painting styles remain intact.

The comparison uses original front paintings and native 4.2/4.3 rest renders,
fitted to equal displayed heights per character. Studies compare rest/delight in
front and three-quarter views with silhouettes. A short native movie demonstrates
expression transitions and branch/hand poses. It is an offline render and does
not measure physical Android performance.

Verification: tools/verify.py covers gameplay, save, presentation and accessibility
regressions. Native character_3d_review --screenshots checks framing, transparency,
complete silhouettes, floor anchors, portraits and integration in existing scenes.
tools/verify_android.py checks signing, 16 KiB alignment, ARM64, landscape and exact
packed resource tests. Physical Android device/emulator testing remains separate.
