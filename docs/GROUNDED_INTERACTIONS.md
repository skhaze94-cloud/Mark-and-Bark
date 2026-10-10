# Grounded interactions update

Built on GitHub main f74e9405ac7b6833f0455e8a19288b06e38295d6. The latest release's Godot draw-method loading fix is retained. New runtime checks use Godot 4.4.1 Compatibility. No quest, save schema or launcher solution is changed.

## Room anchoring

Removed camera offsets from decorative furniture, canopies, flattened room paintings and distant painted garden accents. Pickups retain their world positions instead of vertical bobbing. Only tiny foot-pivot foliage sway, lighting/dust, character animation and deliberate cinematic camera moves remain animated. Layer order, painted perspective, lighting and contact shadows provide depth without props drifting against walls.

## One live board

`assets/workshop_hub_v4.png` is a non-destructive edit of the workshop painting: the large rear chalkboard and its frame were replaced with a quiet sunlit plaster recess. Other architecture, small blueprint posters, cabinetry and floor were retained. Built-in image generation created the edit; its exact prompt is recorded below.

Removed the separate decorative board. `scripts/invention_board.gd` mounts one oak-framed live board. Its textured slate, component icons/checkmarks, angle/power text, chalk arc and delivered invitation state update from the actual assembly/launch state. The ring at world (5050,290) replaces the old fair noticeboard sprite and preserves the existing generous target and launcher trajectory. The school entrance invitation noticeboard is still a separate necessary story object.

## Interaction and shadows

Stable corner brackets and a bulb identify the closest usable object while the contextual HUD gives its name. A restrained world-space ring responds to an interaction; reduced motion omits that expanding effect. Focus clears during dialogue/flight.

Props and Bark use soft layered contact shadows, separate from sprite transforms and aligned to a fixed support point. Hidden/collected items hide their shadows; removed props clean up their shadows. Mark's shadow projects onto the nearest eligible platform or floor beneath him, softly fades with height, and follows the same light direction. Board and rear furniture have subdued wall shadows. Gameplay collisions remain separate from visual shadows.

## Verification

`tests/playthrough.tscn` covers the complete tutorial, skip/replay, quest, inventory, workshop retries, ending, room travel, keyboard/touch controls and saves. Added regression checks exercise camera-independent anchors, backdrop alignment, one board/unchanged target, assembly and launch updates, supporting surfaces and contextual notebook selection. `tests/visual_review.tscn` captures thirteen title, room, workshop, live board, touch and cinematic views. Both preserve existing player save data. See `grounded_verification.json` for final results. Physical phones and Godot 4.7.2 were not re-tested in this update; the prior compatibility fix is retained.

## Background edit prompt

Use case: precise-object-edit. Edit target: attached Mark & Bark classroom workshop background. Remove ONLY the large rectangular green chalkboard on the upper-right rear wall (the one with the big lightbulb and paper plane), INCLUDING its outer wooden frame. Replace that entire rectangle with a beautiful quiet cream plaster wall recess with subtle warm sunlight and soft ambient shading. This empty wall recess will receive ONE separately rendered dynamic game board. Keep the existing plants around it, bottom bench, shelves, papers, all cabinets, windows, floor, roof beams, bunting, small two blueprint posters on the central column and lighting unchanged. Do not add another chalkboard, whiteboard, painting, poster, furniture, writing or UI into the cleared wall recess. Preserve the detailed warm painterly storybook art, perspective, layout, image size and continuous lower floor. No characters. Absolutely no duplicated board baked into the edited backdrop.
