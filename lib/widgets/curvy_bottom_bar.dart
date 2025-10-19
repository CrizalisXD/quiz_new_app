import 'package:flutter/material.dart';

class CurvyBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<IconData> icons; // 3–5 icons
  final int notchIndex; // index of the concave notch cell
  final double height;
  final Color color;
  final Color activeColor;
  final Color inactiveColor;
  final IconData? notchOverrideIcon; // if provided replaces icons[notchIndex] inside circle

  const CurvyBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.icons,
    this.notchIndex = 1,
    this.height = 72,
    this.color = Colors.black,
    this.activeColor = Colors.white,
    this.inactiveColor = const Color(0xCCFFFFFF),
    this.notchOverrideIcon,
  }) : assert(notchIndex >= 0);

  @override
  Widget build(BuildContext context) {
    final r = 18.0; // border radius corners
    return SafeArea(
      top: false,
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final cellW = w / icons.length;
            final notchCenterX = cellW * (notchIndex + 0.5);

            return Stack(
              alignment: Alignment.bottomCenter,
              children: [
                ClipPath(
                  clipper: _WavyClipper(
                    notchCenterX: notchCenterX,
                    notchRadius: 22,
                    cornerRadius: r,
                  ),
                  child: Container(
                    width: w,
                    height: height,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                  ),
                ),
                // Row of icons
                Row(
                  children: List.generate(icons.length, (i) {
                    final isSel = i == currentIndex;
                    final isNotch = i == notchIndex;
                    final topLift = isNotch ? 6.0 : 0.0;
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onTap(i),
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 10, top: topLift),
                          child: Center(
                            child: Icon(
                              icons[i],
                              color: isSel ? activeColor : inactiveColor.withOpacity(0.75),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                // Circle in notch
                Positioned(
                  left: notchCenterX - 22,
                  bottom: height - 42,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.30),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      notchOverrideIcon ?? icons[notchIndex],
                      color: activeColor,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WavyClipper extends CustomClipper<Path> {
  final double notchCenterX;
  final double notchRadius;
  final double cornerRadius;

  _WavyClipper({
    required this.notchCenterX,
    required this.notchRadius,
    required this.cornerRadius,
  });

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final r = cornerRadius;
    final nr = notchRadius;

    final startX = (notchCenterX - nr * 1.6).clamp(r, w - r);
    final endX = (notchCenterX + nr * 1.6).clamp(r, w - r);

    final p = Path()
      ..moveTo(r, 0)
      ..quadraticBezierTo(0, 0, 0, r)
      ..lineTo(0, h - r)
      ..quadraticBezierTo(0, h, r, h)
      ..lineTo(w - r, h)
      ..quadraticBezierTo(w, h, w, h - r)
      ..lineTo(w, r)
      ..quadraticBezierTo(w, 0, w - r, 0)
      ..lineTo(endX, 0)
      ..cubicTo(
        notchCenterX + nr * 0.9,
        0,
        notchCenterX + nr * 0.9,
        -nr * 0.8,
        notchCenterX,
        -nr * 0.8,
      )
      ..cubicTo(
        notchCenterX - nr * 0.9,
        -nr * 0.8,
        notchCenterX - nr * 0.9,
        0,
        startX,
        0,
      )
      ..lineTo(r, 0)
      ..close();

    return p;
  }

  @override
  bool shouldReclip(covariant _WavyClipper old) =>
      notchCenterX != old.notchCenterX ||
      notchRadius != old.notchRadius ||
      cornerRadius != old.cornerRadius;
}
