import 'package:flutter/services.dart' show rootBundle;

/// Глобальный индекс ассетов из AssetManifest.json
class AssetsIndex {
  static Set<String>? _keys;

  static Future<void> ensureLoaded() async {
    if (_keys != null) return;
    try {
      final manifest = await rootBundle.loadString('AssetManifest.json');
      _keys = manifest
          .split('"')
          .where((s) => s.startsWith('assets/'))
          .toSet();
    } catch (_) {
      _keys = <String>{};
    }
  }

  static bool has(String path) => _keys?.contains(path) ?? false;

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
  static String? rewardForLevel({required String country, required String alias, required int level}) {
    if (_keys == null) return null;
    final dir = 'assets/images/reward/$country/${country}_${alias}_lvl/';
    final files = listInDir(dir);
    if (files.isEmpty) return null;
    final exact = files.firstWhere(
      (p) => p.endsWith('_$level.png'),
      orElse: () => '',
    );
    if (exact.isNotEmpty) return exact;
    if (level - 1 < files.length) return files[level - 1];
    return null;
  }
}