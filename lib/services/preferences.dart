import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  static const _keyShowSerialNumber = 'show_serial_number';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static bool get showSerialNumber {
    return _prefs?.getBool(_keyShowSerialNumber) ?? true;
  }

  static Future<void> setShowSerialNumber(bool value) async {
    await _prefs?.setBool(_keyShowSerialNumber, value);
  }
}
