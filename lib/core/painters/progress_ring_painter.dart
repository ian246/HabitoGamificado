import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// ─────────────────────────────────────────────────────────────
/// ProgressRingPainter — anel circular de progresso por hábito
///
/// Aparece no canto do card de hábito mostrando
/// quantas mini tarefas já foram concluídas.
///
/// Uso:
///   ProgressRing(progress: 0.67, size: 36)
///   ProgressRing(progress: 1.0,  size: 36) // completo
/// ─────────────────────────────────────────────────────────────

class ProgressRing extends StatefulWidget {
  final double progress;  // 0.0 a 1.0
  final double size;
  final Color? color;
  final bool   showLabel;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size      = 36,
    this.color,
    this.showLabel = true,
  });

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;
  double _previousProgress = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween<double>(begin: 0, end: widget.progress)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
    _previousProgress = widget.progress;
  }

  @override
  void didUpdateWidget(ProgressRing old) {
    super.didUpdateWidget(old);
    if (old.progress != widget.progress) {
      _anim = Tween<double>(
        begin: _previousProgress,
        end:   widget.progress,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl
        ..reset()
        ..forward();
      _previousProgress = widget.progress;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ringColor = widget.color ??
        (widget.progress >= 1.0 ? AppColors.primary : AppColors.primary);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => RepaintBoundary(
        child: SizedBox(
          width:  widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _RingPainter(
              progress:   _anim.value,
              color:      ringColor,
              isComplete: widget.progress >= 1.0,
            ),
            child: widget.showLabel
                ? Center(child: _buildLabel(_anim.value))
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(double value) {
    final pct = (value * 100).round();
    return Text(
      '$pct%',
      style: TextStyle(
        fontSize:   widget.size * 0.24,
        fontWeight: FontWeight.w600,
        color:      widget.progress >= 1.0 ? AppColors.primary : AppColors.textSecondary,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double  progress;
  final Color   color;
  final bool    isComplete;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.isComplete,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center      = Offset(size.width / 2, size.height / 2);
    final radius      = size.width / 2 - 3;
    final strokeWidth = size.width * 0.09;

    // Track (fundo do anel)
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color       = color.withAlpha(30)
        ..strokeWidth = strokeWidth
        ..style       = PaintingStyle.stroke,
    );

    if (progress <= 0) return;

    // Arco de progresso
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -math.pi / 2,             // começa do topo (12h)
      2 * math.pi * progress,   // varre até o progresso
      false,
      Paint()
        ..color       = isComplete ? color : color
        ..strokeWidth = strokeWidth
        ..style       = PaintingStyle.stroke
        ..strokeCap   = StrokeCap.round,
    );

    // Ponto de início (topo)
    _drawDot(canvas, center, radius, -math.pi / 2, color);

    // Ponto de fim (segue o arco)
    if (progress > 0.02) {
      final endAngle = -math.pi / 2 + (2 * math.pi * progress);
      _drawDot(canvas, center, radius, endAngle, color);
    }

    // Checkmark quando completo
    if (isComplete) {
      _drawCheck(canvas, center, size.width * 0.20, color);
    }
  }

  void _drawDot(Canvas canvas, Offset center, double r, double angle, Color c) {
    final x = center.dx + r * math.cos(angle);
    final y = center.dy + r * math.sin(angle);
    canvas.drawCircle(
      Offset(x, y),
      3.5,
      Paint()..color = c..style = PaintingStyle.fill,
    );
  }

  void _drawCheck(Canvas canvas, Offset center, double size, Color c) {
    final paint = Paint()
      ..color       = c
      ..strokeWidth = size * 0.18
      ..style       = PaintingStyle.stroke
      ..strokeCap   = StrokeCap.round
      ..strokeJoin  = StrokeJoin.round;

    final path = Path()
      ..moveTo(center.dx - size * 0.5, center.dy)
      ..lineTo(center.dx - size * 0.1, center.dy + size * 0.45)
      ..lineTo(center.dx + size * 0.55, center.dy - size * 0.4);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
    old.progress   != progress   ||
    old.color      != color      ||
    old.isComplete != isComplete;
}
