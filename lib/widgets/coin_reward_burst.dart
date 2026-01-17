import 'dart:math';
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';

// ✅ используем существующую монету из вашего проекта
const String _coinAsset = 'assets/images/ui/currency/gold.png';

class CoinRewardBurst extends StatefulWidget {
  final VoidCallback? onDone;
  final bool dimBackground;
  final int coinCount;
  final Duration duration;

  const CoinRewardBurst({
    super.key,
    this.onDone,
    this.dimBackground = true,
    this.coinCount = 10,
    this.duration = const Duration(milliseconds: 850),
  });

  @override
  State<CoinRewardBurst> createState() => _CoinRewardBurstState();
}

class _CoinRewardBurstState extends State<CoinRewardBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_CoinParticle> _coins;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration)
      ..forward()
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onDone?.call();
      });

    _coins = List.generate(widget.coinCount, (i) => _CoinParticle.seeded(i));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final center = Offset(size.width / 2, size.height * 0.45);

    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final v = _c.value;

        double overlayA = 0.0;
        if (widget.dimBackground) {
          if (v < 0.10) {
            overlayA = (v / 0.10) * 0.35;
          } else if (v > 0.70) {
            overlayA = (1 - (v - 0.70) / 0.15) * 0.35;
          } else {
            overlayA = 0.35;
          }
          overlayA = overlayA.clamp(0.0, 0.35);
        }

        final centerScale = _popScale(v);
        final centerSize = min(size.width, size.height) * 0.18;

        return Stack(
          children: [
            // 1) Overlay
            if (widget.dimBackground)
              IgnorePointer(
                child: Opacity(
                  opacity: overlayA,
                  child: Container(color: Colors.black),
                ),
              ),

            // 2) Rays (CustomPaint)
            IgnorePointer(
              child: CustomPaint(
                size: Size.infinite,
                painter: _RaysPainter(
                  center: center,
                  progress: v,
                ),
              ),
            ),

            // 3) Coins
            ..._coins.map((p) {
              final s = p.sample(center, size, v);
              return Positioned(
                left: s.pos.dx - s.size / 2,
                top: s.pos.dy - s.size / 2,
                child: Opacity(
                  opacity: s.opacity,
                  child: Transform.rotate(
                    angle: s.rotation,
                    child: Transform.scale(
                      scale: s.scale,
                      child: Image.asset(
                        _coinAsset,
                        width: s.size,
                        height: s.size,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                ),
              );
            }),

            // 4) Center coin (no text)
            Positioned(
              left: center.dx - centerSize / 2,
              top: center.dy - centerSize / 2,
              child: Transform.scale(
                scale: centerScale,
                child: Image.asset(
                  _coinAsset,
                  width: centerSize,
                  height: centerSize,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  double _popScale(double v) {
    // 0..0.18 grow, 0.18..0.35 settle, then 1.0
    if (v < 0.18) {
      final t = Curves.easeOutBack.transform(v / 0.18);
      return lerpDouble(0.85, 1.12, t)!;
    }
    if (v < 0.35) {
      final t = Curves.easeInOut.transform((v - 0.18) / 0.17);
      return lerpDouble(1.12, 1.00, t)!;
    }
    return 1.0;
  }
}

// ---------------------- Rays Painter ----------------------

class _RaysPainter extends CustomPainter {
  final Offset center;
  final double progress;

  _RaysPainter({required this.center, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Rays visible mostly between 0.05..0.85
    final appear = _range(progress, 0.05, 0.35, curve: Curves.easeOutCubic);
    final fadeOut = 1.0 - _range(progress, 0.55, 0.85, curve: Curves.easeInCubic);
    final a = (0.38 * appear * fadeOut).clamp(0.0, 0.38);
    if (a <= 0.001) return;

    final rayCount = 14;
    final maxLen = min(size.width, size.height) * 0.55 * appear;
    final baseWidth = lerpDouble(14, 6, progress.clamp(0.0, 1.0))!;
    final rotation = lerpDouble(0.0, 0.10, progress)!; // ~5.7°

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    for (int i = 0; i < rayCount; i++) {
      final ang = (2 * pi / rayCount) * i;

      canvas.save();
      canvas.rotate(ang);

      // triangular ray
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(maxLen, -baseWidth / 2)
        ..lineTo(maxLen, baseWidth / 2)
        ..close();

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFD36B).withValues(alpha: a),
            const Color(0x00FFD36B),
          ],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: maxLen))
        ..blendMode = BlendMode.screen;

      canvas.drawPath(path, paint);
      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RaysPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.center != center;

  double _range(double v, double a, double b, {Curve curve = Curves.linear}) {
    if (v <= a) return 0;
    if (v >= b) return 1;
    return curve.transform((v - a) / (b - a));
  }
}

// ---------------------- Coin Particles ----------------------

class _CoinParticle {
  final double angle;     // direction around arc
  final double radiusK;   // how far from center
  final double sizeK;     // coin size factor
  final double rot;       // base rotation
  final double delay;     // per-coin delay
  final double lift;      // upward lift
  final double side;      // side spread

  _CoinParticle({
    required this.angle,
    required this.radiusK,
    required this.sizeK,
    required this.rot,
    required this.delay,
    required this.lift,
    required this.side,
  });

  factory _CoinParticle.seeded(int seed) {
    final r = Random(seed * 9973);
    // angles biased to upper-left / upper-right like in ref
    final side = r.nextBool() ? 1.0 : -1.0;
    final ang = (pi / 2) + side * (0.35 + r.nextDouble() * 0.55); // ~upper sides
    return _CoinParticle(
      angle: ang,
      radiusK: 0.75 + r.nextDouble() * 0.25,
      sizeK: 0.05 + r.nextDouble() * 0.07,
      rot: (r.nextDouble() * 0.7 - 0.35), // ~ -20..+20 deg
      delay: r.nextDouble() * 0.10,
      lift: 0.18 + r.nextDouble() * 0.12,
      side: 0.35 + r.nextDouble() * 0.25,
    );
  }

  _CoinState sample(Offset center, Size screen, double tRaw) {
    // time with per-coin delay
    final t = ((tRaw - delay) / (1.0 - delay)).clamp(0.0, 1.0);

    // flight segment 0.10..0.60
    final fly = _range(t, 0.10, 0.60, curve: Curves.easeOutCubic);

    // fade in 0.10..0.18, fade out 0.60..0.85
    final fadeIn = _range(t, 0.10, 0.18, curve: Curves.easeOut);
    final fadeOut = 1.0 - _range(t, 0.60, 0.85, curve: Curves.easeIn);
    final opacity = (fadeIn * fadeOut).clamp(0.0, 1.0);

    // Size relative to screen width
    final size = screen.width * sizeK;

    // Start near center, end on ellipse arc
    final rx = screen.width * 0.45 * radiusK;
    final ry = screen.height * (lift) * radiusK;

    final end = Offset(
      center.dx + cos(angle) * rx * sideSign(angle),
      center.dy - sin(angle) * ry,
    );

    // Quadratic bezier control point (push upward a bit)
    final mid = Offset(
      (center.dx + end.dx) / 2,
      min(center.dy, end.dy) - screen.height * 0.08,
    );

    final pos = _quadBezier(center, mid, end, fly);

    // scale "breathing" in flight
    final s = 0.92 + 0.12 * sin(fly * pi);
    final scale = s;

    // slight rotation change
    final rotation = rot + (fly * 0.2 - 0.1);

    return _CoinState(
      pos: pos,
      size: size,
      opacity: opacity,
      scale: scale,
      rotation: rotation,
    );
  }

  double sideSign(double a) => cos(a) >= 0 ? 1.0 : -1.0;

  Offset _quadBezier(Offset p0, Offset p1, Offset p2, double t) {
    final u = 1 - t;
    final x = u * u * p0.dx + 2 * u * t * p1.dx + t * t * p2.dx;
    final y = u * u * p0.dy + 2 * u * t * p1.dy + t * t * p2.dy;
    return Offset(x, y);
  }

  double _range(double v, double a, double b, {Curve curve = Curves.linear}) {
    if (v <= a) return 0;
    if (v >= b) return 1;
    return curve.transform((v - a) / (b - a));
  }
}

class _CoinState {
  final Offset pos;
  final double size;
  final double opacity;
  final double scale;
  final double rotation;

  _CoinState({
    required this.pos,
    required this.size,
    required this.opacity,
    required this.scale,
    required this.rotation,
  });
}
