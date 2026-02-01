import 'package:flutter/material.dart';
import '../xapk/xapk_installer.dart';

class InstallProgressDialog extends StatefulWidget {
  final String fileName;
  final Future<void> Function(InstallProgressCallback onProgress) installer;

  const InstallProgressDialog({
    super.key,
    required this.fileName,
    required this.installer,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String fileName,
    required Future<void> Function(InstallProgressCallback onProgress) installer,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => InstallProgressDialog(
        fileName: fileName,
        installer: installer,
      ),
    );
  }

  @override
  State<InstallProgressDialog> createState() => _InstallProgressDialogState();
}

class _InstallProgressDialogState extends State<InstallProgressDialog> {
  InstallStage _stage = InstallStage.parsing;
  String _message = 'Starting installation...';
  double _progress = 0.0;
  bool _completed = false;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _startInstallation();
  }

  Future<void> _startInstallation() async {
    await widget.installer((stage, message, progress) {
      if (mounted) {
        setState(() {
          _stage = stage;
          _message = message;
          _progress = progress;

          if (stage == InstallStage.completed) {
            _completed = true;
            _success = true;
          } else if (stage == InstallStage.failed) {
            _completed = true;
            _success = false;
          }
        });
      }
    });
  }

  IconData _getStageIcon() {
    switch (_stage) {
      case InstallStage.parsing:
        return Icons.folder_zip;
      case InstallStage.installing:
        return Icons.install_mobile;
      case InstallStage.pushingObb:
        return Icons.cloud_upload;
      case InstallStage.cleaning:
        return Icons.cleaning_services;
      case InstallStage.completed:
        return Icons.check_circle;
      case InstallStage.failed:
        return Icons.error;
    }
  }

  Color _getStageColor() {
    switch (_stage) {
      case InstallStage.completed:
        return Colors.green;
      case InstallStage.failed:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: [
          Icon(_getStageIcon(), color: _getStageColor()),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _completed
                  ? (_success ? 'Installation Complete' : 'Installation Failed')
                  : 'Installing ${widget.fileName}',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_message),
          const SizedBox(height: 16),
          if (!_completed) ...[
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 8),
            Text(
              '${(_progress * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
      actions: _completed
          ? [
              TextButton(
                onPressed: () => Navigator.of(context).pop(_success),
                child: const Text('OK'),
              ),
            ]
          : null,
    );
  }
}
