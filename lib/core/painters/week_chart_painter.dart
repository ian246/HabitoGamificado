import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// ─────────────────────────────────────────────────────────────
/// WeekChartPainter — gráfico de barras dos últimos 7 dias
///
/// Cada barra representa o percentual de conclusão do hábito
/// naquele dia. Cores:
///   Verde  → 100% concluído
///   Âmbar  → parcialmente concluído (> 0%)
///   Cinza  → zero (hábito não feito)
///
/// Uso:
///   WeekChart(
///     data: [1.0, 0.5, 0.0, 1.0, 0.67, 1.0, 0.33],
///     height: 80,
///   )
/// ─────────────────────────────────────────────────────────────

class WeekChart extends StatefulWidget {
  /// Lista com exatamente 7 valores de 0.0 a 1.0
  /// Índice 0 = 6 dias atrás, índice 6 = hoje
  final List<double> data;
  final double height;
  final Color? barColor;
  final Color? partialColor;

  const WeekChart({
    super.key,
    required this.data,
    this.height       = 80,
    this.barColor,
    this.partialColor,
  }) : assert(data.length == 7, 'WeekChart precisa de exatamente 7 valores');

  @override
  State<WeekChart> createState() => _WeekChartState();
}

class _WeekChartState extends State<WeekChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 800),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(WeekChart old) {
    super.didUpdateWidget(old);
    if (old.data != widget.data) {
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final full    = widget.barColor    ?? AppColors.primary;
    final partial = widget.partialColor ?? AppColors.streak;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => RepaintBoundary(
        child: SizedBox(
          height: widget.height + 18, // 18px para os labels de dia
          child: CustomPaint(
            painter: _ChartPainter(
              data:         widget.data,
              animValue:    _anim.value,
              fullColor:    full,
              partialColor: partial,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> data;
  final double       animValue;
  final Color        fullColor;
  final Color        partialColor;

  static const _dayLabels = ['D-6', 'D-5', 'D-4', 'D-3', 'D-2', 'Ont.', 'Hoje'];
  static const _barRadius = Radius.circular(6);
  static const _gap       = 6.0;

  const _ChartPainter({
    required this.data,
    required this.animValue,
    required this.fullColor,
    required this.partialColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const labelHeight = 18.0;
    final chartHeight = size.height - labelHeight;
    final barWidth    = (size.width - (_gap * 6)) / 7;

    for (int i = 0; i < 7; i++) {
      final x       = i * (barWidth + _gap);
      final value   = (data[i] * animValue).clamp(0.0, 1.0);
      final isToday = i == 6;

      // ── Track (fundo da barra) ─────────────────────────────
      final trackRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, 0, barWidth, chartHeight),
        _barRadius,
      );
      canvas.drawRRect(
        trackRect,
        Paint()..color = AppColors.surfaceCard,
      );

      // ── Barra preenchida ───────────────────────────────────
      if (value > 0) {
        final barH    = chartHeight * value;
        final barTop  = chartHeight - barH;
        final barRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, barTop, barWidth, barH),
          _barRadius,
        );

        Color barColor;
        if (data[i] >= 1.0) {
          barColor = fullColor;
        } else if (data[i] > 0) {
          barColor = partialColor;
        } else {
          barColor = AppColors.textHint;
        }

        canvas.drawRRect(barRect, Paint()..color = barColor);
      }

      // ── Destaque "hoje" ────────────────────────────────────
      if (isToday) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, 0, barWidth, chartHeight),
            _barRadius,
          ),
          Paint()
            ..color       = fullColor.withAlpha(30)
            ..style       = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }

      // ── Label de dia ──────────────────────────────────────
      _drawLabel(
        canvas,
        _dayLabels[i],
        Offset(x + barWidth / 2, chartHeight + 5),
        isToday ? fullColor : AppColors.textHint,
      );
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset position, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize:   9,
          color:      color,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(position.dx - tp.width / 2, position.dy));
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
    old.animValue    != animValue    ||
    old.data         != data         ||
    old.fullColor    != fullColor    ||
    old.partialColor != partialColor;
}
