import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/achievement_trail.dart';
import '../models/user_profile.dart';

/// ─────────────────────────────────────────────────────────────
/// AchievementsScreen — tela de conquistas redesenhada
///
/// Layout:
///   1. Header com o frame mais alto conquistado pelo usuário
///   2. Grid 2x4 com todas as 8 trilhas
///   3. Ao tocar em uma trilha → detalhe em bottom sheet
///
/// Progresso de cada trilha vem de UserProfile.trailProgress
/// Map<String, int> onde a chave é o AchievementTrail.id
/// ─────────────────────────────────────────────────────────────
class AchievementsScreen extends StatelessWidget {
  final UserProfile? profile;
  const AchievementsScreen({super.key, this.profile});

  /// Lê o progresso de uma trilha do perfil
  int _progress(String trailId) =>
      profile?.trailProgress[trailId] ?? 0;

  /// Tier mais alto conquistado em QUALQUER trilha
  AchievementTier? get _highestTier {
    AchievementTier? best;
    for (final trail in AchievementTrails.all) {
      final tier = trail.currentTier(_progress(trail.id));
      if (tier != null) {
        if (best == null || tier.index2 > best.index2) best = tier;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── Header fixo ────────────────────────────────────────
        SliverToBoxAdapter(child: _HeroHeader(highestTier: _highestTier, profile: profile)),

        // ── Título da seção ────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Text('Suas Trilhas', style: AppTextStyles.sectionLabel),
          ),
        ),

        // ── Grid 2 colunas das trilhas ─────────────────────────
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:     2,
              mainAxisSpacing:    10,
              crossAxisSpacing:   10,
              childAspectRatio:   0.82,
            ),
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final trail    = AchievementTrails.all[i];
                final progress = _progress(trail.id);
                return _TrailCard(
                  trail:    trail,
                  progress: progress,
                  onTap:    () => _showDetail(ctx, trail, progress),
                );
              },
              childCount: AchievementTrails.all.length,
            ),
          ),
        ),

        // ── Espaço para a nav bar ──────────────────────────────
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  void _showDetail(BuildContext context, AchievementTrail trail, int progress) {
    showModalBottomSheet(
      context:       context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TrailDetailSheet(trail: trail, progress: progress),
    );
  }
}

// ── Header hero com o maior frame conquistado ─────────────────
class _HeroHeader extends StatelessWidget {
  final AchievementTier? highestTier;
  final UserProfile?      profile;

  const _HeroHeader({this.highestTier, this.profile});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tier   = highestTier;

    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceHover, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Frame do tier mais alto (ou cadeado)
          _TierDisplay(tier: tier, size: 80),
          const SizedBox(width: 18),

