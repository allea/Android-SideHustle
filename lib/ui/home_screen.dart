import 'dart:io';

import 'package:android_sideloader/util/extensions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../adb/adb.dart';
import '../adb/adb_device.dart';
import '../logs/log.dart';
import '../logs/save_logs_button.dart';
import '../xapk/xapk_installer.dart';
import 'device_list_widget.dart';
import 'drag_and_drop_apk.dart';
import 'install_progress_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AdbDevice? _selectedDevice;
  String? _selectedFile;
  PackageType? _selectedFileType;

  String? get _selectedFileName =>
      _selectedFile?.split(Platform.pathSeparator).last;

  bool get _isButtonEnabled =>
      _selectedDevice != null && _selectedFile != null;

  bool get _isXapk => _selectedFileType == PackageType.xapk;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['apk', 'xapk'],
    );

    final path = result?.files.single.path;
    if (path != null) {
      final isXapk = path.toLowerCase().endsWith('.xapk');
      setState(() {
        _selectedFile = path;
        _selectedFileType = isXapk ? PackageType.xapk : PackageType.apk;
        Log.i("Selected ${isXapk ? 'XAPK' : 'APK'} file: $_selectedFile");
      });
    } else {
      Log.w("Did not pick good file: $result");
    }
  }

  Future<void> _install() async {
    final selectedFile = _selectedFile;
    final deviceId = _selectedDevice?.id;
    if (selectedFile == null || deviceId == null) {
      return;
    }

    if (_isXapk) {
      await _installXapk(selectedFile, deviceId);
    } else {
      await _installApk(selectedFile, deviceId);
    }
  }

  Future<void> _installApk(String filePath, String deviceId) async {
    Adb.installAPK(
      device: deviceId,
      filePath: filePath,
      onSuccess: (outText) {
        Log.i("Successfully installed APK file $_selectedFile:\n$outText");
        _showSnackBar('App successfully installed!', isError: false);
      },
      onFailure: (errorMessage) {
        Log.w("Failed to install APK file $_selectedFile:\n$errorMessage");
        _showSnackBar('Failed to install app: $errorMessage', isError: true);
      },
    );
  }

  Future<void> _installXapk(String filePath, String deviceId) async {
    final result = await InstallProgressDialog.show(
      context: context,
      fileName: _selectedFileName ?? 'XAPK',
      installer: (onProgress) => XapkInstaller.install(
        xapkPath: filePath,
        deviceId: deviceId,
        onSuccess: (msg) => Log.i("XAPK installed: $msg"),
        onFailure: (err) => Log.e("XAPK install failed: $err"),
        onProgress: onProgress,
      ),
    );

    if (result == true) {
      _showSnackBar('XAPK successfully installed!', isError: false);
    } else if (result == false) {
      _showSnackBar('Failed to install XAPK', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red.shade700 : null,
        ),
      );
    }
  }

  void _launchHelpURL() async {
    final Uri url = Uri.parse(
        'https://github.com/ryan-andrew/android_sideloader?tab=readme-ov-file#android-sideloader');
    if (!await launchUrl(url)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DragAndDropApk(
      onPackageDropped: (String path, PackageType type) {
        setState(() {
          _selectedFile = path;
          _selectedFileType = type;
        });
      },
      child: Scaffold(
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SaveLogButton(),
            const SizedBox(width: 8),
            Tooltip(
              message: "More Information",
              child: IconButton(
                onPressed: () => _launchHelpURL(),
                icon: const Icon(Icons.help),
              ),
            ),
          ],
        ),
        body: Row(
          children: [
            DeviceListWidget(
              onDeviceSelected: (device) {
                Log.i("Selected device $device");
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() => _selectedDevice = device);
                });
              },
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildFileStatus(theme),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _pickFile,
                          child: const Text('Choose APK/XAPK File'),
                        ),
                        const SizedBox(width: 40),
                        ElevatedButton(
                          onPressed: _isButtonEnabled ? _install : null,
                          child: Text(_isXapk ? 'Install XAPK' : 'Install APK'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileStatus(ThemeData theme) {
    if (_selectedFile == null) {
      return Text(
        'No file selected',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.red.lerp(theme.colorScheme.onSurface, 0.3),
        ),
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isXapk ? Icons.folder_zip : Icons.android,
              size: 20,
              color: Colors.green.lerp(theme.colorScheme.onSurface, 0.3),
            ),
            const SizedBox(width: 8),
            Text(
              'Selected ${_isXapk ? "XAPK" : "APK"}: $_selectedFileName',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.green.lerp(theme.colorScheme.onSurface, 0.3),
              ),
            ),
          ],
        ),
        if (_isXapk)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '(Contains split APKs and/or OBB files)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
      ],
    );
  }
}
