# Definitive UI & Quality of Life review

Reviewed the playable title, shrinking introduction, tutorial, connected rooms, essential double-jump routes, inventory and hints, workshop assembly and retries, menus, ending, controls, local progress and graceful shutdown. Preserved the supplied characters, pivots, warm palette, fixed scenery, layered depth, original music and forgiving Leafy Lift routes.

| Finding | Change | Verification |
|---|---|---|
| Objective repeated completed parts of a task | Carried-plant and remaining-supply objectives, with matching supply icon | Both collection orders and plant return checked |
| Hints repeated already completed tasks | State-aware instructions identify only the remaining supply | Remaining pencil hint checked |
| Notebook status was a plain list | Current objective, clear Ready/To find checklist, direct Where next hint and N shortcut | Keyboard open, focus and Escape checked |
| Escape did not return through title/settings and pause/settings | Each submenu retains its own back action | Both menu stacks checked |
| Menus lacked a predictable first keyboard action | Start/Continue, Next/Finish, safe cancellation, Resume, notebook return and workshop actions receive focus | Title, dialogue, cancellation and selection focus checked |
| Preset selection depended on styling alone | Check marks and a written selected-angle/power summary | Both selected presets checked |
| Rebuilding workshop choices lost focus | Keep focus on the selected angle or power | Real button signal checked |
| Flight-hint button also changed presets without saying so | Relabelled Apply flight hint; feedback names the recommended combination | Workshop retry and reliable solution retained |
| High-route banter covered the jumping friends | Notices move below the friends when they occupy the upper screen | High-jump native fixture reviewed |
| Long toast text could exceed its card | Expanded card and reading duration for longer text | Long notice dimensions and duration checked |
| Notices competed with dialogue and continued expiring in menus | Hide notices and stop their timers until returning to play | Hide, time preservation and resume checked |
| Sound volume lacked a numeric value | Live percentage display; silent slider changes | Exact percentage checked |
| Hover/focus text relied on engine defaults | Explicit readable text colours across button states | Native screen review |
| A notebook modal could interrupt plane flight | Block it during flight and room transitions | Flight guard checked |
| Held input could continue after switching windows | Clear movement/touch state and pause free exploration on focus loss | Focus-loss event checked |
| Airborne pickup prompt implied immediate use | Prompt asks the player to land first | Required landing guard and full route retained |
| Ending could leave celebration active when dismissed with Escape | Shared exploration action clears effects and resumes play | Ending exploration retained |
| Save counters accepted duplicates and unknown IDs | Deduplicate against the six leaves/two notebook discoveries | Corrupt save fixture checked |
| Saved preference types could crash or change behaviour unexpectedly | Validate numeric/boolean types and finite numbers; clamp attempt count | Malformed preferences checked |

## Compatibility and scope

The application name, user save path and version-1 save format remain unchanged. Existing collected supplies stay collected; choose New adventure to replay the new required platforming routes. Menus, focus and quality-of-life changes are available in continued games. The chapter remains one tutorial and one connected campus with safe retries and optional secrets.

Keyboard and simulated native touch events are tested. Actual mobile hardware, child reading comfort, and child play duration still require real playtesting. This is a complete editable Godot project, played through the Godot editor; no standalone OS executable is bundled. Godot 4.4.1 is the tested runtime; the existing later-version loading fix is retained.

## Verification result

Godot 4.4.1: **175 passed, 0 failed** in headless and native OpenGL Compatibility full-path runs. Thirty native visual fixtures cover the title, ray, tutorial, campus, notebook, remaining-supply objective, pause/settings, high jumps, workshop, ending, touch HUD and film. Two additional rendered navigation checks confirm N opens the notebook and Escape exits the ending cleanly. Window-close audio shutdown passes. The final notice positioning was rechecked visually and with the full headless suite.
