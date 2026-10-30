# Mark & Bark 3.8 — Android edition

The Android edition contains the complete original adventure, three giant
climbs, genuine 3D Mark and Bark, the character studio and all three Library
Ladder little-wonder encounters. It is a signed, offline ARM64 APK, with Android
7.0 (API 24) minimum and Android 15 (API 35) target. It requests no Android
permissions. Landscape orientation and the authored 16:9 composition are kept;
wider phones and taller tablets retain the complete game view with letterboxing.

## Phone controls

Hold an arrow and tap Jump with another finger. Tap Jump again to spring off
Bark. Use appears only beside something interactive. The leaf counter opens the
Notebook; the top-right button opens Pause. Android Back closes Settings,
returns from the studio, or opens/closes the gameplay pause screen. Returning
from the system background leaves active gameplay paused and releases held
movement. Backgrounding also saves both adventures using their existing atomic
stores.

## Runtime and signing

Android alone uses **Godot 4.5.1 stable** with official matching templates.
Its ARM64 ELF LOAD segments are aligned to 16,384 bytes. The older 4.4.1 Android
template uses 4,096-byte segments; it is deliberately not used for this APK.
The APK is also ZIP-aligned for 16 KiB pages and signed with APK v2/v3 using a
dedicated Mark & Bark release key. Desktop/Web releases remain on Godot 4.4.1.

The application ID is `com.samkhaze.markandbark`, version name `3.8.0`, code
`380`. Retain the private signing backup separately from the source tree. Future
updates must use this same key/application ID and increase the version code.
No signing credentials are committed or included in the APK or editable source.

## Rebuild

Install Godot 4.5.1, its matching official Android templates, OpenJDK 17, and the
Android SDK platform-tools and build-tools 35.0.0. Verify the engine/archive
checksums against that release's official `SHA512-SUMS.txt`. Supply the key
password through `MARK_BARK_KEY_PASSWORD` in the environment. Then run:

```sh
python3 tools/build_android.py \
  --godot /path/to/Godot-4.5.1 \
  --template /path/to/4.5.1.stable/android_release.apk \
  --sdk /path/to/android-sdk \
  --java /path/to/jdk-17 \
  --keystore /private/path/mark-and-bark-release.keystore \
  --key-alias markandbark \
  --output /path/to/Mark-and-Bark-3.8.0-Android.apk
```

Keep `android_debug.apk` alongside the release template. The script imports a
clean temporary copy, uses isolated editor settings, builds a release APK, then
aligns and signs it. It does not modify the working project's credentials.
The Android preset can also be used through the Godot editor after configuring
local SDK and release-keystore settings. ETC2/ASTC imports are enabled for the
Android export validator; the painted 2D textures retain their lossless imports.

## Verification and boundaries

Godot 4.5.1 passed all fourteen existing suites (1,306 checks). A new fifteenth
suite exercises real scene controllers through Android Back/background routes:
15 checks cover simultaneous move/jump, contextual Use, miniature-encounter
freeze, released fingers, story/climb pause, nested Settings and studio return.
Native desktop rendering adds four screenshot checks at a wide phone-shaped
window. Both 3D friends and the touch HUD were visually checked there.

```sh
python3 tools/verify.py --godot /path/to/Godot-4.5.1
python3 tools/verify_android.py \
  --apk /path/to/Mark-and-Bark-3.8.0-Android.apk \
  --build-tools /path/to/android-sdk/build-tools/35.0.0 \
  --godot /path/to/Godot-4.5.1
```

The package verifier checks the manifest, ARM64-only architecture, permissions,
release signature, ZIP CRC, ZIP/ELF 16 KiB alignment and absence of tests/tools or
private keys. It extracts the **exact APK resources** and runs the production
seed/resume/corrupt-primary-recovery checks in fresh desktop Godot processes
(84 checks), including 3D models and all three optional encounters.

These are automated touch/controller, desktop rendering and package checks.
No Android emulator or physical phone was connected; device-specific GPU,
thermal, audio interruption and touch feel still need testing on hardware.
