import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/user_profile.dart';

/// Faixa de XP exibida logo abaixo da AppBar na HomeScreen
class XpHeader extends StatelessWidget {
  final UserProfile profile;

  const XpHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme    = AppColors.themeForXp(profile.xpTotal);
    final progress = profile.progressoNivel;
    final xpFalta  = profile.xpProximoNivel - profile.xpTotal;

    return Container(
      color: Theme.of(context).cardTheme.color,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nível ${profile.nivel} — ${profile.nomeDonivel}',
                style: AppTextStyles.levelBadge,
              ),
              Text(
                '${profile.xpTotal} XP',
                style: AppTextStyles.xpLabel,
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (_, val, __) => LinearProgressIndicator(
                value:            val,
                minHeight:        6,
                color:            theme.primary,
                backgroundColor:  AppColors.surfaceHover,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Faltam $xpFalta XP para o próximo nível',
            style: AppTextStyles.xpLabel,
          ),
        ],
      ),
    );
  }
}
