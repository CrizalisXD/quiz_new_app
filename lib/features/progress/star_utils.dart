/// Утилиты для конвертации результата (процент / сырые числа) в звёзды.
class StarUtils {
  /// Конвертация процента правильных ответов в 0..3 звезды.
  static int fromPercent(double percent) {
    if (percent >= 90) return 3;
    if (percent >= 70) return 2;
    if (percent >= 50) return 1;
    return 0;
  }

  /// Конвертация из (score, answered) напрямую.
  static int fromScore(int score, int answered) {
    if (answered <= 0) return 0;
    final p = (score / answered) * 100.0;
    return fromPercent(p);
  }
}
