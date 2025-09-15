import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Persistence {
  static const _key = 'wordle_state';

  static Future<void> saveState(Map<String, dynamic> state) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_key, jsonEncode(state));
  }


  static Future<Map<String, dynamic>?> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_key);
    if (s == null) return null;
    try {
      return jsonDecode(s) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> hasSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_key);
  }


  static Future<void> clearState() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(_key);
  }
}