          // Info do usuário
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.apelido ?? 'Aventureiro',
                  style: const TextStyle(
                    fontSize:   20,
                    fontWeight: FontWeight.w800,
                    color:      AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                if (tier != null) ...[
                  Row(children: [
                    Image.asset(
                      tier.assetPath,
                      width: 18, height: 18,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Patente: ${tier.label}',
                      style: TextStyle(
                        fontSize:   13,
                        fontWeight: FontWeight.w700,
                        color:      Color(tier.colorValue),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Text(
                    '${_conquistas()} trilha${_conquistas() == 1 ? '' : 's'} desbloqueada${_conquistas() == 1 ? '' : 's'}',
                    style: AppTextStyles.xpLabel,
                  ),
                ] else ...[
                  Text(
                    'Nenhuma patente ainda',
                    style: AppTextStyles.xpLabel,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Complete hábitos para ganhar sua primeira!',
                    style: AppTextStyles.xpLabel.copyWith(
                        color: AppColors.primary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _conquistas() {
    int count = 0;
    for (final t in AchievementTrails.all) {
      if (t.currentTier(profile?.trailProgress[t.id] ?? 0) != null) count++;
    }
    return count;
  }
}

// ── Card de trilha no grid ─────────────────────────────────────
class _TrailCard extends StatelessWidget {
  final AchievementTrail trail;
  final int              progress;
  final VoidCallback     onTap;

  const _TrailCard({
    required this.trail,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentTier = trail.currentTier(progress);
    final nextLevel   = trail.nextLevel(progress);
    final pct         = trail.progressToNext(progress);
    final isLocked    = currentTier == null;
    final isMaxed     = trail.isMaxed(progress);
    final tierColor   = currentTier != null
        ? Color(currentTier.colorValue) : AppColors.textHint;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Conteúdo
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Frame PNG central
                  Expanded(
                    child: Center(
                      child: _TierDisplay(
                        tier:   currentTier,
                        size:   72,
                        locked: isLocked,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Nome da trilha
                  Text(
                    '${trail.emoji} ${trail.name}',
                    style: const TextStyle(
                      fontSize:   12,
                      fontWeight: FontWeight.w700,
                      color:      AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines:  1,
                    overflow:  TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),

                  // Tier atual ou "Bloqueado"
                  Text(
                    isMaxed    ? '👑 Maximizado!'
                    : isLocked ? 'Bloqueado'
                               : currentTier!.label,
                    style: TextStyle(
                      fontSize:   10,
                      fontWeight: FontWeight.w600,
                      color:      isMaxed ? AppColors.streak : tierColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Barra de progresso
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value:           pct,
                      minHeight:       5,
                      color:           isLocked ? AppColors.textHint : tierColor,
                      backgroundColor: AppColors.surfaceCard,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Progresso em texto
                  Text(
                    isMaxed
                        ? '${progress} / ${progress}'
                        : nextLevel != null
                            ? '$progress / ${nextLevel.threshold}'
                            : '',
                    style: AppTextStyles.xpLabel,
                  ),
                ],
              ),
            ),

            // Selo "NOVO" se acabou de desbloquear o primeiro tier
            if (currentTier == AchievementTier.prata && progress < 8)
              Positioned(
                top: 6, right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color:        AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('NOVO',
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Exibição do frame PNG (com fallback e estado bloqueado) ────
class _TierDisplay extends StatelessWidget {
  final AchievementTier? tier;
  final double           size;
  final bool             locked;

  const _TierDisplay({this.tier, required this.size, this.locked = false});

  @override
  Widget build(BuildContext context) {
    if (locked || tier == null) {
      // Estado bloqueado — círculo cinza com cadeado
      return Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width:       size,
            height:      size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceCard,
              border: Border.all(color: AppColors.surfaceHover, width: 2),
            ),
          ),
          Icon(Icons.lock_rounded, size: size * 0.32, color: AppColors.textHint),
        ],
      );
    }

    return SizedBox(
      width:  size,
      height: size,
      child:  Image.asset(
        tier!.assetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) {
          // Fallback se o PNG não existir ainda
          return Container(
            width:  size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(tier!.colorValue).withAlpha(30),
              border: Border.all(
                  color: Color(tier!.colorValue), width: 2.5),
            ),
            alignment: Alignment.center,
            child: Text(
              _emoji(tier!),
              style: TextStyle(fontSize: size * 0.36),
            ),
          );
        },
      ),
    );
  }

  String _emoji(AchievementTier t) {
    switch (t) {
      case AchievementTier.prata:     return '🌱';
      case AchievementTier.ouro:      return '🌿';
      case AchievementTier.platina:   return '🔮';
      case AchievementTier.esmeralda: return '💚';
      case AchievementTier.diamante:  return '💎';
      case AchievementTier.mestre:    return '👑';
    }
  }
}

// ── Bottom sheet de detalhe da trilha ─────────────────────────
class _TrailDetailSheet extends StatelessWidget {
  final AchievementTrail trail;
  final int              progress;

  const _TrailDetailSheet({required this.trail, required this.progress});

  @override
  Widget build(BuildContext context) {
    final currentTier = trail.currentTier(progress);
    final nextLevel   = trail.nextLevel(progress);
    final isMaxed     = trail.isMaxed(progress);

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize:     0.4,
      maxChildSize:     0.92,
      expand:           false,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color:        Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 10),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceHover,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header do detalhe
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                _TierDisplay(tier: currentTier, size: 64),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${trail.emoji} ${trail.name}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(trail.description, style: AppTextStyles.xpLabel),
                    const SizedBox(height: 6),
                    Text(
                      currentTier != null
                          ? 'Patente atual: ${currentTier.label}'
                          : 'Ainda não desbloqueado',
                      style: TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w700,
                        color:      currentTier != null
                            ? Color(currentTier.colorValue)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                )),
              ]),
            ),
            const SizedBox(height: 20),

            // Progresso geral
            if (!isMaxed && nextLevel != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Progresso para ${nextLevel.tier.label}',
                            style: AppTextStyles.sectionLabel),
                        Text('$progress / ${nextLevel.threshold}',
                            style: AppTextStyles.levelBadge),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value:           trail.progressToNext(progress),
                        minHeight:       8,
                        color:           Color(nextLevel.tier.colorValue),
                        backgroundColor: AppColors.surfaceCard,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Todos os 6 tiers
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Text('Todos os níveis', style: AppTextStyles.sectionLabel),
                  const SizedBox(height: 10),
                  ...trail.levels.map((lvl) {
                    final earned  = progress >= lvl.threshold;
                    final isCurr  = currentTier == lvl.tier;
                    final tierCol = Color(lvl.tier.colorValue);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: earned
                            ? tierCol.withAlpha(15)
                            : AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isCurr ? tierCol : AppColors.surfaceHover,
                          width: isCurr ? 1.5 : 0.5,
                        ),
                      ),
                      child: Row(children: [
                        // Frame mini
                        _TierDisplay(
                          tier:   earned ? lvl.tier : null,
                          size:   44,
                          locked: !earned,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text(lvl.tier.label,
                                  style: TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w700,
                                      color: earned ? tierCol : AppColors.textHint)),
                              if (isCurr) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: tierCol.withAlpha(30),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text('Atual',
                                      style: TextStyle(fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: tierCol)),
                                ),
                              ],
                            ]),
                            const SizedBox(height: 3),
                            Text(lvl.description,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: earned
                                        ? AppColors.textSecondary
                                        : AppColors.textHint)),
                          ],
                        )),
                        // Check ou lock
                        Icon(
                          earned ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
                          color: earned ? tierCol : AppColors.textHint,
                          size:  20,
                        ),
                      ]),
                    );
                  }),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
