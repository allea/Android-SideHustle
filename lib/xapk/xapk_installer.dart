import '../adb/adb.dart';
import '../logs/log.dart';
import 'xapk_parser.dart';

/// Installation progress stage
enum InstallStage {
  parsing,
  installing,
  pushingObb,
  cleaning,
  completed,
  failed,
}

/// Installation progress callback
typedef InstallProgressCallback = void Function(
  InstallStage stage,
  String message,
  double progress,
);

class XapkInstaller {
  /// Install XAPK file
  static Future<void> install({
    required String xapkPath,
    required String deviceId,
    required void Function(String message) onSuccess,
    required void Function(String error) onFailure,
    InstallProgressCallback? onProgress,
  }) async {
    XapkParseResult? parseResult;

    try {
      // Stage 1: Parse XAPK
      onProgress?.call(InstallStage.parsing, 'Parsing XAPK file...', 0.1);
      Log.i("Starting XAPK installation: $xapkPath");

      parseResult = await XapkParser.parse(xapkPath);
      Log.i("XAPK parsed: ${parseResult.manifest.packageName}, "
          "${parseResult.allApkPaths.length} APKs, "
          "${parseResult.obbFiles.length} OBB files");

      if (parseResult.allApkPaths.isEmpty) {
        throw Exception('No APK files found in XAPK');
      }

      // Stage 2: Install APK(s)
      onProgress?.call(InstallStage.installing, 'Installing APK(s)...', 0.3);

      bool installSuccess = false;
      String installMessage = '';

      await Adb.installMultiple(
        filePaths: parseResult.allApkPaths,
        device: deviceId,
        onSuccess: (msg) {
          installSuccess = true;
          installMessage = msg;
        },
        onFailure: (err) {
          installSuccess = false;
          installMessage = err;
        },
      );

      if (!installSuccess) {
        throw Exception('APK installation failed: $installMessage');
      }

      // Stage 3: Push OBB files (if any)
      if (parseResult.hasObbFiles) {
        onProgress?.call(
          InstallStage.pushingObb,
          'Pushing ${parseResult.obbFiles.length} OBB file(s)...',
          0.6,
        );

        final obbFiles = parseResult.obbFiles
            .map((o) => (localPath: o.localPath, remotePath: o.remotePath))
            .toList();

        final obbSuccess = await Adb.pushObbFiles(
          files: obbFiles,
          device: deviceId,
          onProgress: (current, total, fileName) {
            const baseProgress = 0.6;
            final obbProgress = (current / total) * 0.3;
            onProgress?.call(
              InstallStage.pushingObb,
              'Pushing OBB ($current/$total): $fileName',
              baseProgress + obbProgress,
            );
          },
        );

        if (!obbSuccess) {
          // OBB push failed, but APK is installed, give warning instead of failure
          Log.w("OBB files push failed, app may not work correctly");
          onProgress?.call(
            InstallStage.completed,
            'App installed but OBB files failed to push',
            1.0,
          );
          onSuccess('App installed (Warning: OBB files failed to push)');
          return;
        }
      }

      // Stage 4: Cleanup
      onProgress?.call(InstallStage.cleaning, 'Cleaning up...', 0.95);
      await XapkParser.cleanup(parseResult);

      // Completed
      onProgress?.call(InstallStage.completed, 'Installation completed!', 1.0);
      final message = parseResult.hasObbFiles
          ? 'App and OBB files installed successfully!'
          : 'App installed successfully!';
      onSuccess(message);
    } catch (e, stackTrace) {
      Log.e("XAPK installation failed", error: e, stackTrace: stackTrace);
      onProgress?.call(InstallStage.failed, 'Installation failed: $e', 0.0);
      onFailure('Installation failed: $e');

      // Cleanup temporary files
      if (parseResult != null) {
        await XapkParser.cleanup(parseResult);
      }
    }
  }
}
