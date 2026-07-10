import 'dart:math' as math;
import 'package:flutter/material.dart';

// ==========================================
// Dados do Tubo
// ==========================================
class TubeData {
  List<Color> colors;
  final int capacity = 4;
  TubeData({required this.colors});

  bool get isEmpty => colors.isEmpty;
  bool get isFull => colors.length >= capacity;
  Color? get topColor => colors.isNotEmpty ? colors.last : null;

  int get pourableCount {
    if (colors.isEmpty) return 0;
    int count = 0;
    Color top = colors.last;
    for (var i = colors.length - 1; i >= 0; i--) {
      if (colors[i] == top) count++;
      else break;
    }
    return count;
  }
}

// ==========================================
// Cores do Jogo
// ==========================================
class GameColors {
  static const Color bgTop    = Color(0xFF0D1B3E);
  static const Color bgBottom = Color(0xFF0A0F2C);

  static const Color red    = Color(0xFFFF3A5C);
  static const Color blue   = Color(0xFF3AB4FF);
  static const Color yellow = Color(0xFFFFD600);
  static const Color green  = Color(0xFF3DFF9A);
  static const Color purple = Color(0xFFB44DFF);
  static const Color orange = Color(0xFFFF7A1A);

  static Color glowFor(Color c) => c.withOpacity(0.50);
  static Color darkFor(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - 0.18).clamp(0.0, 1.0)).toColor();
  }
  static Color lightFor(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + 0.18).clamp(0.0, 1.0)).toColor();
  }
}

// ==========================================
// Tela Principal
// ==========================================
class FullGameTest extends StatefulWidget {
  const FullGameTest({super.key});
  @override
  State<FullGameTest> createState() => _FullGameTestState();
}

