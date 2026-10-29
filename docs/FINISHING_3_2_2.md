# Mark & Bark 3.2.2 — Finishing Pass

This release completes the first recommended milestone: reliable opening music, save recovery, consistent settings and checks of the exported game. The restored artwork, characters, story, routes, collisions and jump tuning are preserved.

## Opening music

The opening menu previously played the imported WAV once on a fresh launch. Visiting an adventure could mutate the cached resource into a loop, making the behaviour depend on navigation history. A common audio helper now duplicates the stream and sets a full-length loop for each player. The menu and both soundscapes use it.

Music and volume changes apply immediately on the opening menu. Master mute pauses the stream; returning from either adventure respects the latest preference. Tests seek near the real end, allow the audio mixer to advance, and check that playback wraps without a finished signal or a mutated imported resource.

## Saving and recovery

Both adventures now share the same file-writing implementation while keeping their existing filenames, application name and JSON versions:

| File | Contents | Readable versions |
|---|---|---|
| `big_idea_save.json` | Original story, tutorial and shared settings | 1 |
| `mark_bark_mega.json` | Climbing progress, best scores and calm mode | 1 and 2 |

A save is written to a temporary file, flushed and read back before publication. Before replacing a valid primary, its previous contents are copied to a temporary backup, validated and promoted to `.bak`. Write, copy and rename failures leave the committed primary intact. An unreadable primary never replaces a good backup. A missing or corrupt primary loads its valid backup; pending `.tmp` files do not become committed progress.

Save failures remain visible in settings and the adventure interface. A failed native close keeps the current game open and offers **Try again**, **Keep playing** and **Quit anyway**. Both adventures attempt to save; the close handler does not quit silently after an error. Keeping the game open preserves the current session, and a successful retry uses the normal close and audio-drain path.

This retains one previous valid save; it is not a multi-version history or cloud backup. Filesystem flush and atomic rename protect the tested interruption paths, without promising recovery from every power, device or filesystem failure.

## One settings component

The opening menu and both adventures now display the same panel, with an exact volume percentage and explicit On/Off states:

- Background music and sound volume.
- Reduced motion.
- Always show touch controls.
- Original painted characters.
- Calm climb, labelled as a climbing-adventure preference.

A common setter validates shared settings and announces changes. Each panel synchronizes without emitting another change or writing in a feedback loop. Preferences apply to the active scene, survive cold reloads and preserve the progress of both adventures. Back/Escape returns to the appropriate menu or gameplay; the opening menu restores focus to Settings. If saving failed, Back retries both save files.

## Source and production verification

Run the complete source suite with Python 3 and Godot 4.4.1:

```sh
python3 tools/verify.py --godot /path/to/Godot
```

The runner imports a fresh project copy with a unique application name, asks the engine to verify the resulting test-save location, and refuses to test against a different folder. It runs all eight suites and records logs and `qa_summary.json` in ignored `test_output/`.

The 777 source checks include 77 finishing checks. They cover short and partial writes, copy failures, corrupt backups, failed renames, a real blocked temporary path, corrupt/missing/unsupported saves, malformed preference types, observable failures, successful retries, actual audio wrapping, shared UI, live settings and failed-close recovery. The earlier gameplay and artwork checks remain active.

For production exports:

```sh
python3 tools/fetch_export_templates.py --destination /path/to/templates
python3 tools/verify_exports.py --godot /path/to/Godot --templates /path/to/templates
```

The installer verifies the official Godot 4.4.1 archive against its published SHA-512 checksum. The single-threaded Web preset uses **web_nothreads_release.zip**; the Windows preset uses the x86_64 release template. Templates and verification scripts are developer dependencies, not downloads required by players.

The export runner builds a production resource pack and launches a release runtime in three fresh processes: save, resume, and recovery after deliberately damaging both primaries. Its 66 checks exercise the real opening menu, original story, all three climbs, painted platforms, character studio, settings and failed-save close/retry. It checks saved JSON after the game actually exits, and confirms that artwork data and font licensing are included while tests, tooling and review documents are excluded. The test controller stays outside the distributed game.

It then creates `Mark-and-Bark-3.2.2-web.zip` and `Mark-and-Bark-3.2.2-windows.zip`. The Windows build includes its executable and adjacent `.pck`; the Web build includes the complete HTML/JavaScript/WASM/resource set.

The workflow also runs a browser playthrough of the **unmodified Web release**. It uses real mouse and keyboard input, checks rendered text with OCR, saves preferences, reloads the page and checks the settings in all three entry points. Missing files, HTTP failures and script errors fail the check. To reproduce it on Linux with Node, Tesseract, Python Pillow and Playwright 1.62.1 installed:

```sh
python3 tools/fetch_test_browser.py --destination /path/to/chrome
node tools/verify_web.cjs --browser /path/to/chrome/chrome-headless-shell-linux64/chrome-headless-shell --modules /path/to/node_modules
```

A separate Windows workflow job downloads the same exported Windows build and runs its release executable through the three save/resume/recovery processes. The workflow publishes editable source, Web and Windows builds, verification logs and screenshots as downloadable artifacts.

The JSON [verification record](release_3_2_2_verification.json) records observed local results. GitHub Actions supplies the independent Windows runtime result for each commit. Native screenshots and browser rendering were reviewed at 1280 × 720 using software graphics. Audio lifecycle tests use a dummy output device; they verify playback state, not speaker sound quality. This pass does not claim hardware performance measurements, a physical mobile-device matrix, macOS exports or a public Web deployment.
