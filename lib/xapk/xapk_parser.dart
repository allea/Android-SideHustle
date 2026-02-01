import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import '../logs/log.dart';
import '../util/file_path.dart';
import 'xapk_manifest.dart';

/// XAPK parse result
class XapkParseResult {
  final XapkManifest manifest;
  final String extractDir;
  final String? baseApkPath;
  final List<String> splitApkPaths;
  final List<XapkObbExtracted> obbFiles;

  XapkParseResult({
    required this.manifest,
    required this.extractDir,
    this.baseApkPath,
    this.splitApkPaths = const [],
    this.obbFiles = const [],
  });

  /// Get all APK file paths (for install-multiple)
  List<String> get allApkPaths {
    final paths = <String>[];
    if (baseApkPath != null) paths.add(baseApkPath!);
    paths.addAll(splitApkPaths);
    return paths;
  }

  /// Whether install-multiple is needed
  bool get requiresMultipleInstall => allApkPaths.length > 1;

  /// Whether OBB files are present
  bool get hasObbFiles => obbFiles.isNotEmpty;
}

class XapkObbExtracted {
  final String localPath;
  final String remotePath;

  XapkObbExtracted({required this.localPath, required this.remotePath});
}

class XapkParser {
  /// Parse XAPK file
  static Future<XapkParseResult> parse(String xapkPath) async {
    Log.i("Starting XAPK parse: $xapkPath");

    // 1. Create unique extract directory
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final xapkName = p.basenameWithoutExtension(xapkPath);
    final extractDir = await _createExtractDir('xapk_${xapkName}_$timestamp');

    try {
      // 2. Read XAPK file (ZIP format)
      final bytes = await File(xapkPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // 3. Parse manifest.json
      final manifest = await _parseManifest(archive);
      Log.i("Parsed manifest: package=${manifest.packageName}");

      // 4. Extract APK files
      String? baseApkPath;
      final splitApkPaths = <String>[];
      final obbFiles = <XapkObbExtracted>[];

      // Track which split apks we've already extracted
      final extractedSplits = <String>{};

      for (final file in archive.files) {
        if (file.isFile) {
          final fileName = file.name.toLowerCase();
          final baseName = p.basename(file.name).toLowerCase();

          if (baseName == 'base.apk' ||
              (fileName.endsWith('.apk') && baseName.contains('base'))) {
            // base.apk
            baseApkPath = await _extractFile(file, extractDir);
            Log.d("Extracted base APK: $baseApkPath");
          } else if (fileName.endsWith('.apk')) {
            // Split APK
            final path = await _extractFile(file, extractDir);
            splitApkPaths.add(path);
            extractedSplits.add(baseName);
            Log.d("Extracted split APK: $path");
          } else if (fileName.endsWith('.obb')) {
            // OBB file
            final localPath = await _extractFile(file, extractDir);
            final remotePath = _buildObbRemotePath(
              manifest.packageName,
              file.name,
              manifest.obbFiles,
            );
            obbFiles.add(XapkObbExtracted(
              localPath: localPath,
              remotePath: remotePath,
            ));
            Log.d("Extracted OBB: $localPath -> $remotePath");
          }
        }
      }

      // Handle split_apks from manifest that weren't extracted yet
      for (final splitName in manifest.splitApks) {
        if (extractedSplits.contains(splitName.toLowerCase())) continue;

        for (final archiveFile in archive.files) {
          final baseName = p.basename(archiveFile.name).toLowerCase();
          if (baseName == splitName.toLowerCase() ||
              archiveFile.name.toLowerCase().endsWith('/$splitName'.toLowerCase())) {
            if (archiveFile.size > 0) {
              final path = await _extractFile(archiveFile, extractDir);
              splitApkPaths.add(path);
              Log.d("Extracted additional split APK: $path");
            }
            break;
          }
        }
      }

      // Handle expansions (alternative OBB format)
      for (final expansion in manifest.expansions) {
        for (final archiveFile in archive.files) {
          if (p.basename(archiveFile.name).toLowerCase() ==
              expansion.file.toLowerCase()) {
            final localPath = await _extractFile(archiveFile, extractDir);
            obbFiles.add(XapkObbExtracted(
              localPath: localPath,
              remotePath: expansion.installPath.isNotEmpty
                  ? expansion.installPath
                  : '/sdcard/Android/obb/${manifest.packageName}/${expansion.file}',
            ));
            Log.d("Extracted expansion: $localPath");
            break;
          }
        }
      }

      return XapkParseResult(
        manifest: manifest,
        extractDir: extractDir,
        baseApkPath: baseApkPath,
        splitApkPaths: splitApkPaths,
        obbFiles: obbFiles,
      );
    } catch (e, stackTrace) {
      Log.e("Failed to parse XAPK", error: e, stackTrace: stackTrace);
      // Cleanup extract directory
      await _cleanupDir(extractDir);
      rethrow;
    }
  }

  static Future<XapkManifest> _parseManifest(Archive archive) async {
    final manifestFile = archive.files.firstWhere(
      (f) => f.name.toLowerCase() == 'manifest.json',
      orElse: () => throw const FormatException('manifest.json not found in XAPK'),
    );

    final content = utf8.decode(manifestFile.content as List<int>);
    final json = jsonDecode(content) as Map<String, dynamic>;
    return XapkManifest.fromJson(json);
  }

  static Future<String> _createExtractDir(String name) async {
    final basePath = await FilePath.path;
    final dir = Directory(p.join(basePath, 'xapk_temp', name));
    await dir.create(recursive: true);
    return dir.path;
  }

  static Future<String> _extractFile(ArchiveFile file, String extractDir) async {
    final filePath = p.join(extractDir, p.basename(file.name));
    final outFile = File(filePath);
    await outFile.writeAsBytes(file.content as List<int>);
    return filePath;
  }

  static String _buildObbRemotePath(
    String packageName,
    String fileName,
    List<XapkObbFile> obbManifest,
  ) {
    // Try to get path from manifest first
    for (final obb in obbManifest) {
      if (fileName.contains(obb.file)) {
        return obb.installPath;
      }
    }
    // Default OBB path format
    return '/sdcard/Android/obb/$packageName/${p.basename(fileName)}';
  }

  static Future<void> _cleanupDir(String dirPath) async {
    try {
      final dir = Directory(dirPath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        Log.d("Cleaned up directory: $dirPath");
      }
    } catch (e) {
      Log.w("Failed to cleanup directory: $dirPath", error: e);
    }
  }

  /// Cleanup parse result temporary files
  static Future<void> cleanup(XapkParseResult result) async {
    await _cleanupDir(result.extractDir);
  }
}
