import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

import '../logs/log.dart';

/// Supported package types
enum PackageType { apk, xapk }

class DragAndDropApk extends StatefulWidget {
  final Widget child;
  final Function(String path, PackageType type) onPackageDropped;

  const DragAndDropApk({
    super.key,
    required this.child,
    required this.onPackageDropped,
  });

  @override
  State<DragAndDropApk> createState() => _DragAndDropApkState();
}

class _DragAndDropApkState extends State<DragAndDropApk> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (details) {
        Log.d("onDragEntered");
        setState(() {
          _isDragging = true;
        });
      },
      onDragExited: (details) {
        Log.d("onDragExited");
        setState(() {
          _isDragging = false;
        });
      },
      onDragDone: (details) async {
        Log.d("onDragDone");
        if (details.files.isNotEmpty) {
          final file = details.files.first;
          final fileName = file.name.toLowerCase();

          if (fileName.endsWith('.apk')) {
            _handlePackageDropped(file.path, PackageType.apk);
          } else if (fileName.endsWith('.xapk')) {
            _handlePackageDropped(file.path, PackageType.xapk);
          } else {
            _handleInvalidFileDropped();
          }
        } else {
          Log.w("Dropped empty files list");
        }
      },
      child: Stack(
        children: [
          widget.child,
          if (_isDragging)
            Positioned.fill(
              child: Stack(
                children: [
                  Container(
                    color: Colors.black.withAlpha(128),
                  ),
                  AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    content: Padding(
                      padding: const EdgeInsets.all(64.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.file_download,
                            size: 50,
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Drag and drop your APK or XAPK file here',
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _handlePackageDropped(String filePath, PackageType type) {
    Log.i("${type.name.toUpperCase()} file dropped: $filePath");
    widget.onPackageDropped(filePath, type);
    setState(() {
      _isDragging = false;
    });
  }

  void _handleInvalidFileDropped() {
    Log.w("Invalid file dropped");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        icon: const Icon(Icons.warning_rounded, color: Colors.orange, size: 48),
        title: const Text('Invalid File'),
        content: const Text(
          'You can only drag and drop APK or XAPK files here',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
