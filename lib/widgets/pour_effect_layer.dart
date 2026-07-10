// lib/widgets/pour_effect_layer.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/tube_model.dart';
import 'tube_widget.dart';

class PourEffectLayer extends StatelessWidget {
  final Rect fromRect;
  final Rect toRect;
  final Color color;
  final double progress;
  final int moveCount;
  final Tube fromTube;
  final Tube toTube;

  const PourEffectLayer({
    super.key,
    required this.fromRect,
    required this.toRect,
    required this.color,
    required this.progress,
    required this.moveCount,
    required this.fromTube,
    required this.toTube,
  });

  @override
  Widget build(BuildContext context) {
    bool isPouringRight = toRect.left >= fromRect.left;
    final double dirMultiplier = isPouringRight ? 1.0 : -1.0;
    final double maxTilt = (math.pi / 2.1) * dirMultiplier;

    double flyAnim = 0.0;
    double currentAngle = 0.0;
    double pourAnim = 0.0;
    double streamProgress = 0.0;

    if (progress <= 0.25) {
      // الذهاب والميلان
      double p = progress / 0.25;
      flyAnim = Curves.easeInOutCubic.transform(p);
      currentAngle = maxTilt * Curves.easeInOutCubic.transform(p);
    } else if (progress <= 0.65) {
      // الصب
      flyAnim = 1.0;
      currentAngle = maxTilt;
      pourAnim = (progress - 0.25) / 0.40;
      streamProgress = pourAnim;
    } else {
      // العودة الملكية
      double p = (progress - 0.65) / 0.35;
      flyAnim = 1.0 - Curves.easeOutCubic.transform(p);
      currentAngle = maxTilt * (1.0 - Curves.easeOutCubic.transform(p));
      pourAnim = 1.0;
      streamProgress = 1.0; // ⚠️ هذا يضمن اختفاء الخط العجيب فوراً!
    }

    double lipFractionX = isPouringRight ? 0.95 : 0.05;
    double lipFractionY = 0.04;

    double lipX = fromRect.width * lipFractionX;
    double lipY = fromRect.height * lipFractionY;

    final double xOffset = isPouringRight ? -14.0 : 14.0;
    final Offset hoverTarget = Offset(toRect.left + xOffset, toRect.top - 45);

    final Offset currentPos = Offset(
      fromRect.left + (hoverTarget.dx - fromRect.left) * flyAnim,
      fromRect.top + (hoverTarget.dy - fromRect.top) * flyAnim,
    );

    Offset streamStart = Offset(currentPos.dx + lipX, currentPos.dy + lipY);

    final double lipH = toRect.height * 0.08; // تطابق مع TubeWidget
    const double t = 3.5;
    final double usableH = toRect.height - lipH - t;

    double dstLevel = toTube.blocks.length / toTube.capacity;
    double addedLevel = (moveCount / toTube.capacity) * progress;
    double liquidHeightPixels = (dstLevel + addedLevel) * usableH;

    Offset streamEnd = Offset(
      toRect.left + toRect.width / 2,
      toRect.top + (toRect.height - t) - liquidHeightPixels,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: toRect.left, top: toRect.top, width: toRect.width, height: toRect.height,
          child: CustomPaint(painter: TargetRisingLiquidPainter(tube: toTube, moveCount: moveCount, pourAnim: pourAnim, color: color)),
        ),

        // 🌟 لن يتم رسم خيط الماء أثناء العودة أبداً!
        if (streamProgress > 0.0 && streamProgress < 1.0)
          Positioned.fill(
            child: CustomPaint(painter: WaterStreamPainter(start: streamStart, end: streamEnd, progress: streamProgress, color: color)),
          ),

        Positioned(
          left: currentPos.dx, top: currentPos.dy,
          child: Transform.rotate(
            alignment: FractionalOffset(lipFractionX, lipFractionY),
            angle: currentAngle,
            child: SizedBox(
              width: fromRect.width, height: fromRect.height,
              child: CustomPaint(
                painter: FlyingBottlePainter(tube: fromTube, moveCount: moveCount, color: color, tiltAngle: currentAngle, pourAnim: pourAnim),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 🌟 الأنبوب الطائر (تم إصلاح الفيزياء والميلان بالكامل)
// ==========================================
class FlyingBottlePainter extends CustomPainter {
  final Tube tube;
  final int moveCount;
  final Color color;
  final double tiltAngle;
  final double pourAnim;

  FlyingBottlePainter({required this.tube, required this.moveCount, required this.color, required this.tiltAngle, required this.pourAnim});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    final outerPath = ClassicTubePainter.getOuterPath(w, h);
    final innerPath = ClassicTubePainter.getInnerPath(w, h);

    canvas.drawPath(outerPath, Paint()..color = const Color(0xFF131D33).withOpacity(0.6));

    canvas.save();
    canvas.clipPath(innerPath); // السائل محمي بقص الزجاج

    final double lipH = h * 0.08;
    const double t = 3.5;
    final double usableH = h - lipH - t;
    final double layerH = usableH / tube.capacity;

    double bottom = h - t;
    int baseCount = tube.blocks.length - moveCount;

    // 🌟 السحر الرياضي: حساب ميلان خط السائل ليبقى أفقي بدون تشويه الألوان
    final double centerX = w / 2;
    final double safeTilt = tiltAngle.clamp(-math.pi/2.05, math.pi/2.05); // حماية من الأخطاء
    final double tanA = math.tan(-safeTilt);

    // 1. رسم الألوان الأساسية والمخفية (كلها تميل كالسائل)
    for (int i = 0; i < baseCount; i++) {
      final isHidden = tube.blocks[i].isMystery;
      final blockColor = isHidden ? const Color(0xFF1E293B) : TubeWidget.palette[tube.blocks[i].colorId % TubeWidget.palette.length];

      double centerBottom = bottom - layerH * i;
      double centerTop = bottom - layerH * (i + 1);

      _drawSlantedLayer(canvas, blockColor, centerTop, centerBottom, w, h, centerX, tanA, isBottom: i == 0);

      if (isHidden) {
        final tp = TextPainter(text: TextSpan(text: '?', style: TextStyle(color: Colors.white70, fontSize: w * 0.35, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr)..layout();
        double midY = (centerTop + centerBottom) / 2;

        // 🌟 جعل علامة الاستفهام تقف باستقامة رغم ميلان الزجاجة
        canvas.save();
        canvas.translate(centerX, midY);
        canvas.rotate(-tiltAngle);
        tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
        canvas.restore();
      }
    }

    // 2. رسم اللون المنسكب (ينقص تدريجياً وهو مائل)
    if (moveCount > 0 && pourAnim < 1.0) {
      final shrink = 1.0 - pourAnim;
      double centerBottom = bottom - layerH * baseCount;
      double centerTop = centerBottom - layerH * moveCount * shrink;

      _drawSlantedLayer(canvas, color, centerTop, centerBottom, w, h, centerX, tanA, isBottom: baseCount == 0);
    }

    canvas.restore();

    // رسم زجاج الأنبوب الثابت فوق السائل
    canvas.drawPath(outerPath, Paint()..color = const Color(0xFF0F172A)..style = PaintingStyle.stroke..strokeWidth = 3.0);
    canvas.drawPath(outerPath, Paint()..color = Colors.white.withOpacity(0.35)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    final lusterPath = Path()..moveTo(w * 0.22, h * 0.15)..lineTo(w * 0.22, h * 0.85);
    canvas.drawPath(lusterPath, Paint()..color = Colors.white.withOpacity(0.2)..style = PaintingStyle.stroke..strokeWidth = w * 0.12..strokeCap = StrokeCap.round);
  }

  // 🌟 دالة ترسم كتلة السائل المائلة دون الخروج عن حدود الزجاج
  void _drawSlantedLayer(Canvas canvas, Color color, double top, double bottom, double w, double h, double centerX, double tanA, {required bool isBottom}) {
    double tlY = top + tanA * (0 - centerX);
    double trY = top + tanA * (w - centerX);

    double blY, brY;
    if (isBottom) {
      blY = h + 20; // ضمان تغطية القاع المنحني للزجاجة
      brY = h + 20;
    } else {
      blY = bottom + tanA * (0 - centerX);
      brY = bottom + tanA * (w - centerX);
    }

    Path poly = Path()
      ..moveTo(-10, tlY)
      ..lineTo(w + 10, trY)
      ..lineTo(w + 10, brY + 1) // تجاوز طفيف لمنع الخطوط الفارغة
      ..lineTo(-10, blY + 1)
      ..close();

    canvas.drawPath(poly, Paint()..shader = LinearGradient(
        colors: [TubeWidget.darken(color), color, TubeWidget.lighten(color), color, TubeWidget.darken(color)],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0]
    ).createShader(Rect.fromLTWH(0, 0, w, 1)));

    canvas.drawLine(Offset(0, tlY), Offset(w, trY), Paint()..color = Colors.white.withOpacity(0.25)..strokeWidth = 1.5);
  }
  @override bool shouldRepaint(covariant FlyingBottlePainter old) => true;
}

class TargetRisingLiquidPainter extends CustomPainter {
  final Tube tube;
  final int moveCount;
  final double pourAnim;
  final Color color;

  TargetRisingLiquidPainter({required this.tube, required this.moveCount, required this.pourAnim, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (pourAnim <= 0.0) return;
    final w = size.width; final h = size.height;

    canvas.save();
    canvas.clipPath(ClassicTubePainter.getInnerPath(w, h));

    final double lipH = h * 0.08;
    const double t = 3.5;
    final double usableH = h - lipH - t;
    final double layerH = usableH / tube.capacity;

    double bottom = (h - t) - (layerH * tube.blocks.length);

    final double addedH = layerH * moveCount * pourAnim;
    if (addedH > 0.5) {
      final top = bottom - addedH;
      canvas.drawRect(Rect.fromLTRB(0, top, w, bottom + 1), Paint()..shader = LinearGradient(colors: [TubeWidget.darken(color), color, TubeWidget.lighten(color), color, TubeWidget.darken(color)], stops: const [0.0, 0.2, 0.5, 0.8, 1.0]).createShader(Rect.fromLTWH(0, 0, w, 1)));
      canvas.drawLine(Offset(0, top), Offset(w, top), Paint()..color = Colors.white.withOpacity(0.25)..strokeWidth = 1.5);
    }
    canvas.restore();
  }
  @override bool shouldRepaint(covariant TargetRisingLiquidPainter old) => true;
}

class WaterStreamPainter extends CustomPainter {
  final Offset start; final Offset end; final double progress; final Color color;
  WaterStreamPainter({required this.start, required this.end, required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    const topW = 6.0; const bottomW = 3.5;
    path.moveTo(start.dx - topW / 2, start.dy);
    path.lineTo(start.dx + topW / 2, start.dy);
    path.quadraticBezierTo(start.dx + topW / 2, start.dy + 20, end.dx + bottomW / 2, end.dy);
    path.lineTo(end.dx - bottomW / 2, end.dy);
    path.quadraticBezierTo(start.dx - topW / 2, start.dy + 20, start.dx - topW / 2, start.dy);
    path.close();

    final rect = Rect.fromLTRB(0, progress < 0.85 ? 0 : start.dy + ((progress - 0.85) / 0.15) * (end.dy - start.dy), size.width, progress < 0.15 ? start.dy + (progress / 0.15) * (end.dy - start.dy) : size.height);
    canvas.save();
    canvas.clipRect(rect);
    canvas.drawPath(path, Paint()..color = color.withOpacity(0.70)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    canvas.drawPath(path, Paint()..shader = LinearGradient(colors: [TubeWidget.darken(color), TubeWidget.lighten(color), TubeWidget.darken(color)]).createShader(Rect.fromLTRB(start.dx - topW, 0, start.dx + topW, 1)));
    canvas.restore();

    if (progress > 0.10 && progress < 0.90) {
      final rng = math.Random(42);
      final paint = Paint()..color = color.withOpacity(0.80);
      for (int i = 0; i < 4; i++) {
        final angle = (i / 4) * math.pi * 2 + rng.nextDouble() * 0.8;
        final radius = 5 + rng.nextDouble() * 8;
        final phase = (progress * 4 + i * 0.5) % 1.0;
        canvas.drawCircle(Offset(end.dx + math.cos(angle) * (radius * phase), end.dy + math.sin(angle) * (radius * phase) * 0.5), (1.8 + rng.nextDouble()) * (1 - phase), paint);
      }
    }
  }
  @override bool shouldRepaint(covariant CustomPainter old) => true;
}