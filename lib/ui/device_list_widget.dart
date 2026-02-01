import 'package:android_sideloader/adb/adb_device.dart';
import 'package:android_sideloader/ui/device_list_item.dart';
import 'package:flutter/material.dart';

import '../adb/adb_device_tracker.dart';
import '../logs/log.dart';

class DeviceListWidget extends StatefulWidget {
  final void Function(AdbDevice? selectedDevice) onDeviceSelected;
  final bool showSerialNumber;

  const DeviceListWidget({
    super.key,
    required this.onDeviceSelected,
    this.showSerialNumber = true,
  });

  @override
  State<DeviceListWidget> createState() => _DeviceListWidgetState();
}

class _DeviceListWidgetState extends State<DeviceListWidget> {
  final AdbDeviceTracker _tracker = AdbDeviceTracker();
  AdbDevice? _selectedDevice;
  List<AdbDevice> _devices = [];
  bool _isListeningStarted = false;

  @override
  void initState() {
    super.initState();
    _tracker.startTracking(
      onDeviceChange: (devices) {
        setState(() {
          _devices = devices;
          _isListeningStarted = true;
        });
      },
    );
  }

  @override
  void dispose() {
    _tracker.stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: SizedBox(
        width: 250,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Connected Devices',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (!_isListeningStarted) {
                    return const Center(
                        child: CircularProgressIndicator()
                    );
                  }
                  if (_devices.isEmpty) {
                    if (_selectedDevice != null) {
                      _selectedDevice = null;
                      Log.d('Devices empty on build. Set selected null.');
                      widget.onDeviceSelected.call(null);
                    }
                    return const Center(
                        child: Text(
                          'No devices connected\n\nPlease connect your device',
                          textAlign: TextAlign.center,
                        )
                    );
                  } else {
                    if (_selectedDevice == null) {
                      _selectedDevice = _devices.first;
                      Log.d('First device connected. Setting selected.');
                      widget.onDeviceSelected.call(_selectedDevice);
                    }
                    if (!_devices.contains(_selectedDevice)) {
                      Log.d('Selected device removed. Setting to first device');
                      _selectedDevice = _devices.first;
                      widget.onDeviceSelected.call(_selectedDevice);
                    }
                  }

                  return ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      final isSelected = device == _selectedDevice;
                      return GestureDetector(
                        onTap: () {
                          widget.onDeviceSelected.call(device);
                          setState(() {
                            Log.d('User selected device: $device');
                            _selectedDevice = device;
                          });
                        },
                        child: Container(
                          color: isSelected ?
                            theme.colorScheme.primary.withAlpha(32) :
                              Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0,
                              horizontal: 8.0
                          ),
                          child: DeviceListItem(
                            device: device,
                            showSerialNumber: widget.showSerialNumber,
                          )
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}