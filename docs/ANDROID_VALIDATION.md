# Neon Switch — Android Debug Build and Device Validation

This document covers the reproducible Android debug build and the remaining physical-device checks for Foundation Step 11.

## Current Build

```text
Project version: 0.1.0-dev.11
Preset: Android Debug
Package: com.elijah.neonswitch
Output: build/android/neon-switch-debug.apk
Architecture: arm64-v8a
CI export: passing
```

The committed preset contains no private signing material. Each CI run creates a disposable debug keystore, so the signed APK checksum changes between runs. Always verify an APK against the `.sha256` file distributed in the same workflow artifact.

## Required Tools on Windows

Install:

1. Godot 4.6.3 and its matching export templates.
2. OpenJDK 17.
3. Android Studio with the Android SDK.
4. Android SDK Platform-Tools 35.0.0 or later.
5. Android SDK Build-Tools 35.0.1.
6. Android SDK Platform 35.
7. Android SDK Command-line Tools (latest).
8. CMake 3.10.2.4988404.
9. Android NDK 28.1.13356709.

Official guide:

```text
https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_android.html
```

## Configure Godot

Open:

```text
Editor → Editor Settings → Export → Android
```

Set:

- **Java SDK Path** to the OpenJDK 17 installation directory.
- **Android SDK Path** to the SDK directory containing `platform-tools/adb.exe`.

A common Windows SDK location is:

```text
%LOCALAPPDATA%\Android\Sdk
```

Install the matching Godot export templates through:

```text
Editor → Manage Export Templates
```

The project already enables Android texture imports:

```text
rendering/textures/vram_compression/import_etc2_astc=true
```

## Export Locally

### Godot editor

1. Open **Project → Export**.
2. Select **Android Debug**.
3. Leave **Export With Debug** enabled.
4. Click **Export Project**.
5. Save to `build/android/neon-switch-debug.apk`.

### Command line

```powershell
New-Item -ItemType Directory -Force build/android | Out-Null
& "C:\Path\To\Godot_v4.6.3-stable_win64.exe" `
  --path . `
  --export-debug "Android Debug" `
  "build/android/neon-switch-debug.apk"
```

The machine must already have Android paths and a debug keystore configured in Godot.

## Automated GitHub Build

The workflow is:

```text
.github/workflows/android-debug-build.yml
```

It installs the complete toolchain, downloads Godot and its matching templates, creates a disposable debug keystore, imports the project, exports the APK, records its SHA-256 checksum, and uploads both as workflow artifacts.

## Verify the Downloaded APK

Keep the APK and checksum file from the same artifact together, then run:

```powershell
Get-FileHash .\neon-switch-debug.apk -Algorithm SHA256
Get-Content .\android-apk.sha256
```

The two hexadecimal values must match. A checksum from a different CI run is not expected to match because that run used a different disposable signing key.

## Install on a Phone

Enable Developer Options and USB debugging, connect the Android device by USB, then run:

```powershell
adb devices
adb install -r .\neon-switch-debug.apk
```

If Android reports a signing conflict, remove the older debug package first:

```powershell
adb uninstall com.elijah.neonswitch
adb install .\neon-switch-debug.apk
```

Launch normally from the phone, or use:

```powershell
adb shell monkey -p com.elijah.neonswitch -c android.intent.category.LAUNCHER 1
```

## Physical Device Test Matrix

Record results in [`ANDROID_DEVICE_TEST_REPORT.md`](ANDROID_DEVICE_TEST_REPORT.md).

### Installation and startup

- APK installs without package or signing errors.
- App icon and name appear correctly.
- App launches without a black screen or crash.
- The debug version reads `v0.1.0-dev.11`.

### Display

- Portrait orientation is enforced.
- The playfield is horizontally centered.
- Tall screens reveal more vertical background rather than moving lanes sideways.
- Score, best score, shards, panels, and version label remain visible.
- Camera cutouts and gesture-navigation regions do not cover important UI.
- No unintended stretching or clipped rails appear.

### Input

- First tap starts the run once.
- Each later primary tap switches exactly one lane.
- Holds and releases do not generate duplicate switches.
- Rapid taps do not bypass transition guards.
- Edge taps remain responsive.

### Audio and haptics

- Start sound plays once.
- Switch sound and light haptic occur together.
- Collect sound and haptic occur once.
- Crash sound and stronger haptic occur once.
- Speaker and headphone playback are clear and comfortable.

### Lifecycle and persistence

- App survives app switching, screen lock, and unlock.
- No duplicate audio begins after resume.
- Touch still works after resume.
- A run does not enter an impossible state after interruption.
- Closing and reopening preserves the best score.

### Stability

- Complete at least ten runs and restarts.
- Play for at least ten minutes.
- Watch for stutter, overheating, or unusual battery drain.
- Capture `adb logcat` if the app crashes or freezes.

## Capturing Logs

```powershell
adb logcat -c
adb logcat > neon-switch-logcat.txt
```

Stop capture with `Ctrl+C` after reproducing the issue. A filtered view is:

```powershell
adb logcat | Select-String "Godot|neonswitch|AndroidRuntime"
```

## Release Boundary

Do not use the debug keystore for Google Play. A release build requires a private release keystore, protected credentials, a long-term package identity, and an Android App Bundle (`.aab`). Those belong to the release-preparation phase.
