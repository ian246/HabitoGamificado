import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/achievement.dart';
import '../models/achievement_trail.dart';
import '../models/user_profile.dart';

/// Faixa de XP exibida logo abaixo da AppBar na HomeScreen
class XpHeader extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback? onRefresh;

  const XpHeader({super.key, required this.profile, this.onRefresh});

  String _getFramePath(int level) {
    final currentFrame = AppColors.frameForLevel(level);
    return 'assets/frames/${currentFrame.name.toLowerCase()}_frame.png';
  }

  /// Retorna o caminho do asset de conquista (menor, secundário)
  String? _getConquestPath(
    ({AchievementTrail trail, TrailLevel level})? activeTitle,
  ) {
    if (activeTitle == null) return null;
    final tierName = activeTitle.level.tier.label.toLowerCase();
    return 'assets/conquests/conquista_$tierName.png';
  }

  (int level, String name) _getNextRankTarget(int currentLevel) {
    if (currentLevel < 5) return (5, 'Ouro');
    if (currentLevel < 15) return (15, 'Platina');
    if (currentLevel < 30) return (30, 'Esmeralda');
    if (currentLevel < 50) return (50, 'Diamante');
    if (currentLevel < 80) return (80, 'Mestre');
    return (-1, '');
  }

  String _articleForLevel(String name) {
    final n = name.toLowerCase();
    if (n == 'árvore' || n == 'estrelas' || n == 'estrela' || n == 'floresta')
      return 'da';
    if (n == 'muda') return 'da';
    return 'do';
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppColors.themeForXp(profile.xpTotal);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final framePath = _getFramePath(profile.nivel);
    final (nextRankLevel, nextRankName) = _getNextRankTarget(profile.nivel);

    // XP Calculations
    final xpNextTarget = theme.xpForNext;
    final progress = theme.progressTo(profile.xpTotal);

    // Próximo nível
    final themes = AppColors.levelThemes;
    final currentThemeIdx = themes.indexWhere((t) => t.level == profile.nivel);
    final nextLabel =
        currentThemeIdx != -1 && currentThemeIdx < themes.length - 1
        ? themes[currentThemeIdx + 1].name
        : 'Mestre';

    final activeTitle = profile.activeTitle;
    final conquestPath = _getConquestPath(activeTitle);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2420) : const Color(0xFFF2F9F5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── ZONA DE AVATARES ────────────────────────────────
          _AvatarZone(
            framePath: framePath,
            conquestPath: conquestPath,
            levelColor: theme.primary,
            isDark: isDark,
          ),

          const SizedBox(width: 14),

          // ── ZONA DE INFORMAÇÕES ─────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Linha 1: Nível + botão refresh
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        'Nível ${profile.nivel} — ${profile.nomeDonivel}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white.withOpacity(0.92)
                              : AppColors.textPrimary,
                          letterSpacing: -0.4,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),

                // Linha 2: Título de conquista (se existir) — discreto, inline
                if (activeTitle != null) ...[
                  const SizedBox(height: 3),
                  _InlineTitleChip(activeTitle: activeTitle),
                ],

                // Linha 3: Próximo rank (se não for max)
                if (nextRankLevel > 0) ...[
                  const SizedBox(height: 4),
                  _NextRankRow(
                    nextRankName: nextRankName,
                    targetLevel: nextRankLevel,
                    isDark: isDark,
                  ),
                ],

                const SizedBox(height: 10),

                // Linha 4: Label do caminho de XP + contador
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        'Caminho ${_articleForLevel(nextLabel)} $nextLabel',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: theme.primary.withOpacity(0.9),
                          letterSpacing: 0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${profile.xpTotal} / $xpNextTarget XP',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white38
                            : AppColors.textSecondary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                // Linha 5: Barra de XP
                _XpBar(
                  progress: progress,
                  primaryColor: theme.primary,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── ZONA DE AVATARES ─────────────────────────────────────────────────────────
//
// Hierarquia visual:
//   • Frame de ranking  → DOMINANTE (78px, frente, centro)
//   • Patente conquista → secundário (38px, atrás, canto inf. esquerdo)
//     └─ só aparece se o usuário tiver uma conquista desbloqueada

class _AvatarZone extends StatelessWidget {
  final String framePath;
  final String? conquestPath;
  final Color levelColor;
  final bool isDark;

  const _AvatarZone({
    required this.framePath,
    required this.conquestPath,
    required this.levelColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Tamanho da zona: width=84, height=84
    // Frame central: 78x78, centralizado
    // Patente conquista: 38x38, inferior-esquerdo (sobrepõe levemente o frame)
    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Frame de ranking (DOMINANTE) ─────────────────
          Positioned(
            top: 3,
            right: 0,
            child: SizedBox(
              width: 78,
              height: 78,
              child: Image.asset(
                framePath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.star_rounded, size: 60, color: levelColor),
              ),
            ),
          ),

          // ── Patente de conquista (secundário, inferior-esquerdo) ────
          if (conquestPath != null)
            Positioned(
              bottom: 0,
              left: 0,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF1A2420) : Colors.white,
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.12)
                        : Colors.black.withOpacity(0.08),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Image.asset(
                      conquestPath!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.military_tech_rounded,
                        size: 20,
                        color: isDark ? Colors.white38 : Colors.black26,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── CHIP DE TÍTULO INLINE ─────────────────────────────────────────────────────
// Compacto e discreto: não compete com o frame. Fica na linha de info, pequeno.

class _InlineTitleChip extends StatelessWidget {
  final ({AchievementTrail trail, TrailLevel level}) activeTitle;

  const _InlineTitleChip({required this.activeTitle});

  @override
  Widget build(BuildContext context) {
    final color = Color(activeTitle.level.tier.colorValue);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          activeTitle.trail.emoji,
          style: const TextStyle(fontSize: 10, height: 1),
        ),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            activeTitle.level.title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color.withOpacity(0.85),
              letterSpacing: 0.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── LINHA DE PRÓXIMO RANK ─────────────────────────────────────────────────────

class _NextRankRow extends StatelessWidget {
  final String nextRankName;
  final int targetLevel;
  final bool isDark;

  const _NextRankRow({
    required this.nextRankName,
    required this.targetLevel,
    required this.isDark,
  });

  Color _rankColor(String name) {
    switch (name.toLowerCase()) {
      case 'ouro':
        return const Color(0xFFD4A017);
      case 'platina':
        return const Color(0xFF7BB8E8);
      case 'esmeralda':
        return const Color(0xFF4CAF7D);
      case 'diamante':
        return const Color(0xFF64B5F6);
      case 'mestre':
        return const Color(0xFFCE93D8);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _rankColor(nextRankName);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Próximo rank: ',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark
                ? Colors.white.withOpacity(0.38)
                : AppColors.textSecondary.withOpacity(0.6),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.35), width: 1),
          ),
          child: Text(
            '$nextRankName · Nível $targetLevel',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
    );
  }
}

// ── BARRA DE XP ──────────────────────────────────────────────────────────────

class _XpBar extends StatelessWidget {
  final double progress;
  final Color primaryColor;
  final bool isDark;

  const _XpBar({
    required this.progress,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 7,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1A13) : const Color(0xFFDDECE4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress),
          duration: const Duration(milliseconds: 1100),
          curve: Curves.easeOutCubic,
          builder: (_, val, __) => FractionallySizedBox(
            widthFactor: val.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: [primaryColor.withOpacity(0.75), primaryColor],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.45),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
