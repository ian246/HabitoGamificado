import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/painters/progress_ring_painter.dart';
import '../models/habit.dart';
import 'subtask_tile.dart';

class HabitCard extends StatelessWidget {
  final Habit         habit;
  final ValueChanged<String>? onSubtaskToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const HabitCard({
    super.key,
    required this.habit,
    this.onSubtaskToggle,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = habit.progressoHoje;
    final isDone   = habit.completoHoje;

    return Dismissible(
      key: ValueKey(habit.id),
      direction: DismissDirection.endToStart,
      background: _dismissBackground(),
      confirmDismiss: (_) async {
        return await _confirmDelete(context);
      },
      onDismissed: (_) => onDelete?.call(),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Cabeçalho ───────────────────────────
                Row(
                  children: [
                    // Ícone + período
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(habit.icone,
                          style: const TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.nome,
                            style: isDone
                                ? AppTextStyles.habitNameDone
                                : AppTextStyles.habitName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          _PeriodChip(period: habit.periodo),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Anel de progresso
                    ProgressRing(
                      progress:  progress,
                      size:      40,
                      showLabel: true,
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // ── Subtarefas ───────────────────────────
                ...habit.miniTarefas.map((s) => SubtaskTile(
                      subtask:     s,
                      onToggle:    () => onSubtaskToggle?.call(s.id),
                      interactive: !isDone || s.feita,
                    )),

                const SizedBox(height: 10),

                // ── Barra de progresso + rodapé ──────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (_, val, __) => LinearProgressIndicator(
                      value:           val,
                      minHeight:       5,
                      color:           isDone ? AppColors.primary : AppColors.primary.withAlpha(180),
                      backgroundColor: AppColors.surfaceCard,
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        size: 14, color: AppColors.streak),
                    const SizedBox(width: 3),
                    Text(
                      '${habit.streakAtual} ${habit.streakAtual == 1 ? 'dia' : 'dias'} seguidos',
                      style: AppTextStyles.streakLabel,
                    ),
                    const Spacer(),
                    Text(
                      '${habit.subtarefasFeitas}/${habit.totalSubtarefas} feito',
                      style: isDone
                          ? AppTextStyles.streakLabel.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)
                          : AppTextStyles.streakLabel,
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onEdit,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.edit_outlined,
                            size: 16, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dismissBackground() => Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withAlpha(200),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 26),
      );

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Excluir "${habit.nome}"?'),
            content:
                const Text('Todo o histórico e streak serão apagados.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.error),
                child: const Text('Excluir'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

// ── Chip de período ─────────────────────────────────────────
class _PeriodChip extends StatelessWidget {
  final String period;
  const _PeriodChip({required this.period});

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (period) {
      'tarde' => ('Tarde', Icons.wb_sunny_outlined, const Color(0xFFF0B86A)),
      'noite' => ('Noite', Icons.nights_stay_outlined, const Color(0xFF7B9CCF)),
      _       => ('Manhã', Icons.wb_twilight_outlined, const Color(0xFF84C9A0)),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(label, style: AppTextStyles.periodChip.copyWith(color: color)),
      ],
    );
  }
}
