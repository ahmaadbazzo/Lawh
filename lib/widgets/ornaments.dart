import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';

const List<String> _arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

/// Converts western digits in [value] to Arabic-Indic digits (١٢٣).
String toArabicDigits(Object value) {
  final buffer = StringBuffer();
  for (final ch in value.toString().split('')) {
    final d = int.tryParse(ch);
    buffer.write(d == null ? ch : _arabicDigits[d]);
  }
  return buffer.toString();
}

/// Eight-pointed star (octagram / Rub el Hizb), the classic Mushaf motif.
Path octagramPath(Offset center, double radius, {double innerRatio = 0.765}) {
  final path = Path();
  for (var i = 0; i < 16; i++) {
    final r = i.isEven ? radius : radius * innerRatio;
    final angle = -math.pi / 2 + i * math.pi / 8;
    final x = center.dx + r * math.cos(angle);
    final y = center.dy + r * math.sin(angle);
    if (i == 0) {
      path.moveTo(x, y);
    } else {
      path.lineTo(x, y);
    }
  }
  path.close();
  return path;
}

/// Repeating geometric star lattice, used as a faint watermark.
class StarPatternPainter extends CustomPainter {
  const StarPatternPainter({
    required this.color,
    this.cell = 44,
    this.strokeWidth = 0.8,
  });

  final Color color;
  final double cell;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final dot = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final r = cell * 0.40;
    for (double y = cell / 2; y < size.height + cell; y += cell) {
      for (double x = cell / 2; x < size.width + cell; x += cell) {
        canvas.drawPath(octagramPath(Offset(x, y), r), stroke);
        canvas.drawCircle(Offset(x + cell / 2, y + cell / 2), cell * 0.06, dot);
      }
    }
  }

  @override
  bool shouldRepaint(StarPatternPainter old) =>
      old.color != color || old.cell != cell || old.strokeWidth != strokeWidth;
}

/// Parchment page background with a very faint star lattice.
class MushafBackground extends StatelessWidget {
  const MushafBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? const [AppColors.bgDark, Color(0xFF0A2A21)]
                    : const [Color(0xFFFBF5E6), AppColors.bgLight],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: StarPatternPainter(
                color: (isDark ? AppColors.accentGold : AppColors.primaryGreen)
                    .withOpacity(isDark ? 0.06 : 0.05),
                cell: 56,
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Double gold/green border with star-shaped corner ornaments.
class OrnateFrame extends StatelessWidget {
  const OrnateFrame({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.fill,
    this.gradient,
    this.outerColor,
    this.innerColor,
    this.patternColor,
    this.radius = 18,
    this.corners = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? fill;
  final Gradient? gradient;
  final Color? outerColor;
  final Color? innerColor;
  final Color? patternColor;
  final double radius;
  final bool corners;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(
      painter: _FramePainter(
        fill: fill ?? (isDark ? AppColors.cardDark : AppColors.cardLight),
        gradient: gradient,
        outer: outerColor ?? AppColors.accentGold,
        inner: innerColor ??
            (isDark
                ? AppColors.accentGold.withOpacity(0.45)
                : AppColors.primaryGreen.withOpacity(0.45)),
        pattern: patternColor ??
            (isDark
                ? AppColors.accentGold.withOpacity(0.07)
                : AppColors.primaryGreen.withOpacity(0.06)),
        radius: radius,
        corners: corners,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _FramePainter extends CustomPainter {
  const _FramePainter({
    required this.fill,
    required this.gradient,
    required this.outer,
    required this.inner,
    required this.pattern,
    required this.radius,
    required this.corners,
  });

  final Color fill;
  final Gradient? gradient;
  final Color outer;
  final Color inner;
  final Color pattern;
  final double radius;
  final bool corners;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final outerRRect =
        RRect.fromRectAndRadius(rect.deflate(1), Radius.circular(radius));

    final bg = Paint()..style = PaintingStyle.fill;
    if (gradient != null) {
      bg.shader = gradient!.createShader(rect);
    } else {
      bg.color = fill;
    }
    canvas.drawRRect(outerRRect, bg);

    canvas.save();
    canvas.clipRRect(outerRRect);
    StarPatternPainter(color: pattern, cell: 34).paint(canvas, size);
    canvas.restore();

    canvas.drawRRect(
      outerRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = outer,
    );

    final innerRect = rect.deflate(7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, Radius.circular(math.max(radius - 5, 2))),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..color = inner,
    );

    if (corners) {
      final starPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = outer;
      final points = <Offset>[
        innerRect.topLeft,
        innerRect.topRight,
        innerRect.bottomLeft,
        innerRect.bottomRight,
      ];
      for (final p in points) {
        canvas.drawPath(octagramPath(p, 6.5), starPaint);
        canvas.drawCircle(p, 1.8, Paint()..color = fill);
      }
    }
  }

  @override
  bool shouldRepaint(_FramePainter old) =>
      old.fill != fill ||
      old.gradient != gradient ||
      old.outer != outer ||
      old.inner != inner ||
      old.pattern != pattern ||
      old.radius != radius ||
      old.corners != corners;
}

/// Surah title cartouche: emerald band with star medallions at both ends.
class SurahBanner extends StatelessWidget {
  const SurahBanner({
    super.key,
    required this.title,
    this.subtitle,
    this.height = 76,
  });

  final String title;
  final String? subtitle;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(
      painter: _BannerPainter(isDark: isDark),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: height * 0.95),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTheme.quranFontFamily,
                    fontSize: 26,
                    height: 1.3,
                    color: AppColors.softGold,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.softGold.withOpacity(0.85),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerPainter extends CustomPainter {
  const _BannerPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final r = h / 2;

    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(r, h * 0.14, size.width - 2 * r, h * 0.72),
      Radius.circular(h * 0.12),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            AppColors.primaryGreenDark,
            AppColors.primaryGreen,
            AppColors.primaryGreenDark,
          ],
        ).createShader(body.outerRect),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = AppColors.accentGold,
    );
    canvas.drawRRect(
      body.deflate(4),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = AppColors.accentGold.withOpacity(0.55),
    );

    final medalFill = isDark ? AppColors.cardDark : AppColors.cardLight;
    for (final cx in <double>[r, size.width - r]) {
      final c = Offset(cx, r);
      canvas.drawCircle(c, r - 1, Paint()..color = medalFill);
      canvas.drawCircle(
        c,
        r - 1,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = AppColors.accentGold,
      );
      canvas.drawCircle(
        c,
        r - 6,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = AppColors.accentGold.withOpacity(0.6),
      );
      canvas.drawPath(
        octagramPath(c, r - 11),
        Paint()..color = AppColors.primaryGreen,
      );
      canvas.drawCircle(c, r * 0.2, Paint()..color = AppColors.accentGold);
    }
  }

  @override
  bool shouldRepaint(_BannerPainter old) => old.isDark != isDark;
}

/// Verse-end medallion with the verse number in Arabic-Indic digits.
/// Also used as the numbered badge for surahs.
class AyahMarker extends StatelessWidget {
  const AyahMarker({super.key, required this.number, this.size = 34});

  final int number;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final digits = toArabicDigits(number);
    final fontSize = digits.length > 2 ? size * 0.30 : size * 0.40;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MarkerPainter(
          fill: isDark ? AppColors.cardDark : AppColors.softGold.withOpacity(0.55),
        ),
        child: Center(
          child: Text(
            digits,
            style: TextStyle(
              fontFamily: AppTheme.quranFontFamily,
              fontSize: fontSize,
              height: 1.0,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.softGold : AppColors.primaryGreenDark,
            ),
          ),
        ),
      ),
    );
  }
}

