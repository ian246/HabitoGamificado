import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/achievement_trail.dart';
import '../models/user_profile.dart';

class AchievementsScreen extends StatelessWidget {
  final UserProfile? profile;

  const AchievementsScreen({super.key, this.profile});

  int _progress(String id) => profile?.trailProgress[id] ?? 0;

  AchievementTier? get _highestTier {
    AchievementTier? best;
    for (final trail in AchievementTrails.all) {
      final tier = trail.currentTier(_progress(trail.id));
      if (tier != null && (best == null || tier.index2 > best.index2)) {
        best = tier;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final allTrails = AchievementTrails.all;

    // 1. Concluídas (têm ao menos um tier) → da patente maior para menor
    final completed =
        allTrails.where((t) => t.currentTier(_progress(t.id)) != null).toList()
          ..sort((a, b) {
            final tierA = a.currentTier(_progress(a.id))!.index2;
            final tierB = b.currentTier(_progress(b.id))!.index2;
            return tierB.compareTo(tierA); // decrescente
          });

    // 2. Em andamento (sem tier ainda, mas com algum progresso) → mais próxima de concluir primeiro
    final inProgress =
        allTrails
            .where(
              (t) =>
                  t.currentTier(_progress(t.id)) == null && _progress(t.id) > 0,
            )
            .toList()
          ..sort((a, b) {
            final pctA = a.progressToNext(_progress(a.id));
            final pctB = b.progressToNext(_progress(b.id));
            return pctB.compareTo(pctA); // decrescente: mais próxima primeiro
          });

    // 3. Não iniciadas (progresso == 0)
    final notStarted = allTrails.where((t) => _progress(t.id) == 0).toList();

    final trails = [...completed, ...inProgress, ...notStarted];

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // 1. HERO SECTION
        SliverToBoxAdapter(
          child: _HeroSection(tier: _highestTier, profile: profile),
        ),

        // 2. SEÇÃO DE TRILHAS
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          sliver: SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sua Jornada', style: AppTextStyles.sectionLabel),
                Text(
                  '${completed.length}/${allTrails.length}',
                  style: AppTextStyles.xpLabel.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 3. GRID DE TRILHAS
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.85,
            ),
            delegate: SliverChildBuilderDelegate((ctx, i) {
              final trail = trails[i];
              final progress = _progress(trail.id);

              return _TrailCardRefined(
                trail: trail,
                progress: progress,
                onTap: () => _openDetail(ctx, trail, progress),
              );
            }, childCount: trails.length),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  void _openDetail(BuildContext ctx, AchievementTrail trail, int progress) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TrailDetailSheet(trail: trail, progress: progress),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final AchievementTier? tier;
  final UserProfile? profile;

  const _HeroSection({this.tier, this.profile});

  @override
  Widget build(BuildContext context) {
    final color = tier != null ? Color(tier!.colorValue) : AppColors.textHint;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
      color: Colors.transparent,
      child: Column(
        children: [
          // Frame Central com Glow
          Stack(
            alignment: Alignment.center,
            children: [
              if (tier != null)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 40,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              _TierDisplay(tier: tier, size: 110),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            profile?.apelido ?? 'Aventureiro',
            style: AppTextStyles.sectionLabel.copyWith(
              fontSize: 22,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tier != null
                ? 'Patente: ${tier!.label}'
                : 'Em busca da primeira conquista',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrailCardRefined extends StatelessWidget {
  final AchievementTrail trail;
  final int progress;
  final VoidCallback onTap;

  const _TrailCardRefined({
    required this.trail,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tier = trail.currentTier(progress);
    final currentLevel = trail.currentLevel(progress);
    final next = trail.nextLevel(progress);
    final pct = trail.progressToNext(progress);
    final isMaxed = trail.isMaxed(progress);
    final color = tier != null ? Color(tier.colorValue) : AppColors.textHint;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color:
              Theme.of(context).cardTheme.color ??
              Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: tier != null
                ? color.withOpacity(0.35)
                : Theme.of(context).dividerColor,
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Expanded(
                child: _TierDisplay(tier: tier, size: 60, locked: tier == null),
              ),
              const SizedBox(height: 6),
              // Nome da trilha
              Text(
                '${trail.emoji} ${trail.name}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // Título da patente atual (tag estilizada)
              if (currentLevel != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.4), width: 1),
                  ),
                  child: Text(
                    currentLevel.title,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else
                const SizedBox(height: 10),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  color: color,
                  backgroundColor: AppColors.surfaceHover,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isMaxed ? "CONCLUÍDO" : '${progress}/${next?.threshold ?? ""}',
                style: AppTextStyles.xpLabel.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TierDisplay extends StatelessWidget {
  final AchievementTier? tier;
  final double size;
  final bool locked;

  const _TierDisplay({this.tier, required this.size, this.locked = false});

  @override
  Widget build(BuildContext context) {
    if (locked || tier == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceHover.withOpacity(0.5),
        ),
        child: Icon(
          Icons.lock_outline_rounded,
          color: AppColors.textHint,
          size: size * 0.4,
        ),
      );
    }

    return Image.asset(
      tier!.assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          Icon(Icons.stars, color: Color(tier!.colorValue), size: size),
    );
  }
}

// Nota: O _TrailDetailSheet foi mantido conforme sua versão 2,
// que já estava excelente com DraggableScrollableSheet e a lista de níveis.

class _TrailDetailSheet extends StatelessWidget {
  final AchievementTrail trail;
  final int progress;

  const _TrailDetailSheet({required this.trail, required this.progress});

  @override
  Widget build(BuildContext context) {
    final currentTier = trail.currentTier(progress);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceHover,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Header do Detail
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _TierDisplay(tier: currentTier, size: 70),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${trail.emoji} ${trail.name}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(trail.description, style: AppTextStyles.xpLabel),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Lista de Níveis
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: trail.levels.length,
                itemBuilder: (ctx, i) {
                  final lvl = trail.levels[i];
                  final earned = progress >= lvl.threshold;
                  final isCurr = currentTier == lvl.tier;
                  final color = Color(lvl.tier.colorValue);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: earned
                          ? color.withOpacity(0.1)
                          : AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCurr
                            ? color
                            : (earned
                                  ? color.withOpacity(0.3)
                                  : AppColors.surfaceHover),
                        width: isCurr ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        _TierDisplay(
                          tier: earned ? lvl.tier : null,
                          size: 40,
                          locked: !earned,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                earned ? lvl.title : lvl.tier.label,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: earned ? color : AppColors.textHint,
                                ),
                              ),
                              if (earned)
                                Text(
                                  lvl.tier.label,
                                  style: AppTextStyles.xpLabel.copyWith(
                                    fontSize: 10,
                                    color: color.withOpacity(0.7),
                                  ),
                                ),
                              Text(
                                lvl.description,
                                style: AppTextStyles.xpLabel.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (earned)
                          Icon(Icons.check_circle, color: color, size: 20),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
