import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/painters/week_chart_painter.dart';
import '../core/utils/date_utils.dart';
import '../models/habit.dart';

class ProgressScreen extends StatefulWidget {
  final List<Habit> habits;
  const ProgressScreen({super.key, required this.habits});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── Cálculos ───────────────────────────────────────────────
  List<double> get _weekGeral {
    final keys = HabitDateUtils.lastWeekKeys();
    if (widget.habits.isEmpty) return List.filled(7, 0.0);
    return keys.map((k) {
      final vals = widget.habits.map((h) => h.progressoNaData(k)).toList();
      return vals.fold(0.0, (a, b) => a + b) / vals.length;
    }).toList();
  }

  int get _totalAtivos     => widget.habits.where((h) => h.ativoHoje).length;
  int get _totalCompletos  => widget.habits.where((h) => h.ativoHoje && h.completoHoje).length;
  double get _taxaHoje     => _totalAtivos == 0 ? 0 : _totalCompletos / _totalAtivos;

  int get _streakMaxAtual  => widget.habits.isEmpty ? 0
      : widget.habits.map((h) => h.streakAtual).fold(0, (a, b) => a > b ? a : b);
  int get _melhorStreak    => widget.habits.isEmpty ? 0
      : widget.habits.map((h) => h.melhorStreak).fold(0, (a, b) => a > b ? a : b);

  double get _mediaSemana  {
    final w = _weekGeral;
    if (w.isEmpty) return 0;
    return w.fold(0.0, (a, b) => a + b) / w.length;
  }

  int get _diasPerfeitosTotal {
    final sets = widget.habits.map((h) =>
        h.historicoConclusao.entries
            .where((e) => e.value >= 1.0)
            .map((e) => e.key)
            .toSet()
    ).toList();
    if (sets.isEmpty) return 0;
    return sets.reduce((a, b) => a.intersection(b)).length;
  }

