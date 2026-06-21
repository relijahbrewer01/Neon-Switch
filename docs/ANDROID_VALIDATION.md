# Neon Switch — Android Debug Build and Device Validation

This document covers the reproducible Android debug build and the remaining physical-device checks for Foundation Step 11.

## Current Build

```text
Project version: 0.1.0-dev.11
Preset: Android Debug
Package: com.elijah.neonswitch
Output: build/android/neon-switch-debug.apk
Architecture: arm64-v8a
CI result: PASS
APK SHA-256: 271d282836093fc59452531c942c0c3295033d1aafc9bb2c6d0d4389e5570932
```

The committed preset contains no private signing material. Local and CI debug builds use a disposable or machine-local debug keystore.

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

The official Godot Android export guide is:

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
- **Android SDK Path** to the Android SDK directory containing `platform-tools/adb.exe`.

A common Windows Android SDK location is:

```text
%LOCALAPPDATA%\Android\Sdk
```

Install the matching Godot 4.6.3 export templates through:

```text
Editor → Manage Export Templates
```

The project enables:

```text
rendering/textures/vram_compression/import_etc2_astc=true
```

Godot requires the Android texture-import format before it considers the Android preset exportable.

## Export Locally

### Godot editor

1. Open **Project → Export**.
2. Select **Android Debug**.
3. Leave **Export With Debug** enabled.
4. Click **Export Project**.
5. Save to:

```text
build/android/neon-switch-debug.apk
```

### Command line

From the repository root:

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

It:

1. Installs OpenJDK 17.
2. Installs the Android platform, Build-Tools, CMake, and NDK.
3. Downloads Godot 4.6.3 and matching export templates.
4. Creates a disposable debug keystore.
5. Imports the project and Android texture formats.
6. Exports `neon-switch-debug.apk`.
7. Records a SHA-256 checksum.
8. Uploads the APK and export logs as workflow artifacts.

The CI keystore is intentionally disposable. CI builds are for installation and testing, not Play Store release.

## Verify the APK

On Windows PowerShell:

```powershell
Get-FileHash .\build\android\neon-switch-debug.apk -Algorithm SHA256
```

Expected checksum for the validated centered-layout `0.1.0-dev.11` artifact:

```text
271D282836093FC59452531C942C0C3295033D1AAFC9BB2C6D0D4389E5570932
```

A different checksum is normal after any source, resource, export-template, or signing-key change. The important check is that the downloaded APK matches the checksum distributed alongside that same artifact.

## Install on a Phone

Enable Developer Options and USB debugging on the Android device, connect it by USB, then run:

```powershell
adb devices
adb install -r build/android/neon-switch-debug.apk
```

If Android reports a signing conflict, uninstall the older debug package first:

```powershell
adb uninstall com.elijah.neonswitch
adb install build/android/neon-switch-debug.apk
```

Launch from the phone normally, or use:

```powershell
adb shell monkey -p com.elijah.neonswitch -c android.intent.category.LAUNCHER 1
```

## Physical Device Test Matrix

Record results in [`ANDROID_DEVICE_TEST_REPORT.md`](ANDROID_DEVICE_TEST_REPORT.md).

### Installation and startup

- APK installs without package or signing errors.
- App icon and application name appear correctly.
- App launches without a black screen or crash.
- The debug version reads `v0.1.0-dev.11`.

### Display

- Portrait orientation is enforced.
- The playfield is horizontally centered.
- Tall screens reveal more vertical background rather than shifting lanes sideways.
- Score, best score, shards, panels, and version label remain visible.
- Camera cutouts do not cover important UI.
- Gesture-navigation areas do not cover the footer or restart prompt.
- No unintended stretching or clipped rails appear.

### Input

- First tap starts the run.
- Each later primary tap switches exactly one lane.
- Holding or releasing does not produce duplicate switches.
- Rapid tapping does not bypass transition guards.
- Touch remains responsive near screen edges and cutouts.

### Audio and haptics

- Start sound plays once.
- Switch sound and light haptic occur together.
- Collect sound and haptic occur once.
- Crash sound and stronger haptic occur once.
- Phone speaker playback is clear and not painfully loud.
- Headphone playback works.
- Silent or Do Not Disturb behavior is reasonable for the device.

### Lifecycle

- App survives switching to another app and returning.
- App survives locking and unlocking the phone.
- No duplicate audio begins after resume.
- Touch still works after resume.
- A run does not enter an impossible state after interruption.
- Closing and reopening preserves the best score.

### Stability

- Complete at least ten runs and restarts.
- Play for at least ten minutes.
- Watch for frame pacing problems, overheating, or battery drain.
- Capture `adb logcat` if the app crashes or freezes.

## Capturing Logs

Clear old logs before reproducing a problem:

```powershell
adb logcat -c
```

Capture logs to a file:

```powershell
adb logcat > neon-switch-logcat.txt
```

Stop with `Ctrl+C` after reproducing the issue.

For a filtered view:

```powershell
adb logcat | Select-String "Godot|neonswitch|AndroidRuntime"
```

## Release Boundary

Do not use the debug keystore for Google Play. A release build requires a private release keystore, protected credentials, a unique long-term package identity, and an Android App Bundle (`.aab`). Those belong to the later release-preparation phase.
