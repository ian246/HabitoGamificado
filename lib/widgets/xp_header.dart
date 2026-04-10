import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';
import '../models/achievement.dart';
import '../models/user_profile.dart';

/// Faixa de XP exibida logo abaixo da AppBar na HomeScreen
class XpHeader extends StatelessWidget {
  final UserProfile profile;

  const XpHeader({super.key, required this.profile});

  String _getFramePath(int streak) {
    final currentFrame = AppColors.frameForDays(streak);
    return 'assets/frames/${currentFrame.name.toLowerCase()}_frame.png';
  }

  (int days, String name) _getNextFrameTarget(int streak) {
    if (streak < 30) return (30, 'Ouro');
    if (streak < 75) return (75, 'Platina');
    if (streak < 150) return (150, 'Esmeralda');
    if (streak < 200) return (200, 'Diamante');
    if (streak < 300) return (300, 'Mestre');
    return (-1, '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppColors.themeForXp(profile.xpTotal);
    final progress = profile.progressoNivel;
    final habitFlowColors = Theme.of(context).extension<HabitFlowColors>();

    // Calcula o streak geral (usando a conquista da categoria 'geral')
    final int streakAtual =
        profile.conquistas[AchievementCategory.geral]?.streakAtual ?? 0;

    final framePath = _getFramePath(streakAtual);
    final (nextFrameDays, nextFrameName) = _getNextFrameTarget(streakAtual);
    final xpNextTarget = theme.xpForNext;
    final diasFaltando = nextFrameDays > 0 ? nextFrameDays - streakAtual : 0;

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ícone / Frame do Nível
          SizedBox(
            width: 70,
            height: 70,
            child: Image.asset(
              framePath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.star, size: 50, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 16),
          // Informações e Progresso
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Nível ${profile.nivel} — ${profile.nomeDonivel}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (nextFrameDays > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Faltam $diasFaltando dias para o nível $nextFrameName',
                    style: AppTextStyles.xpLabel.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  '${profile.xpTotal} / $xpNextTarget XP',
                  style: AppTextStyles.xpLabel.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (_, val, __) => LinearProgressIndicator(
                      value: val,
                      minHeight: 8,
                      color: theme.primary,
                      backgroundColor:
                          habitFlowColors?.progressTrack ??
                          AppColors.surfaceHover,
                    ),
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
