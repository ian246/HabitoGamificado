import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// ─────────────────────────────────────────────────────────────
/// FramePainter — moldura animada de conquista
///
/// Uso básico:
///   AchievementFrame(
///     days: 45,                          // determina a raridade
///     size: 80,
///     animationValue: _controller.value, // 0.0 a 1.0
///     child: Text('🐶', style: TextStyle(fontSize: 32)),
///   )
///
/// Estrutura visual por raridade:
///   Prata    → 1 anel sólido
///   Ouro     → 1 anel sólido + 1 tracejado
///   Platina  → 2 anéis sólidos + tracejado giratório
///   Esmeralda→ 3 anéis + tracejado + pontos ornamentais
///   Diamante → 4 anéis + tracejado + pontos + reflexo
///   Mestre   → 5 anéis + todos os efeitos + aura pulsante
/// ─────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────
// Widget conveniente que envolve o CustomPaint
// ─────────────────────────────────────────────────────────────
class AchievementFrame extends StatefulWidget {
  final int    days;
  final double size;
  final Widget child;
  final bool   animate;

  const AchievementFrame({
    super.key,
    required this.days,
    required this.child,
    this.size    = 80,
    this.animate = true,
  });

  @override
  State<AchievementFrame> createState() => _AchievementFrameState();
}

class _AchievementFrameState extends State<AchievementFrame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _rotation;
  late Animation<double>   _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(seconds: 6),
    );

    _rotation = Tween<double>(begin: 0, end: 2 * math.pi)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.linear));

    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const _PulseCurve(),
      ),
    );

    if (widget.animate) _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frame = AppColors.frameForDays(widget.days);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => RepaintBoundary(
        child: SizedBox(
          width:  widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _FramePainter(
              frame:        frame,
              days:         widget.days,
              rotationAngle: _rotation.value,
              pulseScale:   _pulse.value,
            ),
            child: Center(child: widget.child),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// O CustomPainter principal
// ─────────────────────────────────────────────────────────────
class _FramePainter extends CustomPainter {
  final FrameColors frame;
  final int         days;
  final double      rotationAngle;
  final double      pulseScale;

  const _FramePainter({
    required this.frame,
    required this.days,
    required this.rotationAngle,
    required this.pulseScale,
  });

  // Determina quantas "camadas" de anel mostrar
  int get _ringCount {
    if (days >= 300) return 5; // Mestre
    if (days >= 200) return 4; // Diamante
    if (days >= 150) return 3; // Esmeralda
    if (days >= 75)  return 2; // Platina
    if (days >= 30)  return 1; // Ouro
    return 0;                  // Prata — só o anel base
  }

  bool get _hasSpinningDash => days >= 75;  // Platina em diante
  bool get _hasOrnaments    => days >= 150; // Esmeralda em diante
  bool get _hasPulse        => days >= 300; // Mestre

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR   = size.width / 2 - 2;

    // ── Aura pulsante (Mestre) ───────────────────────────────
    if (_hasPulse) {
      _drawPulseAura(canvas, center, maxR * 1.05 * pulseScale);
    }

    // ── Anel base (sempre presente) ──────────────────────────
    _drawRing(canvas, center, maxR, frame.ring, strokeWidth: 4.5);

    // ── Anéis concêntricos extras ────────────────────────────
    for (int i = 1; i <= _ringCount; i++) {
      final r = maxR - (i * (maxR * 0.14));
      final opacity = 1.0 - (i * 0.15);
      _drawRing(
        canvas, center, r,
        frame.glow.withAlpha((opacity * 255).round()),
        strokeWidth: i == _ringCount ? 2.5 : 1.5,
      );
    }

    // ── Anel tracejado giratório (Platina em diante) ─────────
    if (_hasSpinningDash) {
      _drawDashedArc(
        canvas, center,
        maxR - 8,
        frame.shine,
        startAngle: rotationAngle,
        dashLength: 8,
        gapLength:  5,
        strokeWidth: 2,
      );
    }

    // ── Pontos ornamentais (Esmeralda em diante) ─────────────
    if (_hasOrnaments) {
      _drawOrnamentDots(canvas, center, maxR + 1, frame.glow);
    }
  }

  // ── Helpers de desenho ───────────────────────────────────────

  void _drawRing(
    Canvas canvas,
    Offset center,
    double radius,
    Color color, {
    double strokeWidth = 3,
  }) {
    final paint = Paint()
      ..color       = color
      ..strokeWidth = strokeWidth
      ..style       = PaintingStyle.stroke
      ..strokeCap   = StrokeCap.round;

    canvas.drawCircle(center, radius, paint);
  }

  void _drawDashedArc(
    Canvas canvas,
    Offset center,
    double radius,
    Color color, {
    required double startAngle,
    required double dashLength,
    required double gapLength,
    double strokeWidth = 2,
  }) {
    final paint = Paint()
      ..color       = color
      ..strokeWidth = strokeWidth
      ..style       = PaintingStyle.stroke
      ..strokeCap   = StrokeCap.round;

    final circumference = 2 * math.pi * radius;
    final dashAngle     = (dashLength / circumference) * 2 * math.pi;
    final gapAngle      = (gapLength  / circumference) * 2 * math.pi;
    final totalAngle    = dashAngle + gapAngle;
    final steps         = (2 * math.pi / totalAngle).floor();

    for (int i = 0; i < steps; i++) {
      final angle = startAngle + (i * totalAngle);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        angle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  void _drawOrnamentDots(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const dotCount = 8;
    const angleStep = (2 * math.pi) / dotCount;

    for (int i = 0; i < dotCount; i++) {
      final angle = (i * angleStep) - (math.pi / 2);
      final x = center.dx + (radius + 3) * math.cos(angle);
      final y = center.dy + (radius + 3) * math.sin(angle);
      // Alterna entre dot grande e pequeno
      canvas.drawCircle(Offset(x, y), i % 2 == 0 ? 2.5 : 1.5, paint);
    }
  }

  void _drawPulseAura(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color       = frame.ring.withAlpha(40)
      ..strokeWidth = 8
      ..style       = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_FramePainter old) =>
    old.rotationAngle != rotationAngle ||
    old.pulseScale    != pulseScale    ||
    old.days          != days;
}

// ─────────────────────────────────────────────────────────────
// Curva de pulso suave para a animação do Mestre
// ─────────────────────────────────────────────────────────────
class _PulseCurve extends Curve {
  const _PulseCurve();

  @override
  double transform(double t) => (math.sin(t * 2 * math.pi) * 0.5 + 0.5);
}

// ─────────────────────────────────────────────────────────────
// Widget de preview para ver todas as molduras de uma vez
// Útil para desenvolvimento — pode usar em uma tela de teste
// ─────────────────────────────────────────────────────────────
class FrameShowcase extends StatelessWidget {
  const FrameShowcase({super.key});

  static const _frames = [
    (days: 5,   label: 'Prata'),
    (days: 30,  label: 'Ouro'),
    (days: 75,  label: 'Platina'),
    (days: 150, label: 'Esmeralda'),
    (days: 200, label: 'Diamante'),
    (days: 300, label: 'Mestre'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 20,
      alignment: WrapAlignment.center,
      children: _frames.map((f) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AchievementFrame(
              days: f.days,
              size: 70,
              child: const Text('🏆', style: TextStyle(fontSize: 26)),
            ),
            const SizedBox(height: 6),
            Text(f.label, style: const TextStyle(fontSize: 11)),
          ],
        );
      }).toList(),
    );
  }
}
