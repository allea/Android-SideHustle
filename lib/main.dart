import 'package:android_sideloader/logs/log.dart';
import 'package:android_sideloader/services/preferences.dart';
import 'package:android_sideloader/ui/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:window_manager/window_manager.dart';

void main() async => await Log.init(level: Level.all, () async {
  Log.i("Logging initialized. Starting app...");
  await Preferences.init();
  await windowManager.ensureInitialized();

  windowManager.waitUntilReadyToShow(
    const WindowOptions(
      title: "App Sideloader",
      size: Size(800, 600),
      maximumSize: Size(1200, 900),
      minimumSize: Size(800, 600),
    ),
    () async {
      await windowManager.show();
      await windowManager.focus();
    },
  );

  runApp(const SideloaderApp());
});

class SideloaderApp extends StatelessWidget {
  const SideloaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Sideloader',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.dark,
      home: const HomeScreen(),
    );
  }
}
