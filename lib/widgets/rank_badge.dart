import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/painters/frame_painter.dart';
import '../models/user_profile.dart';

/// ─────────────────────────────────────────────────────────────
/// RankBadge — exibe a moldura + patente do usuário
///
/// Usado no AppBar da Home e no header de Conquistas.
/// Mostra o avatar com o anel animado da moldura atual.
/// ─────────────────────────────────────────────────────────────
class RankBadge extends StatelessWidget {
  final UserProfile profile;
  final double      size;
  final bool        showLabel;
  final bool        showRankName;

  const RankBadge({
    super.key,
    required this.profile,
    this.size         = 56,
    this.showLabel    = true,
    this.showRankName = true,
  });

  /// Dias de streak máximo entre todas as conquistas
  int get _maxStreak {
    if (profile.conquistas.isEmpty) return 0;
    return profile.conquistas.values
        .map((a) => a.streakAtual)
        .fold(0, (a, b) => a > b ? a : b);
  }

  String get _rankName => AppColors.frameForDays(_maxStreak).name;

  @override
  Widget build(BuildContext context) {
    final days   = _maxStreak;
    final frame  = AppColors.frameForDays(days);
    final theme  = AppColors.themeForXp(profile.xpTotal);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar com anel da moldura
        AchievementFrame(
          days:    days,
          size:    size,
          animate: days > 0,
          child: CircleAvatar(
            radius:          size * 0.34,
            backgroundColor: theme.surface,
            backgroundImage: _hasPhoto ? FileImage(_photoFile) : null,
            child: _hasPhoto
                ? null
                : Text(
                    profile.apelido.isNotEmpty
                        ? profile.apelido[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize:   size * 0.24,
                      fontWeight: FontWeight.w700,
                      color:      theme.primary,
                    ),
                  ),
          ),
        ),

        if (showLabel) ...[
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize:       MainAxisSize.min,
            children: [
              Text(
                'Nível ${profile.nivel} — ${profile.nomeDonivel}',
                style: TextStyle(
                  fontSize:   13,
                  fontWeight: FontWeight.w700,
                  color:      theme.primary,
                ),
              ),
              const SizedBox(height: 2),
              if (showRankName && days > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color:        frame.ring.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border:       Border.all(color: frame.ring.withAlpha(80), width: 0.5),
                  ),
                  child: Text(
                    '🏅 ${frame.name}',
                    style: TextStyle(
                      fontSize:   10,
                      fontWeight: FontWeight.w600,
                      color:      frame.text,
                    ),
                  ),
                )
              else if (days == 0)
                Text(
                  'Sem patente ainda',
                  style: TextStyle(
                    fontSize: 10,
                    color:    AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  // Suporte futuro a foto de perfil — retorna false até ter ImagePicker
  bool get _hasPhoto => false;
  dynamic get _photoFile => null;
}

/// Versão compacta apenas do anel + inicial — para usar no AppBar
class RankAvatarOnly extends StatelessWidget {
  final UserProfile profile;
  final double      size;

  const RankAvatarOnly({
    super.key,
    required this.profile,
    this.size = 40,
  });

  int get _maxStreak {
    if (profile.conquistas.isEmpty) return 0;
    return profile.conquistas.values
        .map((a) => a.streakAtual)
        .fold(0, (a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppColors.themeForXp(profile.xpTotal);
    return AchievementFrame(
      days:    _maxStreak,
      size:    size,
      animate: _maxStreak > 0,
      child: CircleAvatar(
        radius:          size * 0.34,
        backgroundColor: theme.surface,
        child: Text(
          profile.apelido.isNotEmpty
              ? profile.apelido[0].toUpperCase()
              : '?',
          style: TextStyle(
            fontSize:   size * 0.24,
            fontWeight: FontWeight.w700,
            color:      theme.primary,
          ),
        ),
      ),
    );
  }
}
