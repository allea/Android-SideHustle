import 'dart:io';
import 'package:android_sideloader/util/extensions.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../logs/log.dart';

class FilePath {
  static Future<String> get path async {
    return (await directory).path;
  }

  static Future<Directory>? _directory;
  static Future<Directory> get directory async {
    return _directory ??= _initializeDir();
  }

  static Future<Directory> _initializeDir() async {
    final Directory tempDir = await getTemporaryDirectory();
    final path = p.normalize('${tempDir.path}/android_sideloader');
    final ret = await Directory(path).create(recursive: true);
    Log.d("Initialized data directory: ${ret.path}");
    return ret;
  }

  static Future<File> getFile(String newPath) async {
    final file = File(p.normalize('${await path}/$newPath'));
    if (!await file.exists()) {
      await file.create(recursive: true);
    }
    Log.d("Getting / creating file: ${file.path}");
    return file;
  }

  static Future<File> extractAsset(String assetPath) async {
    final file = await getFile(assetPath);
    final asset = await rootBundle.load(assetPath);
    if (await file.isEqualToByteData(asset)) {
      Log.i("Asset already exists: $assetPath");
      return file;
    }
    final ret = await file.writeAsBytes(asset.buffer.asUint8List());
    Log.d("Extracted asset: ${ret.path}");
    return ret;
  }

  /// Create a temporary subdirectory
  static Future<Directory> createTempSubDir(String name) async {
    final basePath = await path;
    final dir = Directory(p.join(basePath, name));
    await dir.create(recursive: true);
    Log.d("Created temp subdirectory: ${dir.path}");
    return dir;
  }

  /// Cleanup a temporary directory
  static Future<void> cleanupTempDir(String dirPath) async {
    try {
      final dir = Directory(dirPath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        Log.d("Cleaned up temp directory: $dirPath");
      }
    } catch (e, stackTrace) {
      Log.w("Failed to cleanup temp directory: $dirPath",
          error: e, stackTrace: stackTrace);
    }
  }

  /// Cleanup all XAPK temporary files
  static Future<void> cleanupAllXapkTemp() async {
    try {
      final basePath = await path;
      final xapkTempDir = Directory(p.join(basePath, 'xapk_temp'));
      if (await xapkTempDir.exists()) {
        await xapkTempDir.delete(recursive: true);
        Log.i("Cleaned up all XAPK temp files");
      }
    } catch (e, stackTrace) {
      Log.w("Failed to cleanup XAPK temp files",
          error: e, stackTrace: stackTrace);
    }
  }
}
