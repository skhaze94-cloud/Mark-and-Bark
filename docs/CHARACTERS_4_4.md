# 4.4 — Seamless Motion

Round overlapping wood volumes bridge Bark's shoulder, elbow, wrist, knee and
ankle ends, replacing exposed flat segment joins during rotation. Mark's sleeve
and knee overlaps are fuller; the notebook sits farther forward of the hand.
Elbow flexion and shoulder yaw are limited to the modeled overlap range and
transitions are softened. The 4.3 silhouettes and original art remain.

Portrait/studio textures increase from 384x480 to 512x640 and gameplay textures
from 256x320 to 320x400, with 4x MSAA. Curved organic primitives have more surface
segments. This increases rendering cost; physical Android performance is untested.

These remain articulated segmented models, not continuously skinned production
meshes. The update addresses exposed joins and tested pose intersections, but
cannot guarantee freedom from every intersection in arbitrary poses. Existing
facial expressions, discovery performances, pause and reduced motion remain.
