import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/current_user.dart';
import 'progress_store.dart';

/// Provider монет текущего пользователя с авто-обновлением через refresh вызов.
final coinsProvider = FutureProvider<int>((ref) async {
  final userId = ref.watch(currentUserProvider);
  return ProgressStore.getCoins(userId);
});

/// Provider batch прогресса уровней для указанного packKey.
final levelsProgressProvider = FutureProvider.family<(
  List<int>, // stars
  List<bool>, // unlocked
), (String packKey, int levelsCount)>((ref, tuple) async {
  final (packKey, levelsCount) = tuple;
  final userId = ref.watch(currentUserProvider);
  return ProgressStore.getLevelsProgress(userId, packKey, levelsCount);
});