  String get _melhorDiaSemana {
    final Map<int, List<double>> byDay = {1:[], 2:[], 3:[], 4:[], 5:[], 6:[], 7:[]};
    for (final h in widget.habits) {
      for (final e in h.historicoConclusao.entries) {
        final day = DateTime.parse(e.key).weekday;
        byDay[day]!.add(e.value);
      }
    }
    const names = ['', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    double best  = -1;
    int    bestD = 0;
    for (final entry in byDay.entries) {
      if (entry.value.isEmpty) continue;
      final avg = entry.value.fold(0.0, (a, b) => a + b) / entry.value.length;
      if (avg > best) { best = avg; bestD = entry.key; }
    }
    return bestD == 0 ? '—' : names[bestD];
  }

  // ── Consistência dos últimos 30 dias ───────────────────────
  List<_DayDot> get _last30Days {
    final result = <_DayDot>[];
    final today  = DateTime.now();
    for (int i = 29; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final key  = HabitDateUtils.toKey(date);
      final vals = widget.habits.map((h) => h.progressoNaData(key)).toList();
      final avg  = vals.isEmpty ? 0.0 : vals.fold(0.0, (a, b) => a + b) / vals.length;
      result.add(_DayDot(date: date, value: avg));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.habits.isEmpty) return _EmptyProgress();

    return Column(
      children: [
        // Tabs
        Container(
          color: Theme.of(context).cardTheme.color,
          child: TabBar(
            controller:          _tabCtrl,
            labelColor:          AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor:      AppColors.primary,
            tabs: const [
              Tab(text: 'Visão Geral'),
              Tab(text: 'Por Hábito'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _OverviewTab(screen: this),
              _ByHabitTab(habits: widget.habits),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Tab: Visão Geral ────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final _ProgressScreenState screen;
  const _OverviewTab({required this.screen});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
      children: [
        // ── 4 cards de estatísticas ───────────────────────
        Text('Estatísticas de hoje', style: AppTextStyles.sectionLabel),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount:  2,
          crossAxisSpacing: 10,
          mainAxisSpacing:  10,
          childAspectRatio: 2.0,
          shrinkWrap: true,
          physics:    const NeverScrollableScrollPhysics(),
          children: [
            _StatTile(
              icon:  Icons.check_circle_outline_rounded,
              color: AppColors.primary,
              value: '${screen._totalCompletos}/${screen._totalAtivos}',
              label: 'Concluídos',
            ),
            _StatTile(
              icon:  Icons.percent_rounded,
              color: AppColors.blueAccent,
              value: '${(screen._taxaHoje * 100).round()}%',
              label: 'Taxa do dia',
            ),
            _StatTile(
              icon:  Icons.local_fire_department_rounded,
              color: AppColors.streak,
              value: '${screen._streakMaxAtual}d',
              label: 'Streak atual',
            ),
            _StatTile(
              icon:  Icons.emoji_events_outlined,
              color: const Color(0xFFD4AF37),
              value: '${screen._melhorStreak}d',
              label: 'Melhor streak',
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── 4 cards de análise ────────────────────────────
        Text('Análise geral', style: AppTextStyles.sectionLabel),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount:  2,
          crossAxisSpacing: 10,
          mainAxisSpacing:  10,
          childAspectRatio: 2.0,
          shrinkWrap: true,
          physics:    const NeverScrollableScrollPhysics(),
          children: [
            _StatTile(
              icon:  Icons.trending_up_rounded,
              color: AppColors.primary,
              value: '${(screen._mediaSemana * 100).round()}%',
              label: 'Média semanal',
            ),
            _StatTile(
              icon:  Icons.star_outline_rounded,
              color: const Color(0xFFD4AF37),
              value: '${screen._diasPerfeitosTotal}',
              label: 'Dias perfeitos',
            ),
            _StatTile(
              icon:  Icons.calendar_today_rounded,
              color: AppColors.blueAccent,
              value: screen._melhorDiaSemana,
              label: 'Melhor dia',
            ),
            _StatTile(
              icon:  Icons.format_list_numbered_rounded,
              color: AppColors.textSecondary,
              value: '${screen.widget.habits.length}',
              label: 'Hábitos ativos',
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Gráfico semanal ───────────────────────────────
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
                      'Melhor: ${screen._melhorStreak} dias',
                      style: AppTextStyles.xpLabel,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                WeekChart(data: screen._weekGeral, height: 110),
                const SizedBox(height: 8),
                // Legenda
                Row(children: [
                  _LegendDot(color: AppColors.primary,  label: 'Completo'),
                  const SizedBox(width: 12),
                  _LegendDot(color: AppColors.streak,   label: 'Parcial'),
                  const SizedBox(width: 12),
                  _LegendDot(color: AppColors.surfaceHover, label: 'Não feito'),
                ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Mapa de consistência (últimos 30 dias) ────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Consistência — 30 dias', style: AppTextStyles.sectionLabel),
                const SizedBox(height: 12),
                _ConsistencyGrid(days: screen._last30Days),
                const SizedBox(height: 10),
                Row(children: [
                  _LegendDot(color: AppColors.surfaceCard, label: 'Nenhum'),
                  const SizedBox(width: 10),
                  _LegendDot(color: AppColors.primary.withAlpha(100), label: 'Parcial'),
                  const SizedBox(width: 10),
                  _LegendDot(color: AppColors.primary, label: 'Completo'),
                ]),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Tab: Por hábito ────────────────────────────────────────
class _ByHabitTab extends StatelessWidget {
  final List<Habit> habits;
  const _ByHabitTab({required this.habits});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
      children: habits
          .map((h) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _HabitProgressCard(habit: h),
              ))
          .toList(),
    );
  }
}

// ── Card de estatística ────────────────────────────────────
class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   value, label;

  const _StatTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width:  38, height: 38,
                decoration: BoxDecoration(
                  color:        color.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment:  MainAxisAlignment.center,
                  children: [
                    Text(value,
                        style: TextStyle(
                            fontSize:   18,
                            fontWeight: FontWeight.w800,
                            color:      color)),
                    Text(label, style: AppTextStyles.xpLabel,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

// ── Card de progresso por hábito ───────────────────────────
class _HabitProgressCard extends StatelessWidget {
  final Habit habit;
  const _HabitProgressCard({required this.habit});

  List<double> get _weekData {
    final keys = HabitDateUtils.lastWeekKeys();
    return keys.map((k) => habit.progressoNaData(k)).toList();
  }

  double get _media {
    final d = _weekData;
    return d.isEmpty ? 0 : d.fold(0.0, (a, b) => a + b) / d.length;
  }

  int get _totalDias =>
      habit.historicoConclusao.values.where((v) => v >= 1.0).length;

  @override
  Widget build(BuildContext context) {
    final media  = _media;
    final isDone = habit.completoHoje;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(children: [
              Text(habit.icone, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(habit.nome,
                    style: AppTextStyles.habitName,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              if (isDone)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('✓ Hoje',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                ),
            ]),
            const SizedBox(height: 10),

            // Mini stats
            Row(children: [
              _MiniStat(
                  icon:  Icons.local_fire_department_rounded,
                  color: AppColors.streak,
                  value: '${habit.streakAtual}d',
                  label: 'Streak'),
              const SizedBox(width: 14),
              _MiniStat(
                  icon:  Icons.emoji_events_outlined,
                  color: const Color(0xFFD4AF37),
                  value: '${habit.melhorStreak}d',
                  label: 'Melhor'),
              const SizedBox(width: 14),
              _MiniStat(
                  icon:  Icons.check_circle_outline_rounded,
                  color: AppColors.primary,
                  value: '$_totalDias',
                  label: 'Dias 100%'),
              const SizedBox(width: 14),
              _MiniStat(
                  icon:  Icons.trending_up_rounded,
                  color: AppColors.blueAccent,
                  value: '${(media * 100).round()}%',
                  label: 'Média 7d'),
            ]),
            const SizedBox(height: 10),

            // Gráfico
            WeekChart(
              data:         _weekData,
              height:       64,
              barColor:     AppColors.primary,
              partialColor: AppColors.streak,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   value, label;

  const _MiniStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      Text(label, style: AppTextStyles.xpLabel),
    ],
  );
}

// ── Grid de consistência 30 dias ───────────────────────────
class _ConsistencyGrid extends StatelessWidget {
  final List<_DayDot> days;
  const _ConsistencyGrid({required this.days});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: days.map((d) {
        Color color;
        if (d.value <= 0)       color = AppColors.surfaceCard;
        else if (d.value < 1.0) color = AppColors.primary.withAlpha(100);
        else                    color = AppColors.primary;

        final isToday = HabitDateUtils.isToday(d.date);
        return Tooltip(
          message: '${HabitDateUtils.friendlyDate(d.date)}: ${(d.value * 100).round()}%',
          child: Container(
            width:  22, height: 22,
            decoration: BoxDecoration(
              color:        color,
              borderRadius: BorderRadius.circular(5),
              border:       isToday
                  ? Border.all(color: AppColors.primary, width: 1.5)
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DayDot {
  final DateTime date;
  final double   value;
  const _DayDot({required this.date, required this.value});
}

class _LegendDot extends StatelessWidget {
  final Color  color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 10, height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 4),
      Text(label, style: AppTextStyles.xpLabel),
    ],
  );
}

class _EmptyProgress extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('📊', style: TextStyle(fontSize: 52)),
        const SizedBox(height: 14),
        Text('Nenhum dado ainda', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text('Crie hábitos para ver seu progresso.', style: AppTextStyles.greeting),
      ],
    ),
  );
}
