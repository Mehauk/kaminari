import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  // Private constructor
  LocalStorageService._();

  static final LocalStorageService instance = LocalStorageService._();

  SharedPreferences? _preferences;

  // Initialize this in your main.dart
  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  // Generic setter
  Future<bool> saveData(String key, dynamic value) async {
    if (value is String) return await _preferences!.setString(key, value);
    if (value is int) return await _preferences!.setInt(key, value);
    if (value is bool) return await _preferences!.setBool(key, value);
    if (value is double) return await _preferences!.setDouble(key, value);
    if (value is List<String>) {
      return await _preferences!.setStringList(key, value);
    }
    return false;
  }

  // Generic getter
  dynamic getData(String key) {
    return _preferences?.get(key);
  }

  // Remove specific item
  Future<bool> removeData(String key) async {
    return await _preferences!.remove(key);
  }

  // Clear all storage
  Future<bool> clearAll() async {
    return await _preferences!.clear();
  }
}
