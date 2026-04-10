import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/painters/week_chart_painter.dart';
import '../core/utils/date_utils.dart';
import '../models/habit.dart';

class ProgressScreen extends StatelessWidget {
  final List<Habit> habits;
  const ProgressScreen({super.key, required this.habits});

  // ── Dados calculados ───────────────────────────────────────
  List<double> get _weekGeral {
    final keys = HabitDateUtils.lastWeekKeys();
    if (habits.isEmpty) return List.filled(7, 0.0);

    return keys.map((k) {
      final values = habits.map((h) => h.progressoNaData(k)).toList();
      return values.isEmpty
          ? 0.0
          : values.fold(0.0, (a, b) => a + b) / values.length;
    }).toList();
  }

  int get _totalHojeCompletos =>
      habits.where((h) => h.ativoHoje && h.completoHoje).length;

  int get _totalHojeAtivos =>
      habits.where((h) => h.ativoHoje).length;

  double get _taxaHoje =>
      _totalHojeAtivos == 0 ? 0 : _totalHojeCompletos / _totalHojeAtivos;

  int get _melhorStreakGlobal =>
      habits.isEmpty ? 0 : habits.map((h) => h.melhorStreak).reduce((a, b) => a > b ? a : b);

  int get _streakAtualGlobal {
    if (habits.isEmpty) return 0;
    return habits.map((h) => h.streakAtual).fold(0, (a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    if (habits.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📊', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('Nenhum hábito para analisar',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Crie hábitos para ver seu progresso.',
                style: AppTextStyles.greeting),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Cards resumo do dia ────────────────────────────
        Text('Hoje', style: AppTextStyles.sectionLabel),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: _StatCard(
              label: 'Concluídos',
              value: '$_totalHojeCompletos / $_totalHojeAtivos',
              icon:  Icons.check_circle_outline_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              label: 'Taxa do dia',
              value: '${(_taxaHoje * 100).round()}%',
              icon:  Icons.percent_rounded,
              color: AppColors.blueAccent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              label: 'Maior streak',
              value: '$_streakAtualGlobal dias',
              icon:  Icons.local_fire_department_rounded,
              color: AppColors.streak,
            ),
          ),
        ]),
        const SizedBox(height: 16),

        // ── Gráfico geral da semana ────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Média semanal', style: AppTextStyles.sectionLabel),
                    Text(
                      'Melhor: $_melhorStreakGlobal dias',
                      style: AppTextStyles.xpLabel,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                WeekChart(data: _weekGeral, height: 100),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Progresso por hábito ───────────────────────────
        Text('Por hábito', style: AppTextStyles.sectionLabel),
        const SizedBox(height: 8),
        ...habits.map((h) => _HabitProgressTile(habit: h)),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Card de estatística ─────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;
  final Color    color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 5),
              Text(value,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: color),
                  textAlign: TextAlign.center),
              const SizedBox(height: 2),
              Text(label,
                  style: AppTextStyles.xpLabel,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

// ── Linha de progresso por hábito ──────────────────────────
class _HabitProgressTile extends StatelessWidget {
  final Habit habit;
  const _HabitProgressTile({required this.habit});

  List<double> get _weekData {
    final keys = HabitDateUtils.lastWeekKeys();
    return keys.map((k) => habit.progressoNaData(k)).toList();
  }

  double get _media {
    final data = _weekData;
    if (data.isEmpty) return 0;
    return data.fold(0.0, (a, b) => a + b) / data.length;
  }

  @override
  Widget build(BuildContext context) {
    final media = _media;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(habit.icone, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(habit.nome,
                      style: AppTextStyles.habitName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        size: 13, color: AppColors.streak),
                    const SizedBox(width: 2),
                    Text('${habit.streakAtual}d',
                        style: AppTextStyles.streakBadge),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            WeekChart(
              data:   _weekData,
              height: 60,
              barColor:     AppColors.primary,
              partialColor: AppColors.streak,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Média 7 dias: ${(media * 100).round()}%',
                    style: AppTextStyles.xpLabel),
                Text(
                  habit.completoHoje ? '✓ Completo hoje' : 'Em andamento',
                  style: AppTextStyles.xpLabel.copyWith(
                    color: habit.completoHoje
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
