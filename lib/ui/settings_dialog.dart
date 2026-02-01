import 'package:flutter/material.dart';

import '../services/preferences.dart';

class SettingsDialog extends StatefulWidget {
  final VoidCallback onSettingsChanged;

  const SettingsDialog({super.key, required this.onSettingsChanged});

  static Future<void> show(BuildContext context, {required VoidCallback onSettingsChanged}) {
    return showDialog(
      context: context,
      builder: (context) => SettingsDialog(onSettingsChanged: onSettingsChanged),
    );
  }

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late bool _showSerialNumber;

  @override
  void initState() {
    super.initState();
    _showSerialNumber = Preferences.showSerialNumber;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Show Serial Number'),
            subtitle: const Text('Display device serial number in the device list'),
            value: _showSerialNumber,
            onChanged: (value) async {
              await Preferences.setShowSerialNumber(value);
              setState(() {
                _showSerialNumber = value;
              });
              widget.onSettingsChanged();
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
