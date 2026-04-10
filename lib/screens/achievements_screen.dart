import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/achievement.dart';
import '../models/user_profile.dart';
import '../widgets/achievement_badge_widget.dart';

class AchievementsScreen extends StatefulWidget {
  final UserProfile? profile;
  const AchievementsScreen({super.key, this.profile});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  static const _tabs = [
    Tab(text: 'Todas'),
    Tab(icon: Icon(Icons.wb_twilight_outlined, size: 16), text: 'Manhã'),
    Tab(icon: Icon(Icons.wb_sunny_outlined, size: 16),    text: 'Tarde'),
    Tab(icon: Icon(Icons.nights_stay_outlined, size: 16), text: 'Noite'),
    Tab(icon: Icon(Icons.local_fire_department_rounded, size: 16), text: 'Geral'),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Map<AchievementCategory, Achievement> get _conquistas =>
      widget.profile?.conquistas ?? {};

  Achievement _getOrEmpty(AchievementCategory cat) =>
      _conquistas[cat] ?? Achievement(categoria: cat);

  List<Achievement> get _all => AchievementCategory.values
      .where((c) => c != AchievementCategory.perfeito)
      .map(_getOrEmpty)
      .toList();

  List<Achievement> _filtered(AchievementCategory cat) =>
      [_getOrEmpty(cat)];

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;

    return Column(
      children: [
        // ── Resumo de nível ──────────────────────────────
        if (profile != null)
          _LevelSummary(profile: profile),

        // ── Tabs ─────────────────────────────────────────
        Container(
          color: Theme.of(context).cardTheme.color,
          child: TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            tabAlignment:  TabAlignment.start,
            labelColor:    AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: _tabs,
          ),
        ),

        // ── Conteúdo ─────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _AchievementList(achievements: _all),
              _AchievementList(achievements: _filtered(AchievementCategory.manha)),
              _AchievementList(achievements: _filtered(AchievementCategory.tarde)),
              _AchievementList(achievements: _filtered(AchievementCategory.noite)),
              _AchievementList(achievements: _filtered(AchievementCategory.geral)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Lista de conquistas ─────────────────────────────────────
class _AchievementList extends StatelessWidget {
  final List<Achievement> achievements;
  const _AchievementList({required this.achievements});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Grid de badges no topo
        _BadgeGrid(achievements: achievements),
        const SizedBox(height: 20),

        // Cards detalhados
        ...achievements.map(
          (a) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AchievementCard(achievement: a),
          ),
        ),

        // Marcos do sistema
        const SizedBox(height: 8),
        _MilestonesRow(),
      ],
    );
  }
}

// ── Grid de badges grandes ──────────────────────────────────
class _BadgeGrid extends StatelessWidget {
  final List<Achievement> achievements;
  const _BadgeGrid({required this.achievements});

  @override
  Widget build(BuildContext context) {
    if (achievements.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: achievements
          .map((a) => AchievementBadgeWidget(
                achievement:    a,
                useImageAssets: true,
                size:           80,
                showLabel:      true,
                showProgress:   true,
              ))
          .toList(),
    );
  }
}

// ── Resumo do nível do usuário ──────────────────────────────
class _LevelSummary extends StatelessWidget {
  final UserProfile profile;
  const _LevelSummary({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = AppColors.themeForXp(profile.xpTotal);
    return Container(
      color: Theme.of(context).cardTheme.color,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: theme.surface,
            child: Text(
              profile.apelido.isNotEmpty
                  ? profile.apelido[0].toUpperCase()
                  : '?',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: theme.primary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nível ${profile.nivel} — ${profile.nomeDonivel}',
                  style: AppTextStyles.levelBadge,
                ),
                const SizedBox(height: 4),
                Text('${profile.xpTotal} XP total',
                    style: AppTextStyles.xpLabel),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value:           profile.progressoNivel,
                    minHeight:       5,
                    color:           theme.primary,
                    backgroundColor: AppColors.surfaceCard,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Linha de marcos do sistema ──────────────────────────────
class _MilestonesRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final milestones = Achievement.todos;
    final labels     = {
      5: 'Prata', 30: 'Ouro', 75: 'Platina',
      150: 'Esmeralda', 200: 'Diamante', 300: 'Mestre',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Marcos de dias', style: AppTextStyles.sectionLabel),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: milestones.map((m) {
            final label = labels[m];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color:  AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.surfaceHover),
              ),
              child: Text(
                label != null ? '$m dias · $label' : '$m dias',
                style: AppTextStyles.xpLabel,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
