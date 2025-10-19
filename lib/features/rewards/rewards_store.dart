import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RewardsStore {
  static String _key(String userId) => 'u:$userId|rewards';

  static Future<List<String>> getRewards(String userId) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key(userId));
    if (raw == null || raw.isEmpty) return <String>[];
    try {
        return (jsonDecode(raw) as List).map((e) => e.toString()).toList();
    } catch (_) {
      return <String>[];
    }
  }

  static Future<bool> hasReward(String userId, String assetPath) async {
    final list = await getRewards(userId);
    return list.contains(assetPath);
  }

  static Future<void> addReward(String userId, String assetPath) async {
    final sp = await SharedPreferences.getInstance();
    final list = await getRewards(userId);
      if (list.contains(assetPath)) return;
      list.add(assetPath);
    await sp.setString(_key(userId), jsonEncode(list));
  }

  /// Удаляет все награды пользователя
  static Future<void> clear(String userId) async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_key(userId));
  }

  // --- helpers ---
  // Миграционные и нормализующие хелперы удалены — поддерживаем только новую схему путей.
}