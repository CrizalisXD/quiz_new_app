import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint; // CHANGED
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/current_user.dart';
import 'local_profile.dart';

const _kProfileKeyPrefix = 'profile_v1_';
const _kAvatarDir = 'assets/images/profile/avatar';
const _kDefaultAvatarAsset = '$_kAvatarDir/avatar_classic_girl.png';

String _normalizeAvatarPath(String raw) {
  // CHANGED: нормализуем пути из prefs (в т.ч. Windows-style '\')
  final v = raw.replaceAll('\\', '/').trim(); // CHANGED
  if (v.isEmpty) return _kDefaultAvatarAsset;

  // ADD: legacy дефолт, который у тебя сейчас отсутствует в assets
  if (v == 'assets/images/profile/default.png') return _kDefaultAvatarAsset;

  if (v.startsWith('assets/')) return v;
  if (!v.contains('/')) return '$_kAvatarDir/$v';
  return v;
}

final profileProvider =
    AsyncNotifierProvider<ProfileController, LocalProfile>(ProfileController.new);

/// Принудительно пересобрать профиль (когда профиль меняют НЕ через ProfileController.save/update*()).
void invalidateProfile(WidgetRef ref) => ref.invalidate(profileProvider);

class ProfileController extends AsyncNotifier<LocalProfile> {
  static const int _maxStars = 1 << 30; // CHANGED

  Future<LocalProfile> _loadFor(SharedPreferences prefs, String key, String userId) async {
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      final p = _defaultProfile(userId);
      await _save(prefs, key, p);
      return p;
    }

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final p = LocalProfile.fromJson(map);
      return p.copyWith(avatarPath: _normalizeAvatarPath(p.avatarPath));
    } catch (_) {
      final p = _defaultProfile(userId);
      await _save(prefs, key, p);
      return p;
    }
  }

  @override
  Future<LocalProfile> build() async {
    final userId = ref.watch(currentUserProvider);
    final prefs = await SharedPreferences.getInstance();
    final key = '$_kProfileKeyPrefix$userId';
    return _loadFor(prefs, key, userId);
  }

  Future<void> save(LocalProfile profile) async {
    final userId = ref.read(currentUserProvider);
    final prefs = await SharedPreferences.getInstance();
    final key = '$_kProfileKeyPrefix$userId';

    final normalized = profile.copyWith(
      avatarPath: _normalizeAvatarPath(profile.avatarPath),
      name: profile.name.trim().isEmpty ? profile.name : profile.name.trim(),
    );

    if (kDebugMode) {
      debugPrint('[Profile] save user=$userId name="${normalized.name}" avatar="${normalized.avatarPath}" key=$key'); // CHANGED
    }

    await _save(prefs, key, normalized);
    state = AsyncData(normalized);
  }

  Future<void> reset() async {
    final userId = ref.read(currentUserProvider);
    final prefs = await SharedPreferences.getInstance();
    final key = '$_kProfileKeyPrefix$userId';
    final p = _defaultProfile(userId);
    await _save(prefs, key, p);
    state = AsyncData(p);
  }

  Future<void> updateName(String name) async {
    final p = await future;
    final normalized = name.trim();
    await save(p.copyWith(name: normalized.isEmpty ? p.name : normalized));
  }

  Future<void> updateAvatar(String avatarPath) async {
    final p = await future;
    await save(p.copyWith(avatarPath: avatarPath));
  }

  Future<void> addStars(int delta) async {
    final p = await future;
    final next = (p.totalStars + delta).clamp(0, _maxStars).toInt(); // CHANGED
    await save(p.copyWith(totalStars: next));
  }

  /// Compat: старое API для экранов, которые ещё вызывают rename().
  Future<void> rename(String name) => updateName(name);

  /// Compat: старое API для экранов, которые ещё вызывают changeAvatar().
  Future<void> changeAvatar(String avatarPath) => updateAvatar(avatarPath); // CHANGED

  static Future<void> _save(SharedPreferences prefs, String key, LocalProfile p) async {
    await prefs.setString(key, jsonEncode(p.toJson()));
  }

  static LocalProfile _defaultProfile(String userId) {
    return LocalProfile(
      id: userId,
      name: userId,
      avatarPath: _kDefaultAvatarAsset,
      totalStars: 0,
    );
  }
}