class _MarkerPainter extends CustomPainter {
  const _MarkerPainter({required this.fill});

  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 1;
    final star = octagramPath(c, r);
    canvas.drawPath(star, Paint()..color = fill);
    canvas.drawPath(
      star,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = AppColors.accentGold,
    );
    canvas.drawCircle(
      c,
      r * 0.66,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = AppColors.accentGold.withOpacity(0.8),
    );
  }

  @override
  bool shouldRepaint(_MarkerPainter old) => old.fill != fill;
}

/// Star-shaped badge holding an icon (used for stats and menu tiles).
class StarIconBadge extends StatelessWidget {
  const StarIconBadge({
    super.key,
    required this.icon,
    this.size = 48,
    this.color = AppColors.primaryGreen,
  });

  final IconData icon;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BadgePainter(color: color),
        child: Center(child: Icon(icon, size: size * 0.46, color: color)),
      ),
    );
  }
}

class _BadgePainter extends CustomPainter {
  const _BadgePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final star = octagramPath(c, size.shortestSide / 2 - 1);
    canvas.drawPath(star, Paint()..color = color.withOpacity(0.14));
    canvas.drawPath(
      star,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = color.withOpacity(0.85),
    );
  }

  @override
  bool shouldRepaint(_BadgePainter old) => old.color != color;
}

class _StarMark extends StatelessWidget {
  const _StarMark({this.size = 16});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(painter: _StarMarkPainter()),
    );
  }
}

class _StarMarkPainter extends CustomPainter {
  const _StarMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      octagramPath(size.center(Offset.zero), size.shortestSide / 2),
      Paint()..color = AppColors.accentGold,
    );
  }

  @override
  bool shouldRepaint(_StarMarkPainter old) => false;
}

/// Section heading: star, title, fading gold rule.
class OrnateTitle extends StatelessWidget {
  const OrnateTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        const _StarMark(),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontFamily: AppTheme.quranFontFamily,
            fontSize: 21,
            color: isDark ? AppColors.softGold : AppColors.primaryGreenDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1.2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: AlignmentDirectional.centerStart,
                end: AlignmentDirectional.centerEnd,
                colors: [
                  AppColors.accentGold.withOpacity(0.9),
                  AppColors.accentGold.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Thin gold rule with a centred star.
class StarDivider extends StatelessWidget {
  const StarDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Container(height: 1, color: AppColors.accentGold.withOpacity(0.5)),
    );
    return Row(
      children: [
        line,
        const SizedBox(width: 10),
        const _StarMark(size: 14),
        const SizedBox(width: 10),
        line,
      ],
    );
  }
}
