import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class GameBackground extends StatelessWidget {
  final String asset;                // путь к файлу
  final Widget child;                // контент поверх фона
  final Color? overlayColor;         // полупрозрачная заливка
  final BlendMode overlayBlendMode;  // режим наложения заливки
  final BoxFit fit;                  // как растягивать фон
  final Gradient fallbackGradient;   // градиент, если ассет не найден

  const GameBackground({
    super.key,
    required this.asset,
    required this.child,
    this.overlayColor,
    this.overlayBlendMode = BlendMode.srcOver,
    this.fit = BoxFit.cover,
    this.fallbackGradient = const LinearGradient(
      colors: [Color.fromARGB(255, 255, 251, 251), Color(0xFF2A2A2A)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          asset,
          fit: fit,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) {
            if (kDebugMode) {
              debugPrint('[GameBackground] "$asset" не найден -> градиент');
            }
            return DecoratedBox(decoration: BoxDecoration(gradient: fallbackGradient));
          },
        ),
        if (overlayColor != null)
          ColoredBox(color: overlayColor!), // цвет берём как есть (укажи нужную opacity при передаче)
        child,
      ],
    );
  }
}
