# 3.6.0 — Whimsy HUD

The gameplay HUD now leaves the scenery open. The normal view contains a small botanical leaf-score capsule, two spring leaves and a round pause control. The former full-width quest header, progress ribbon, shelf/height panel, jump sentences and notebook/hint/checkpoint shortcut rows are retired from the always-on view.

![Before and after the HUD redesign](previews/whimsy_hud_3_6.jpg)

## The essentials

- The leaf capsule shows real discoveries (`0 / 24` in a climb; `0 / 6` in the original adventure). Selecting it opens the notebook. Collecting a leaf briefly animates a small `+N` chip and sparkle inside the score area instead of producing a long banner.
- Two little leaves on a stem show the actual two-jump spring energy. Each jump consumes a displayed charge; landing restores both. The existing game has forgiving retries rather than a hit-point system, so the meter represents real spring energy rather than invented health.
- A small pause button opens the familiar pause menu. Objectives, discovery totals, Notebook, Bark's hint, checkpoint/restart, Settings and title-screen actions remain available there. Keyboard shortcuts remain available during play.

Touch mode adds two movement arrows and a larger Jump button near the edges. Use appears only when a nearby interaction is relevant. The controls retain substantial hit targets and support simultaneous movement/jumping. Layout responds to viewport size and display-safe insets.

## Help that appears when needed

The current tutorial task appears as a brief paper cue when it changes. The full task is always available in Pause and the Notebook. An idle learner can still request Bark's help; tutorial skipping is available in Pause. Nearby interactions produce a short cue. Story message cards try positions clear of both characters, the small HUD and touch controls, and only one card appears at a time.

The climbing introduction's jump cue expires after six seconds. Routine leaf collection and repeated airborne jokes no longer generate long text banners. Bark's jokes remain in the Notebook. Important discoveries, quest dialogue, recovery and failed-save notices remain readable.

All UI score animation stops while paused and immediately honors Reduced motion. Notice reading timers pause with menus. Decorative drawings use native Godot canvas shapes and existing painted leaf artwork; no external font, asset or service is required.

## Measured change and validation

At 1280 × 720, the three resting HUD elements occupy **13,100 logical square pixels**, about **1.4%** of the canvas. Compared with the former Library keyboard panels (159,200 pixels), that is a **91.8% reduction**. Idle touch mode occupies 31,212 pixels versus the prior 209,000-pixel reference, an **85.1% reduction**. Temporary messages, nearby Use and opened menus are additional, contextual UI rather than part of the idle measurement.

The dedicated HUD suite checks score collection, both real jumps, landing recharge, keyboard and multitouch input, focus safety, touch hit regions, pause tools, transient help, reduced motion, responsive layout and asymmetric safe insets. Native fixtures cover all three climbs and all three original rooms in keyboard/touch modes, spring states and pause menus. Existing quest, shadow, scenery, save and complete-playthrough suites continue to run.

Gameplay physics, collectible requirements, quest order, painted characters, scenery and save formats remain intact. Validation uses Godot 4.4.1, native software rendering, a production Web build in Chrome and the exported Windows executable; physical-device testing is separate.
