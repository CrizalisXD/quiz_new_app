import 'package:flutter/material.dart';

class CountryProgressChip extends StatelessWidget {
  final String countryKey;
  final int levelsPassed;
  final int stars;
  final VoidCallback? onTap;
  const CountryProgressChip({super.key, required this.countryKey, required this.levelsPassed, required this.stars, this.onTap});

  String _emojiFor(String k) {
    switch (k) {
      case 'japan':
        return '🇯🇵';
      case 'france':
        return '🇫🇷';
      case 'brazil':
        return '🇧🇷';
      case 'norway':
        return '🇳🇴';
      case 'egypt':
        return '🇪🇬';
      default:
        return '🌍';
    }
  }

  @override
  Widget build(BuildContext context) {
    // На данном этапе процент рассчитываем условно: 10 уровней максимум
    final maxLevels = 10;
    final pct = (levelsPassed.clamp(0, maxLevels)) / maxLevels;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(_emojiFor(countryKey), style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _countryTitle(countryKey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: Colors.black12,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 6),
            Text('${(pct * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  String _countryTitle(String k) {
    switch (k) {
      case 'japan':
        return 'Япония';
      case 'france':
        return 'Франция';
      case 'brazil':
        return 'Бразилия';
      case 'norway':
        return 'Норвегия';
      case 'egypt':
        return 'Египет';
      default:
        return 'Страна';
    }
  }
}
