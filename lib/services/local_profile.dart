import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quiz_new_app/models/profile.dart';

class LocalProfileStore {
  static const _kProfile = 'profile.v1';
  static const _kProgressPrefix = 'progress.v1'; // progress.v1:<profileId>:<pack>:<level>

  Future<Profile?> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kProfile);
    if (raw == null) return null;
    return Profile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(Profile p) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kProfile, jsonEncode(p.toJson()));
  }

  Future<void> signOut() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kProfile);
  }

  // Простое «вход по почте» (без сервера) — храним как локальный профиль
  Future<Profile> signInEmail(String email) async {
    final p = Profile(
      id: email.toLowerCase().trim(),
      email: email.trim(),
      displayName: email.split('@').first,
      isGuest: false,
      createdAt: DateTime.now(),
    );
    await save(p);
    return p;
  }

  // «Гость»
  Future<Profile> continueAsGuest() async {
    final p = Profile(
      id: 'guest',
      email: null,
      displayName: 'Гость',
      isGuest: true,
      createdAt: DateTime.now(),
    );
    await save(p);
    return p;
  }

  /// Прогресс: звезды/лучшее время на уровень под конкретного пользователя.
  Future<void> saveLevelResult({
    required Profile profile,
    required String packKey, // например "japan|classic"
    required int level,
    required int stars,      // 0..3
    required int timeSec,    // лучшее время, сек
  }) async {
    final sp = await SharedPreferences.getInstance();
    final key = '$_kProgressPrefix:${profile.id}:$packKey:$level';
    final prev = sp.getString(key);
    int prevStars = 0;
    int prevBest = 1 << 30;
    if (prev != null) {
      final m = jsonDecode(prev) as Map<String, dynamic>;
      prevStars = (m['stars'] as int?) ?? 0;
      prevBest = (m['bestTime'] as int?) ?? prevBest;
    }
    final data = {
      'stars': stars > prevStars ? stars : prevStars,
      'bestTime': timeSec < prevBest ? timeSec : prevBest,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await sp.setString(key, jsonEncode(data));
  }
}
