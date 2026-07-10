// lib/widgets/tube_widget.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/tube_model.dart';

// ==========================================
// 🌟 الأنبوب الأساسي (التصميم والأنيميشن)
// ==========================================
class TubeWidget extends StatelessWidget {
  final Tube tube;
  final bool isSelected;
  final bool isHinted;
  final bool showCelebration;
  final VoidCallback onTap;
  final double width;
  final double height;

  static const List<Color> palette = [
    Color(0xFFE6194B), Color(0xFF3CB44B), Color(0xFFFFE119), Color(0xFF4363D8),
    Color(0xFFF58231), Color(0xFF911EB4), Color(0xFF42D4F4), Color(0xFFF032E6),
    Color(0xFFBFEF45), Color(0xFFFABED4), Color(0xFF469990), Color(0xFFDCBEFF),
    Color(0xFF9A6324), Color(0xFF808000),
  ];

  const TubeWidget({
    super.key,
    required this.tube,
    this.isSelected = false,
    this.isHinted = false,
    this.showCelebration = false,
    required this.onTap,
    this.width = 56,
    this.height = 165,
  });

  static Color darken(Color c) => HSLColor.fromColor(c).withLightness((HSLColor.fromColor(c).lightness - 0.15).clamp(0.0, 1.0)).toColor();
  static Color lighten(Color c) => HSLColor.fromColor(c).withLightness((HSLColor.fromColor(c).lightness + 0.15).clamp(0.0, 1.0)).toColor();

  @override
  Widget build(BuildContext context) {
    final bool active = isSelected || isHinted || showCelebration;
    Color glowColor = Colors.transparent;

    if (showCelebration) glowColor = Colors.amber;
    else if (isSelected) glowColor = Colors.white;
    else if (isHinted) glowColor = const Color(0xFFFACC15);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none, // مهم جداً عشان المفرقعات تطلع برا الأنبوب
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, active ? -20 : 0, 0),
            width: width,
            height: height,
            child: CustomPaint(
              painter: ClassicTubePainter(tube: tube, glowColor: active ? glowColor : null),
            ),
          ),

          // 🌟 الانفجار الفخم للورق الملون!
          if (showCelebration)
          // 🌟 الاحتفال: ألعاب نارية لطيفة وواضحة من الأسفل للأعلى
            if (showCelebration)
              const Positioned(
                top: -60, // المساحة فوق الأنبوب تماماً
                left: 0,
                right: 0,
                height: 60, // ارتفاع الألعاب النارية
                child: FancyCelebration(),
              ),
        ],
      ),
    );
  }
}

// ==========================================
// 🌟 رسم الزجاج الكلاسيكي الفخم
// ==========================================
class ClassicTubePainter extends CustomPainter {
  final Tube tube;
  final Color? glowColor;

  ClassicTubePainter({required this.tube, this.glowColor});

