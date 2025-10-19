import 'package:flutter/material.dart';
import 'package:quiz_new_app/l10n/app_localizations.dart';

enum Rank { bronze, silver, gold, legend }

class RankUtils {
  static Rank byTotalStars(int totalStars) {
    if (totalStars >= 120) return Rank.legend;
    if (totalStars >= 60) return Rank.gold;
    if (totalStars >= 20) return Rank.silver;
    return Rank.bronze;
  }

  static List<Color> gradientFor(Rank r) {
    switch (r) {
      case Rank.bronze:
        return const [Color(0xFFCD7F32), Color(0xFFE6A66A)];
      case Rank.silver:
        return const [Color(0xFFB0B0B0), Color(0xFFE1E1E1)];
      case Rank.gold:
        return const [Color(0xFFFFC107), Color(0xFFFFE082)];
      case Rank.legend:
        return const [Color(0xFF7C4DFF), Color(0xFFE3D7FF)];
    }
  }

  static String label(Rank r, BuildContext context) {
    final l = AppLocalizations.of(context);
    switch (r) {
      case Rank.bronze:
        return l.rank_bronze;
      case Rank.silver:
        return l.rank_silver;
      case Rank.gold:
        return l.rank_gold;
      case Rank.legend:
        return l.rank_legend;
    }
  }

  // Backward-compatible helper without context (fallback to English).
  static String labelFallback(Rank r, {String languageCode = 'en'}) {
    switch (r) {
      case Rank.bronze:
        return languageCode == 'ru' ? 'Бронза' : 'Bronze';
      case Rank.silver:
        return languageCode == 'ru' ? 'Серебро' : 'Silver';
      case Rank.gold:
        return languageCode == 'ru' ? 'Золото' : 'Gold';
      case Rank.legend:
        return languageCode == 'ru' ? 'Легенда' : 'Legend';
    }
  }
}
