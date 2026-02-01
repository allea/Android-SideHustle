# XAPK Sideloading Support

## Overview

Added support for XAPK file format installation. XAPK is a ZIP-based package format that can contain:
- **base.apk** - The main APK file
- **Split APKs** - Architecture/language specific APKs (e.g., config.arm64_v8a.apk)
- **OBB files** - Expansion data files
- **manifest.json** - Package metadata

## New Files

| File | Description |
|------|-------------|
| `lib/xapk/xapk_manifest.dart` | Data model for parsing manifest.json |
| `lib/xapk/xapk_parser.dart` | XAPK extraction and parsing logic |
| `lib/xapk/xapk_installer.dart` | Installation flow controller with progress tracking |
| `lib/ui/install_progress_dialog.dart` | Progress dialog UI for XAPK installation |

## Modified Files

### `pubspec.yaml`
- Added `archive: ^3.6.1` dependency for ZIP extraction

### `lib/adb/adb.dart`
- Added `installMultiple()` method for split APK installation using `adb install-multiple`
- Added `pushFile()` method for pushing files to device using `adb push`
- Added `pushObbFiles()` method for batch OBB file pushing with progress callback

### `lib/ui/drag_and_drop_apk.dart`
- Added `PackageType` enum (`apk`, `xapk`)
- Extended drop handler to accept `.xapk` files
- Updated callback signature to include file type

### `lib/ui/home_screen.dart`
- Added `_selectedFileType` state variable
- Extended file picker to accept both `.apk` and `.xapk` extensions
- Added `_installXapk()` method with progress dialog
- Updated UI to show different icons and labels for XAPK files

### `lib/util/file_path.dart`
- Added `createTempSubDir()` for creating temporary directories
- Added `cleanupTempDir()` for cleaning up specific directories
- Added `cleanupAllXapkTemp()` for cleaning all XAPK temporary files

## Installation Flow

```
1. User selects/drops XAPK file
       ↓
2. Progress dialog appears
       ↓
3. Parse XAPK (extract to temp directory)
       ↓
4. Install APKs (adb install-multiple)
       ↓
5. Push OBB files if present (adb push)
       ↓
6. Cleanup temporary files
       ↓
7. Show result
```

## Error Handling

| Error | Handling |
|-------|----------|
| Invalid XAPK format | Show "Invalid XAPK format" error |
| Missing manifest.json | Show format error |
| APK installation failed | Show ADB error message |
| OBB push failed | Warning only (APK already installed) |
| Disk space insufficient | Show IO error |

## Bug Fixes

- Fixed `version_code` parsing to handle both integer and string types in manifest.json
