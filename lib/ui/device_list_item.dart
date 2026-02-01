
import 'package:android_sideloader/adb/adb_device.dart';
import 'package:flutter/material.dart';

class DeviceListItem extends StatelessWidget {
  final AdbDevice device;
  final bool showSerialNumber;

  const DeviceListItem({
    super.key,
    required this.device,
    this.showSerialNumber = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          Icons.phone_android,
          color: theme.colorScheme.onSurface,
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                device.model,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: theme.textTheme.bodyMedium?.fontSize,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (showSerialNumber)
                Text(
                  device.id,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withAlpha(200),
                    fontSize: theme.textTheme.bodySmall?.fontSize,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
