import 'package:android_sideloader/adb/adb_device.dart';
import 'package:android_sideloader/logs/log.dart';
import 'package:process_run/process_run.dart';
import 'adb_path.dart';

class Adb {
  static final _shell = (() async => Shell(
    workingDirectory: await AdbPath.adbWorkingDirectoryPath,
  ))();

  static Future<void> installAPK({
    required String filePath,
    String? device,
    required void Function(String outText) onSuccess,
    required void Function(String errorMessage) onFailure,
  }) async {
    try {
      final result = await (await _shell).run(
        '"${await AdbPath.adbPath}" '
        '${device != null ? "-s $device " : ""}'
        'install "$filePath"'
      );
      Log.i("Successfully installed APK:\n${result.outText}");
      onSuccess(result.outText);
    } on ShellException catch (shellException, stackTrace) {
      Log.e(
        "Error installing APK.\n"
          "* stdout:\n${shellException.result?.outText}\n" 
          "* stderr:\n${shellException.result?.errText}", 
        error: shellException, 
        stackTrace: stackTrace
      );
      onFailure("Error: $shellException");
    }
  }

  static Future<AdbDevice?> getAdbDevice(String deviceId) async {
    final manufacturer = await getDeviceManufacturer(deviceId);
    final model = await getDeviceModel(deviceId);
    if (manufacturer == null || model == null) {
      return null;
    }
    return AdbDevice(id: deviceId, manufacturer: manufacturer, model: model);
  }

  static Future<String?> getDeviceModel(String deviceId) async {
    return await getProp(deviceId, "ro.product.model");
  }

  static Future<String?> getDeviceManufacturer(String deviceId) async {
    return await getProp(deviceId, "ro.product.manufacturer");
  }

  static Future<String?> getProp(String deviceId, String propId) async {
    try {
      final result = await (await _shell).run(
        '"${await AdbPath.adbPath}" '
        '-s $deviceId '
        'shell getprop $propId'
      );
      Log.d("Successfully got $propId: ${result.outText}");
      return result.outText;
    } on ShellException catch (shellException, stackTrace) {
      Log.e(
        "Error getting $propId.\n"
          "* stdout:\n${shellException.result?.outText}\n"
          "* stderr:\n${shellException.result?.errText}",
        error: shellException,
        stackTrace: stackTrace
      );
      return null;
    }
  }

  static Future<bool> killServer() async {
    try {
      final result = await (await _shell).run(
        '"${await AdbPath.adbPath}" '
        'kill-server'
      );
      Log.i("Successfully killed ADB server:\n${result.outText}");
      return true;
    } on ShellException catch (shellException, stackTrace) {
      Log.e(
          "Error starting ADB server.\n"
            "* stdout:\n${shellException.result?.outText}\n"
            "* stderr:\n${shellException.result?.errText}",
          error: shellException,
          stackTrace: stackTrace
      );
      return false;
    }
  }

  static Future<bool> startServer() async {
    try {
      final result = await (await _shell).run(
        '"${await AdbPath.adbPath}" '
        'start-server'
      );
      Log.i("Successfully started ADB server:\n${result.outText}");
      return true;
    } on ShellException catch (shellException, stackTrace) {
      Log.e(
        "Error starting ADB server.\n"
          "* stdout:\n${shellException.result?.outText}\n"
          "* stderr:\n${shellException.result?.errText}",
        error: shellException,
        stackTrace: stackTrace
      );
      return false;
    }
  }

  /// Install multiple APKs using adb install-multiple (for Split APKs)
  static Future<void> installMultiple({
    required List<String> filePaths,
    String? device,
    required void Function(String outText) onSuccess,
    required void Function(String errorMessage) onFailure,
  }) async {
    if (filePaths.isEmpty) {
      onFailure("No APK files provided");
      return;
    }

    // If only one file, use regular install
    if (filePaths.length == 1) {
      return installAPK(
        filePath: filePaths.first,
        device: device,
        onSuccess: onSuccess,
        onFailure: onFailure,
      );
    }

    try {
      Log.i("Installing ${filePaths.length} APKs using install-multiple");

      // Build command: adb install-multiple "file1.apk" "file2.apk" ...
      final quotedPaths = filePaths.map((p) => '"$p"').join(' ');
      final command = '"${await AdbPath.adbPath}" '
          '${device != null ? "-s $device " : ""}'
          'install-multiple $quotedPaths';

      final result = await (await _shell).run(command);
      Log.i("Successfully installed multiple APKs:\n${result.outText}");
      onSuccess(result.outText);
    } on ShellException catch (shellException, stackTrace) {
      Log.e(
        "Error installing multiple APKs.\n"
          "* stdout:\n${shellException.result?.outText}\n"
          "* stderr:\n${shellException.result?.errText}",
        error: shellException,
        stackTrace: stackTrace
      );
      onFailure("Error: $shellException");
    }
  }

  /// Push a file to the device
  static Future<bool> pushFile({
    required String localPath,
    required String remotePath,
    String? device,
  }) async {
    try {
      Log.i("Pushing file: $localPath -> $remotePath");

      // Create target directory first
      final remoteDir = remotePath.substring(0, remotePath.lastIndexOf('/'));
      await (await _shell).run(
        '"${await AdbPath.adbPath}" '
        '${device != null ? "-s $device " : ""}'
        'shell mkdir -p "$remoteDir"'
      );

      // Push file
      final result = await (await _shell).run(
        '"${await AdbPath.adbPath}" '
        '${device != null ? "-s $device " : ""}'
        'push "$localPath" "$remotePath"'
      );

      Log.i("Successfully pushed file:\n${result.outText}");
      return true;
    } on ShellException catch (shellException, stackTrace) {
      Log.e(
        "Error pushing file.\n"
          "* stdout:\n${shellException.result?.outText}\n"
          "* stderr:\n${shellException.result?.errText}",
        error: shellException,
        stackTrace: stackTrace
      );
      return false;
    }
  }

  /// Push multiple OBB files
  static Future<bool> pushObbFiles({
    required List<({String localPath, String remotePath})> files,
    String? device,
    void Function(int current, int total, String fileName)? onProgress,
  }) async {
    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      onProgress?.call(i + 1, files.length, file.localPath.split('/').last);

      final success = await pushFile(
        localPath: file.localPath,
        remotePath: file.remotePath,
        device: device,
      );

      if (!success) {
        Log.e("Failed to push OBB file: ${file.localPath}");
        return false;
      }
    }
    return true;
  }
}
