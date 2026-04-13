import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/painters/week_chart_painter.dart';
import '../core/utils/date_utils.dart';
import '../models/habit.dart';
import '../services/storage_service.dart';
import 'habit_form_screen.dart';

class HabitDetailScreen extends StatefulWidget {
  final Habit habit;
  const HabitDetailScreen({super.key, required this.habit});

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  late Habit _habit;

  @override
  void initState() {
    super.initState();
    _habit = widget.habit;
  }

  List<double> get _weekData {
    final keys = HabitDateUtils.lastWeekKeys();
    return keys.map((k) => _habit.progressoNaData(k)).toList();
  }

  Future<void> _editar() async {
    final editado = await Navigator.of(context).push<Habit>(
      MaterialPageRoute(
        builder: (_) => HabitFormScreen(habitParaEditar: _habit),
      ),
    );
    if (editado != null) {
      await StorageService.instance.saveHabitLocal(editado);
      setState(() => _habit = editado);
    }
  }

  Future<void> _deletar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Excluir "${_habit.nome}"?'),
        content: const Text(
          'Todo o histórico e streak serão perdidos. Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await StorageService.instance.deleteHabitLocal(_habit.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekData = _weekData;
    final totalDias = _habit.historicoConclusao.values
        .where((v) => v >= 1.0)
        .length;
    final mediaSemana = weekData.isEmpty
        ? 0.0
        : weekData.fold(0.0, (a, b) => a + b) / weekData.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_habit.nome, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: _editar),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
            ),
            onPressed: _deletar,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Cabeçalho ────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _habit.icone,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _habit.nome,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _InfoChip(
                              icon: Icons.wb_twilight_outlined,
                              label: _periodoLabel(_habit.periodo),
                            ),
                            const SizedBox(width: 8),
                            _InfoChip(
                              icon: Icons.repeat_rounded,
                              label: _frequenciaLabel(_habit.frequencia),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Streak + Estatísticas ─────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.local_fire_department_rounded,
                  color: AppColors.streak,
                  value: '${_habit.streakAtual}',
                  label: 'Dias seguidos',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.emoji_events_outlined,
                  color: AppColors.primary,
                  value: '${_habit.melhorStreak}',
                  label: 'Melhor streak',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.blueAccent,
                  value: '$totalDias',
                  label: 'Dias completos',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Gráfico 7 dias ────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Últimos 7 dias', style: AppTextStyles.sectionLabel),
                      Text(
                        'Média ${(mediaSemana * 100).round()}%',
                        style: AppTextStyles.levelBadge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  WeekChart(data: weekData, height: 90),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Mini tarefas ──────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mini tarefas', style: AppTextStyles.sectionLabel),
                  const SizedBox(height: 8),
                  ..._habit.miniTarefas.map(
                    (s) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.radio_button_unchecked,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(s.nome, style: AppTextStyles.subtaskLabel),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Notificação ───────────────────────────────────
          Card(
            child: ListTile(
              leading: Icon(
                _habit.notificacaoAtiva
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
                color: _habit.notificacaoAtiva
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              title: Text(
                _habit.notificacaoAtiva
                    ? 'Notificação ativa'
                    : 'Notificação desativada',
                style: AppTextStyles.habitName,
              ),
              subtitle: _habit.notificacaoAtiva
                  ? Text(
                      'Todos os dias às ${_habit.notificacaoHora}',
                      style: AppTextStyles.xpLabel,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),

          // ── Botões ────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _editar,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _deletar,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Excluir'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _periodoLabel(String p) {
    switch (p) {
      case 'tarde':
        return 'Tarde';
      case 'noite':
        return 'Noite';
      default:
        return 'Manhã';
    }
  }

  String _frequenciaLabel(String f) {
    switch (f) {
      case 'seg-sex':
        return 'Seg–Sex';
      default:
        return 'Diário';
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.xpLabel,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: AppColors.textSecondary),
      const SizedBox(width: 3),
      Text(label, style: AppTextStyles.xpLabel),
    ],
  );
}
