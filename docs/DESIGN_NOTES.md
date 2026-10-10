# Introductory slice

## Coordinates and play spaces

Logical viewport: 1280×720; ground top: y=610; campus width: 5600 pixels. Hallway: x=0–1700; garden: x=1700–3700; workshop: x=3700–5600. Each room has its own horizontal camera bounds. At the signed screen edges, a short transition moves both companions into the adjacent room; no adjacent background is shown during normal exploration. Reduced motion removes smoothing, parallax, character lean/breathing and ambient motion, and shortens transitions.

Main locations: invitation x=810; notebook x=1910; plant display x=2320; wandering plant x=2840; books x=3290 at platform y=490; pencil x=3500; shortcut x=3630; desk x=4430; target x=5050. Optional one-way branch platforms form an elevated garden route. The underlying floor is continuous and forgiving, but room travel explicitly interrupts movement with a named transition. Normal boundaries are x=1688/1712 and x=3688/3712, with safe arrival points 1745/1655 and 3745/3655. The shortcut arrives at x=4240.

Platform artwork and physics are independent. Painted backdrop objects are scenery. Golden-edged logs identify the actual usable platforms. Jump height is approximately 130 pixels, allowing the required books to be reached directly from below as well as through the branch route.

## Quest state

Stages: 0 invitation; 1 notebook; 2 plant restoration; 3 books/pencil; 4 reach workshop; 5 assemble; 6 launch; 7 complete. Early interactions explain the current prerequisite without consuming or moving the required object. Pickups vanish only after their persisted flag is set. Optional collectibles never gate stages.

## Launcher

Trajectory origin (4430,425); angle presets 25°,40°,55°; speed presets 350,470,600; downward acceleration 250 pixels/s². Swept crossing at target x=5050 interpolates the y coordinate, with a generous ±90-pixel tolerance around y=290. Middle angle with medium power is reliable. There is no required timing input. A failed shot retains assembly and returns to the workshop interaction.

## Scope and extension

The first chapter uses Young Mark and Bark. The other age groups remain available in the owner's full art pack but are deliberately omitted from this playable download to keep it compact. Changing goals, dialogue, object positions and optional notebook text is straightforward in the scripts. Future chapters can keep the movement and state systems and provide separate level data.

The level contains detailed painted background art with slow parallax, warm native 2D lights, contact shadows and layered foliage, original tonal sound effects, a complete small quest and an ending. It does not simulate an entire school population or a large open world. Play duration should be tuned through observation with the intended audience rather than inferred from an automated test.