class _FullGameTestState extends State<FullGameTest>
    with TickerProviderStateMixin {

  late AnimationController _ctrl;
  late Animation<double> _flyAnim;
  late Animation<double> _pourAnim;

  late AnimationController _selectCtrl;
  late Animation<double> _selectAnim;

  static const Size bottleSize = Size(54, 160);

  late List<TubeData> tubes;
  int? selectedIdx;
  int? targetIdx;
  bool isAnimating = false;
  int    pouringAmount = 0;
  Color? pouringColor;

  @override
  void initState() {
    super.initState();
    _setupLevel();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _flyAnim = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 25,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 50),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 25,
      ),
    ]).animate(_ctrl);

    _pourAnim = TweenSequence([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 30),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.linear)),
        weight: 50,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 20),
    ]).animate(_ctrl);

    _ctrl.addListener(() => setState(() {}));
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) _finalizePour();
    });

    _selectCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _selectAnim = Tween<double>(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(_selectCtrl);
    _selectCtrl.addListener(() => setState(() {}));
  }

  void _setupLevel() {
    tubes = [
      TubeData(colors: [GameColors.red,    GameColors.blue,   GameColors.red,    GameColors.yellow]),
      TubeData(colors: [GameColors.yellow, GameColors.blue,   GameColors.green,  GameColors.green]),
      TubeData(colors: [GameColors.purple, GameColors.red,    GameColors.yellow, GameColors.blue]),
      TubeData(colors: [GameColors.green,  GameColors.purple, GameColors.purple, GameColors.red]),
      TubeData(colors: [GameColors.yellow, GameColors.blue,   GameColors.green,  GameColors.purple]),
      TubeData(colors: [GameColors.purple, GameColors.green,  GameColors.red,    GameColors.yellow]),
      TubeData(colors: []),
      TubeData(colors: []),
    ];
  }

  Offset _getPos(int index) {
    int row = index ~/ 4;
    int col = index % 4;
    double x = 20.0 + col * (bottleSize.width + 25);
    double y = 200.0 + row * (bottleSize.height + 60);
    return Offset(x, y);
  }

  void _onTubeTap(int index) {
    if (isAnimating) return;
    setState(() {
      if (selectedIdx == null) {
        if (tubes[index].colors.isNotEmpty) {
          selectedIdx = index;
          _selectCtrl.forward(from: 0);
        }
      } else {
        if (selectedIdx == index) {
          selectedIdx = null;
          _selectCtrl.reverse();
        } else {
          final src = tubes[selectedIdx!];
          final dst = tubes[index];

          if (!dst.isFull && (dst.isEmpty || dst.topColor == src.topColor)) {
            targetIdx     = index;
            isAnimating   = true;
            pouringColor  = src.topColor;
            int canTake   = 4 - dst.colors.length;
            pouringAmount = math.min(src.pourableCount, canTake);
            _ctrl.forward(from: 0);
          } else {
            selectedIdx = index;
            _selectCtrl.forward(from: 0);
          }
        }
      }
    });
  }

  void _finalizePour() {
    setState(() {
      for (int i = 0; i < pouringAmount; i++) {
        tubes[targetIdx!].colors.add(tubes[selectedIdx!].colors.removeLast());
      }
      isAnimating  = false;
      selectedIdx  = null;
      targetIdx    = null;
      _ctrl.reset();
      _selectCtrl.reset();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _selectCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _pourAnim.value;

    double currentAngle    = 0.0;
    Offset currentPos  = Offset.zero;
    Offset streamStart = Offset.zero;
    Offset streamEnd   = Offset.zero;

    // Valores padrão para o ponto de pivô e direção
    double lipX = 38.0;
    bool isPouringRight = true;

    if (isAnimating) {
      final Offset start  = _getPos(selectedIdx!);
      final Offset target = _getPos(targetIdx!);

      // 🔴 Magia dinâmica: determinando a direção com base nas posições dos tubos
      isPouringRight = target.dx >= start.dx;
      final double dirMultiplier = isPouringRight ? 1.0 : -1.0;

      // Calculando ângulos e invertendo se derramar para a esquerda
      final double startTilt = (math.pi / 2.5) * dirMultiplier;
      final double endTilt   = (math.pi / 1.7) * dirMultiplier;

      if (_ctrl.value < 0.3) {
        currentAngle = startTilt * (_ctrl.value / 0.3);
      } else if (_ctrl.value > 0.8) {
        currentAngle = endTilt * ((1.0 - _ctrl.value) / 0.2);
      } else {
        currentAngle = startTilt + ((endTilt - startTilt) * progress);
      }

      // Definindo o lábio correto para pivô e saída de água
      lipX = isPouringRight ? 38.0 : 16.0;

      // Deslocando o alvo para que o lábio fique logo acima do tubo
      final double xOffset = isPouringRight ? -10.0 : 10.0;
      final Offset hoverTarget = Offset(target.dx + xOffset, target.dy - 35);

      currentPos = Offset(
        start.dx + (hoverTarget.dx - start.dx) * _flyAnim.value,
        start.dy + (hoverTarget.dy - start.dy) * _flyAnim.value,
      );

      streamStart = Offset(currentPos.dx + lipX, currentPos.dy + 3);

      double dstLevel   = tubes[targetIdx!].colors.length / 4.0;
      double addedLevel = (pouringAmount / 4.0) * progress;
      streamEnd = Offset(
        target.dx + 27,
        target.dy + bottleSize.height - ((dstLevel + addedLevel) * bottleSize.height) - 10,
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          _buildTopBar(),

          for (int i = 0; i < tubes.length; i++)
            if (!(isAnimating && i == selectedIdx))
              _buildBottle(i, progress),

          if (isAnimating && progress > 0.0 && progress < 1.0)
            Positioned.fill(
              child: CustomPaint(
                painter: WaterStreamPainter(
                  start:    streamStart,
                  end:      streamEnd,
                  progress: progress,
                  color:    pouringColor!,
                ),
              ),
            ),

          if (isAnimating)
            Positioned(
              left: currentPos.dx,
              top:  currentPos.dy,
              child: Transform.rotate(
                // 🔴 O pivô muda dinamicamente (direita ou esquerda)
                alignment: FractionalOffset(lipX / bottleSize.width, 0),
                angle: currentAngle,
                child: SizedBox(
                  width:  bottleSize.width,
                  height: bottleSize.height,
                  child: CustomPaint(
                    painter: ProBottlePainter(
                      colors:          tubes[selectedIdx!].colors,
                      tiltAngle:       currentAngle,
                      removedCount:    pouringAmount,
                      removedProgress: progress,
                      isSelected:      false,
                      isFlying:        true,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end:   Alignment.bottomCenter,
          colors: [GameColors.bgTop, GameColors.bgBottom],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Water Sort',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color:        Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border:       Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: const Text(
                  'Level 1',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottle(int i, double progress) {
    final bool isSelected = selectedIdx == i;
    final bool isTarget   = isAnimating && targetIdx == i;
    final double liftY = isSelected ? _selectAnim.value * 18.0 : 0.0;

    return Positioned(
      left: _getPos(i).dx,
      top:  _getPos(i).dy - liftY,
      child: GestureDetector(
        onTap: () => _onTubeTap(i),
        child: SizedBox(
          width:  bottleSize.width,
          height: bottleSize.height,
          child: CustomPaint(
            painter: ProBottlePainter(
              colors:         tubes[i].colors,
              tiltAngle:      0,
              isSelected:     isSelected,
              isTarget:       isTarget,
              addedCount:     isTarget ? pouringAmount : 0,
              addedProgress:  progress,
              pouringColor:   pouringColor,
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// Desenhando a Garrafa Profissional
// ==========================================
class ProBottlePainter extends CustomPainter {
  final List<Color> colors;
  final double tiltAngle;
  final bool isSelected;
  final bool isTarget;
  final bool isFlying;
  final int addedCount;
  final double addedProgress;
  final int removedCount;
  final double removedProgress;
  final Color? pouringColor;

  ProBottlePainter({
    required this.colors,
    required this.tiltAngle,
    this.isSelected    = false,
    this.isTarget      = false,
    this.isFlying      = false,
    this.addedCount    = 0,
    this.addedProgress = 0.0,
    this.removedCount  = 0,
    this.removedProgress = 0.0,
    this.pouringColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    const double neckW      = 20.0;
    const double neckH      = 24.0;
    const double cornerR    = 14.0;
    final double neckX      = (w - neckW) / 2;

    final bottlePath = Path()
      ..moveTo(neckX,              0)
      ..lineTo(neckX + neckW,      0)
      ..lineTo(neckX + neckW,      neckH)
      ..quadraticBezierTo(w,       neckH + 5,  w, neckH + 20)
      ..lineTo(w,                  h - cornerR)
      ..quadraticBezierTo(w,       h,          w - cornerR, h)
      ..lineTo(cornerR,            h)
      ..quadraticBezierTo(0,       h,          0, h - cornerR)
      ..lineTo(0,                  neckH + 20)
      ..quadraticBezierTo(0,       neckH + 5,  neckX, neckH)
      ..close();

    if (isSelected || isTarget) {
      final glowColor = isSelected
          ? Colors.white
          : (pouringColor ?? Colors.white);
      canvas.drawPath(
        bottlePath,
        Paint()
          ..color      = glowColor.withOpacity(0.20)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16)
          ..style      = PaintingStyle.stroke
          ..strokeWidth = 10,
      );
    }

    if (colors.isNotEmpty || addedCount > 0) {
      canvas.save();
      canvas.clipPath(bottlePath);

      canvas.drawPath(
        bottlePath,
        Paint()..color = Colors.black.withOpacity(0.20),
      );

      canvas.translate(w / 2, h / 2);
      canvas.rotate(-tiltAngle);
      canvas.translate(-w / 2, -h / 2);

      final double layerH = h / 4.0;
      int    baseCount    = colors.length - removedCount;
      double bottom       = h;

      for (int i = 0; i < baseCount; i++) {
        _drawLayer(canvas, colors[i],
            top: bottom - layerH, bottom: bottom, width: w);
        bottom -= layerH;
      }

      if (removedCount > 0 && removedProgress < 1.0) {
        final shrink   = 1.0 - removedProgress;
        final topColor = colors.isNotEmpty ? colors.last : Colors.transparent;
        final layerTop = bottom - layerH * removedCount * shrink;
        // Tomamos o valor absoluto da inclinação para compensar a elevação de ambos os lados
        _drawLayer(canvas, topColor,
            top: layerTop - (tiltAngle.abs() * 15),
            bottom: bottom,
            width: w);
      }

      if (addedCount > 0 && pouringColor != null && addedProgress > 0) {
        final addedH = layerH * addedCount * addedProgress;
        if (addedH > 0.5) {
          _drawLayer(canvas, pouringColor!,
              top: bottom - addedH, bottom: bottom, width: w);
        }
      }

      canvas.restore();
    }

    canvas.drawPath(
      bottlePath,
      Paint()
        ..color       = Colors.black.withOpacity(0.15)
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 6,
    );

    canvas.drawPath(
      bottlePath,
      Paint()
        ..color       = Colors.white.withOpacity(isSelected ? 0.80 : 0.35)
        ..style       = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.2 : 1.8,
    );

    final lusterPath = Path()
      ..moveTo(w * 0.18, neckH + 28)
      ..quadraticBezierTo(w * 0.10, h * 0.50, w * 0.18, h * 0.78);
    canvas.drawPath(
      lusterPath,
      Paint()
        ..color       = Colors.white.withOpacity(0.20)
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap   = StrokeCap.round,
    );

    final luster2 = Path()
      ..moveTo(w * 0.24, neckH + 32)
      ..quadraticBezierTo(w * 0.18, h * 0.38, w * 0.24, h * 0.55);
    canvas.drawPath(
      luster2,
      Paint()
        ..color       = Colors.white.withOpacity(0.10)
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap   = StrokeCap.round,
    );

    final capRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(neckX - 2, -2, neckW + 4, 6),
      const Radius.circular(2),
    );
    canvas.drawRRect(
      capRect,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white.withOpacity(0.65), Colors.white.withOpacity(0.20)],
          begin:  Alignment.topCenter,
          end:    Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(neckX - 2, -2, neckW + 4, 6)),
    );
    canvas.drawRRect(
      capRect,
      Paint()
        ..color       = Colors.white.withOpacity(0.55)
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _drawLayer(
      Canvas canvas,
      Color color, {
        required double top,
        required double bottom,
        required double width,
      }) {
    final rect = Rect.fromLTRB(-width * 2, top, width * 3, bottom + 2);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin:  Alignment.centerLeft,
          end:    Alignment.centerRight,
          colors: [
            GameColors.darkFor(color),
            color,
            GameColors.lightFor(color),
            color,
            GameColors.darkFor(color),
          ],
          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, width, 1)),
    );

    canvas.drawLine(
      Offset(-width, top),
      Offset(width * 3, top),
      Paint()
        ..color       = Colors.white.withOpacity(0.18)
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

// ==========================================
// Fluxo de Água
// ==========================================
class WaterStreamPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final double progress;
  final Color color;

  WaterStreamPainter({
    required this.start,
    required this.end,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path     = Path();
    const topW     = 8.0;
    const bottomW  = 4.0;

    path.moveTo(start.dx - topW / 2, start.dy);
    path.lineTo(start.dx + topW / 2, start.dy);
    path.quadraticBezierTo(
      start.dx + topW / 2, start.dy + 20,
      end.dx   + bottomW / 2, end.dy,
    );
    path.lineTo(end.dx - bottomW / 2, end.dy);
    path.quadraticBezierTo(
      start.dx - topW / 2, start.dy + 20,
      start.dx - topW / 2, start.dy,
    );
    path.close();

    final rect = Rect.fromLTRB(
      0,
      progress < 0.85
          ? 0
          : start.dy + ((progress - 0.85) / 0.15) * (end.dy - start.dy),
      size.width,
      progress < 0.15
          ? start.dy + (progress / 0.15) * (end.dy - start.dy)
          : size.height,
    );
    canvas.save();
    canvas.clipRect(rect);

    canvas.drawPath(
      path,
      Paint()
        ..color      = GameColors.glowFor(color)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin:  Alignment.centerLeft,
          end:    Alignment.centerRight,
          colors: [
            GameColors.darkFor(color),
            GameColors.lightFor(color),
            GameColors.darkFor(color),
          ],
        ).createShader(Rect.fromLTRB(
          start.dx - topW, 0, start.dx + topW, 1,
        )),
    );

    canvas.restore();

    if (progress > 0.18 && progress < 0.88) {
      _drawSplash(canvas, end, color, progress);
    }
  }

  void _drawSplash(Canvas canvas, Offset center, Color color, double t) {
    final rng   = math.Random(42);
    final paint = Paint()..color = color.withOpacity(0.50);

    for (int i = 0; i < 4; i++) {
      final angle  = (i / 4) * math.pi * 2 + rng.nextDouble() * 0.8;
      final radius = 5 + rng.nextDouble() * 9;
      final phase  = (t * 3 + i * 0.5) % 1.0;
      final r      = radius * phase;

      canvas.drawCircle(
        Offset(
          center.dx + math.cos(angle) * r,
          center.dy + math.sin(angle) * r * 0.5,
        ),
        (1.5 + rng.nextDouble()) * (1 - phase),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}