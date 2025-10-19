import 'package:shared_preferences/shared_preferences.dart';

/// Простой локальный стор для хранения количества кристаллов (gems).
/// На сервер/реальный биллинг не завязано.
class CurrencyStore {
  static String _key(String userId) => 'gems_$userId';

  static Future<int> getGems(String userId) async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_key(userId)) ?? 0;
  }

  static Future<void> setGems(String userId, int value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_key(userId), value);
  }

  static Future<int> addGems(String userId, int delta) async {
    final sp = await SharedPreferences.getInstance();
    final cur = sp.getInt(_key(userId)) ?? 0;
    final next = cur + delta;
    await sp.setInt(_key(userId), next < 0 ? 0 : next);
    return sp.getInt(_key(userId)) ?? 0;
  }
}
