# Cinematic edition

This graphical update keeps the existing tutorial, quest, three connected rooms, collision coordinates, launcher solution, discoveries and save format compatible. It uses detailed dimensional 2D art and code-driven planes, not new 3D meshes or skeletal rigs.

The painted architecture, rear furniture, interactive props, characters, near foliage and UI occupy distinct render planes. Rear furniture shifts by 10–18% of camera movement; near canopy framing moves oppositely by 24–26%. Only decorative sprites move; interaction targets and collisions remain fixed. High canopies frame the room edges without obscuring the central action. Rear lockers, bookshelves, a reading bench and a mounted invention blackboard add depth and local cast shadows.

Five campus light shafts use softly graded transparency and slow deterministic dust. Existing warm light pools remain. A lightweight five-sample Compatibility shader adds a restrained highlight halo, warm colour balance and soft edge falloff to the world only. No depth blur is applied to characters or interface text. Mark has a 160 ms foot-anchored landing settle and a 320 ms dust puff. Neither changes input buffering, coyote time or collisions.

The campus film has four seven-second shots: the quiet garden, Big Ideas Day hallway, invention workshop and friendship/title moment. Letterboxing, gentle dissolves, camera drift and zoom, expressive supplied poses and a cosmetic plane flight create a 28-second in-engine opening. Keyboard and touch skip controls remain available. The title can replay the film independently. A first adventure goes from film to tutorial. Film props are temporary and never mutate quest data. Reduced motion fixes the camera and plane, removes parallax, dust and landing deformation.

## Art provenance

Built-in image generation created three transparent cutouts using `assets/workshop_hub_v2.png` as a style reference. The PNGs are copied intact, with native sizes and bottom pivots recorded in `assets/index.json`. Full prompts are in `cinematic_generation_prompts.json`.

- `assets/invention_board_v3.png`: bevelled oak frame and chalk invention doodles.
- `assets/reading_nook_v3.png`: cabinet, navy bench, books, globe, lamp and trailing plants.
- `assets/canopy_v3.png`: warm oak/ivy canopy with transparent leaf gaps.

## Verification

Run `godot --headless --fixed-fps 60 --path . res://tests/playthrough.tscn` for complete quest and cinematic regression checks. With a graphical display, run `godot --path . res://tests/visual_review.tscn` for twelve title, room, transition, controls and film screenshots. Tests preserve existing player saves. Results are recorded in `cinematic_verification.json`. Physical phones, audio speakers and child play duration have not been measured.
