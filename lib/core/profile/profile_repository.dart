import 'package:shared_preferences/shared_preferences.dart';
import 'local_profile.dart';

class ProfileRepository {
  static const _key = 'local_profile_v1';

  Future<LocalProfile> loadOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      final p = LocalProfile.emptyGuest();
      await prefs.setString(_key, p.toJson());
      return p;
    }
    return LocalProfile.fromJson(raw);
  }

  Future<void> save(LocalProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, profile.toJson());
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    final p = LocalProfile.emptyGuest();
    await prefs.setString(_key, p.toJson());
  }
}