  static Path getOuterPath(double w, double h) {
    final double lipH = h * 0.07;
    final double bodyW = w * 0.82;
    final double bodyX = (w - bodyW) / 2;

    return Path()
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, lipH), const Radius.circular(4)))
      ..addRRect(RRect.fromRectAndCorners(
        Rect.fromLTWH(bodyX, lipH - 2, bodyW, h - lipH + 2),
        bottomLeft: Radius.circular(bodyW / 2),
        bottomRight: Radius.circular(bodyW / 2),
      ));
  }

  static Path getInnerPath(double w, double h) {
    final double lipH = h * 0.07;
    final double bodyW = w * 0.82;
    final double bodyX = (w - bodyW) / 2;
    const double t = 4.0;

    return Path()
      ..addRRect(RRect.fromRectAndCorners(
        Rect.fromLTWH(bodyX + t, lipH, bodyW - t * 2, h - lipH - t),
        bottomLeft: Radius.circular((bodyW - t * 2) / 2),
        bottomRight: Radius.circular((bodyW - t * 2) / 2),
      ));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    final outerPath = getOuterPath(w, h);
    final innerPath = getInnerPath(w, h);

    if (glowColor != null) {
      canvas.drawPath(outerPath, Paint()..color = glowColor!.withOpacity(0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
      canvas.drawPath(outerPath, Paint()..color = glowColor!.withOpacity(0.8)..style = PaintingStyle.stroke..strokeWidth = 2.5);
    }

    canvas.drawPath(outerPath, Paint()..color = const Color(0xFF131D33).withOpacity(0.6));

    if (tube.blocks.isNotEmpty) {
      canvas.save();
      canvas.clipPath(innerPath);

      final double lipH = h * 0.07;
      const double t = 4.0;
      final double usableH = h - lipH - t;
      final double layerH = usableH / tube.capacity;

      double bottom = h - t;

      for (int i = 0; i < tube.blocks.length; i++) {
        final isHidden = tube.blocks[i].isMystery;
        final color = isHidden ? const Color(0xFF1E293B) : TubeWidget.palette[tube.blocks[i].colorId % TubeWidget.palette.length];
        final top = bottom - layerH;

        canvas.drawRect(
          Rect.fromLTRB(0, top, w, bottom + 1),
          Paint()..shader = LinearGradient(colors: [TubeWidget.darken(color), color, TubeWidget.lighten(color), color, TubeWidget.darken(color)], stops: const [0.0, 0.2, 0.5, 0.8, 1.0]).createShader(Rect.fromLTWH(0, 0, w, 1)),
        );
        canvas.drawLine(Offset(0, top), Offset(w, top), Paint()..color = Colors.white.withOpacity(0.25)..strokeWidth = 1.5);

        if (isHidden) {
          final tp = TextPainter(text: TextSpan(text: '?', style: TextStyle(color: Colors.white70, fontSize: w * 0.35, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr)..layout();
          tp.paint(canvas, Offset(w / 2 - tp.width / 2, top + layerH / 2 - tp.height / 2));
        }
        bottom -= layerH;
      }
      canvas.restore();
    }

    canvas.drawPath(outerPath, Paint()..color = const Color(0xFF0F172A)..style = PaintingStyle.stroke..strokeWidth = 3.0);
    canvas.drawPath(outerPath, Paint()..color = Colors.white.withOpacity(0.35)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    final lusterPath = Path()..moveTo(w * 0.22, h * 0.15)..lineTo(w * 0.22, h * 0.85);
    canvas.drawPath(lusterPath, Paint()..color = Colors.white.withOpacity(0.2)..style = PaintingStyle.stroke..strokeWidth = w * 0.12..strokeCap = StrokeCap.round);
  }
  @override bool shouldRepaint(covariant ClassicTubePainter old) => true;
}

// ==========================================
// 🌟 نظام الاحتفال السحري الفاخر (النجوم اللامعة)
// ==========================================
class FancyCelebration extends StatelessWidget {
  const FancyCelebration({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCirc,
      builder: (context, progress, child) {
        return CustomPaint(
          size: const Size(120, 120), // مساحة مرتاحة وواضحة
          painter: _PremiumCelebrationPainter(progress),
        );
      },
    );
  }
}

class _PremiumCelebrationPainter extends CustomPainter {
  final double progress;
  _PremiumCelebrationPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0) return;

    final center = Offset(size.width / 2, size.height / 2 + 25); // مركز الانطلاق عند الفوهة
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    // 1. رسم الحلقة الضوئية التي تتوسع بوضوح
    final ringRadius = progress * 55; // حلقة أوسع وأوضح
    final ringPaint = Paint()
      ..color = Colors.amber.withOpacity(opacity * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6 * opacity
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(center, ringRadius, ringPaint);

    // 2. رسم النجوم السحرية اللامعة
    final rng = math.Random(42);

    for (int i = 0; i < 9; i++) { // 9 نجوم ليكونوا واضحين ويعبوا العين
      // توزيع النجوم للأعلى بشكل نصف دائري
      final angle = math.pi + (math.pi / 8) * i;
      final speed = 45.0 + rng.nextDouble() * 50.0;
      final distance = progress * speed;

      final pos = Offset(
        center.dx + math.cos(angle) * distance,
        center.dy + math.sin(angle) * distance,
      );

      // حجم النجمة صار أكبر وأوضح
      final starSize = (7.0 + rng.nextDouble() * 6.0) * opacity;
      final color = TubeWidget.palette[(i * 3) % TubeWidget.palette.length];

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(progress * math.pi);

      // التوهج خلف النجمة (أقوى قليلاً)
      canvas.drawPath(
          _getStarPath(starSize * 1.6),
          Paint()..color = color.withOpacity(opacity * 0.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      );

      // قلب النجمة اللامع
      canvas.drawPath(
          _getStarPath(starSize),
          Paint()..color = Colors.white.withOpacity(opacity)..style = PaintingStyle.fill // أبيض ساطع لتبين أكثر
      );

      canvas.restore();
    }
  }

  // 🌟 هندسة رسم نجمة رباعية حادة
  Path _getStarPath(double size) {
    final path = Path();
    path.moveTo(0, -size);
    path.quadraticBezierTo(size * 0.15, -size * 0.15, size, 0);
    path.quadraticBezierTo(size * 0.15, size * 0.15, 0, size);
    path.quadraticBezierTo(-size * 0.15, size * 0.15, -size, 0);
    path.quadraticBezierTo(-size * 0.15, -size * 0.15, 0, -size);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _PremiumCelebrationPainter old) => old.progress != progress;
}