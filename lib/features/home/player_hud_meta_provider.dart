import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/current_user.dart';
import '../profile/profile_providers.dart'; // CHANGED: без package-импорта
import 'player_hud_meta.dart';

String _rankLabelByStars(int totalStars) {
  // Простой fallback без зависимостей от RankUtils, чтобы сборка не падала.
  if (totalStars >= 200) return 'Мастер';
  if (totalStars >= 100) return 'Золото I';
  if (totalStars >= 50) return 'Серебро I';
  return 'Бронза I';
}

int _levelByStars(int totalStars) {
  // Пример: 10 звёзд = +1 уровень, минимум 1.
  return 1 + (totalStars ~/ 10);
}

final playerHudMetaProvider = Provider<PlayerHudMeta>((ref) {
  final uid = ref.watch(currentUserProvider);
  final profileAsync = ref.watch(profileProvider); // AsyncValue<LocalProfile>

  return profileAsync.when(
    data: (p) {
      final name = p.name.trim().isNotEmpty ? p.name.trim() : uid;
      final totalStars = p.totalStars;

      return PlayerHudMeta(
        name: name,
        level: _levelByStars(totalStars),
        rankLabel: _rankLabelByStars(totalStars),
        avatarPath: p.avatarPath, // локальный путь (или пусто)
        avatarAsset: PlayerHudMeta.empty.avatarAsset, // placeholder
      );
    },
    loading: () => PlayerHudMeta(
      name: uid,
      level: 1,
      rankLabel: 'Бронза I',
      avatarAsset: PlayerHudMeta.empty.avatarAsset,
    ),
    error: (_, __) => PlayerHudMeta(
      name: uid,
      level: 1,
      rankLabel: 'Бронза I',
      avatarAsset: PlayerHudMeta.empty.avatarAsset,
    ),
  );
});
