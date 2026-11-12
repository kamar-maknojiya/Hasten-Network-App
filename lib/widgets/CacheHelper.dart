import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheHelper {
  /// Save data
  static Future<void> save(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(data));
  }

  /// Read data
  static Future<dynamic> read(String key) async {
    final prefs = await SharedPreferences.getInstance();

    final cache = prefs.getString(key);

    if (cache == null) return null;

    return jsonDecode(cache);
  }

  /// Remove cache
  static Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  /// Clear all cache
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}