import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import 'dart:convert' show jsonDecode;

class AssetsIndex {
  static Set<String>? _keys;

  static Future<void> ensureLoaded() async {
    if (_keys != null) return;
    try {
      final manifestStr = await rootBundle.loadString('AssetManifest.json');

      // ✅ корректно парсим JSON манифеста: ключи = пути ассетов
      final decoded = jsonDecode(manifestStr);
      if (decoded is Map) {
        _keys = decoded.keys.whereType<String>().toSet();
      } else {
        _keys = <String>{};
      }

      if (kDebugMode) {
        debugPrint('[AssetsIndex] Загружено ${_keys!.length} ассетов');
        // Проверяем наличие фонов уровней
        final levelBgKeys = _keys!.where((k) => k.contains('bg/level')).toList();
        debugPrint('[AssetsIndex] Фоны уровней: $levelBgKeys');
        // Проверяем наличие изображений для уровней Японии
        final japanClassicKeys = _keys!.where((k) => k.contains('japan_classic_lvl')).toList();
        debugPrint('[AssetsIndex] Изображения Japan Classic уровней: $japanClassicKeys');
        // Выводим первые 20 ассетов для отладки
        if (_keys!.isNotEmpty) {
          final firstAssets = _keys!.take(20).toList();
          debugPrint('[AssetsIndex] Первые 20 ассетов: $firstAssets');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AssetsIndex] Ошибка загрузки манифеста: $e');
      }
      _keys = <String>{};
    }
  }

  static bool has(String path) {
    final bool exists = _keys?.contains(path) ?? false;
    if (kDebugMode && !exists) {
      debugPrint('[AssetsIndex] Ассет не найден: $path');
    }
    return exists;
  }

  static String? firstByPrefixes(List<String> prefixes, {String extension = '.png'}) {
    if (_keys == null) return null;
    for (final p in prefixes) {
      final candidate = '$p$extension';
      if (_keys!.contains(candidate)) return candidate;
    }
    return null;
  }

  static String? firstInDir(String dir, {String extension = '.png'}) {
    if (_keys == null) return null;
    for (final k in _keys!) {
      if (k.startsWith(dir) && k.endsWith(extension)) return k;
    }
    return null;
  }

  static int countByPrefix(String prefix, {String extension = '.png'}) {
    if (_keys == null) return 0;
    return _keys!.where((k) => k.startsWith(prefix) && k.endsWith(extension)).length;
  }

  /// Возвращает все файлы с заданным расширением внутри папки dir (без рекурсии)
  static List<String> listInDir(String dir, {String extension = '.png'}) {
    if (_keys == null) return const [];
    final norm = dir.endsWith('/') ? dir : '$dir/';
    return _keys!
        .where((k) => k.startsWith(norm) && k.endsWith(extension) && !k.substring(norm.length).contains('/'))
        .toList()
      ..sort((a, b) => _naturalCompare(a, b));
  }

  /// Естественная сортировка: учитывает числовые суффиксы в конце имени
  static int _naturalCompare(String a, String b) {
    final na = _numSuffix(a);
    final nb = _numSuffix(b);
    if (na != -1 && nb != -1 && na != nb) return na.compareTo(nb);
    return a.compareTo(b);
  }

  static int _numSuffix(String s) {
    final m = RegExp(r'(\d+)(?=\.[A-Za-z0-9]+$)').firstMatch(s);
    return m == null ? -1 : int.tryParse(m.group(1)!) ?? -1;
  }

  /// Находит файл награды для указанного уровня, исходя из реального содержимого папки
  /// Папка: assets/images/reward/{country}/{country}_{alias}_lvl/
  /// Приоритет подбора:
  /// 1) точное совпадение по суффиксу _{level}.png
  /// 2) если нет точного совпадения — берём файл с индексом level-1 после естественной сортировки
  static String? rewardForLevel({
    required String country,
    required String alias,
    required int level,
  }) {
    final path =
        'assets/images/reward/$country/${country}_${alias}_lvl/${country}_${alias}_$level.png';
    return has(path) ? path : null;
  }

  static int countRewardsForCountry(String country) {
    final keys = _keys;
    if (keys == null || keys.isEmpty) return 0;

    final prefix = 'assets/images/reward/$country/';
    var total = 0;
    for (final asset in keys) {
      if (asset.startsWith(prefix) && asset.toLowerCase().endsWith('.png')) {
        total++;
      }
    }
    return total;
  }
}