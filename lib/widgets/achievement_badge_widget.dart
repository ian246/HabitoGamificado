import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/painters/frame_painter.dart';
import '../models/achievement.dart';

/// ─────────────────────────────────────────────────────────────
/// AchievementBadgeWidget
///
/// Suporta dois modos:
///   1. PNG asset (imagens do Nano Barana) — recomendado
///   2. Emoji fallback — quando não há asset
///
/// Para usar os PNG assets, coloque os arquivos em:
///   assets/frames/frame_prata.png
///   assets/frames/frame_ouro.png
///   assets/frames/frame_platina.png
///   assets/frames/frame_esmeralda.png
///   assets/frames/frame_diamante.png
///   assets/frames/frame_mestre.png
///
/// E no pubspec.yaml:
///   flutter:
///     assets:
///       - assets/frames/
///
/// O CustomPainter desenha o anel animado ao redor do asset PNG.
/// ─────────────────────────────────────────────────────────────
class AchievementBadgeWidget extends StatelessWidget {
  final Achievement achievement;
  final bool        useImageAssets; // true = PNG, false = emoji
  final double      size;
  final bool        showLabel;
  final bool        showProgress;

  const AchievementBadgeWidget({
    super.key,
    required this.achievement,
    this.useImageAssets = true,
    this.size           = 80,
    this.showLabel      = true,
    this.showProgress   = true,
  });

  @override
  Widget build(BuildContext context) {
    final days    = achievement.diasMolduraAtual;
    final locked  = days == 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Badge + anel ─────────────────────────────────
        Stack(
          alignment: Alignment.center,
          children: [
            // Anel animado (CustomPainter)
            AchievementFrame(
              days:    locked ? 0 : days,
              size:    size,
              animate: !locked,
              child:   _buildCenter(locked),
            ),

            // Cadeado se bloqueado
            if (locked)
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withAlpha(200),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_rounded,
                      size: 12, color: Colors.white),
                ),
              ),
          ],
        ),

        if (showLabel) ...[
          const SizedBox(height: 6),
          Text(
            achievement.categoria.label,
            style: AppTextStyles.frameName,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            locked
                ? 'Sem conquista'
                : achievement.nomeMoldura,
            style: AppTextStyles.frameDays.copyWith(
              color: locked
                  ? AppColors.textHint
                  : AppColors.frameForDays(days).text,
            ),
          ),
        ],

        if (showProgress && !locked) ...[
          const SizedBox(height: 6),
          SizedBox(
            width: size,
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value:           achievement.progressoParaProximo,
                    minHeight:       4,
                    color:           AppColors.frameForDays(days).ring,
                    backgroundColor: AppColors.surfaceCard,
                  ),
                ),
                const SizedBox(height: 3),
                if (achievement.proximoMarco != null)
                  Text(
                    'Faltam ${achievement.diasParaProximo}d → ${achievement.proximoMarco}d',
                    style: AppTextStyles.xpLabel,
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCenter(bool locked) {
    if (locked) {
      return Text(
        achievement.categoria.icone,
        style: TextStyle(fontSize: size * 0.35),
      );
    }

    final days = achievement.diasMolduraAtual;

    if (useImageAssets) {
      return _AssetBadgeCenter(days: days, size: size);
    }

    return Text(
      achievement.categoria.icone,
      style: TextStyle(fontSize: size * 0.38),
    );
  }
}

/// Centro com imagem PNG do asset
class _AssetBadgeCenter extends StatelessWidget {
  final int    days;
  final double size;

  const _AssetBadgeCenter({required this.days, required this.size});

  String get _assetPath {
    if (days >= 300) return 'assets/frames/frame_mestre.png';
    if (days >= 200) return 'assets/frames/frame_diamante.png';
    if (days >= 150) return 'assets/frames/frame_esmeralda.png';
    if (days >= 75)  return 'assets/frames/frame_platina.png';
    if (days >= 30)  return 'assets/frames/frame_ouro.png';
    return              'assets/frames/frame_prata.png';
  }

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        _assetPath,
        width:  size * 0.58,
        height: size * 0.58,
        fit:    BoxFit.cover,
        errorBuilder: (_, __, ___) {
          // Fallback para emoji se o PNG não existir ainda
          final frames = AppColors.frameForDays(days);
          return Container(
            width:  size * 0.58,
            height: size * 0.58,
            decoration: BoxDecoration(
              color: frames.shine,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _emojiForDays(days),
              style: TextStyle(fontSize: size * 0.28),
            ),
          );
        },
      ),
    );
  }

  String _emojiForDays(int days) {
    if (days >= 300) return '👑';
    if (days >= 200) return '💎';
    if (days >= 150) return '💚';
    if (days >= 75)  return '🔮';
    if (days >= 30)  return '🌟';
    return '🌱';
  }
}

/// Card de conquista completo para a tela de Conquistas
class AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final bool        useImageAssets;

  const AchievementCard({
    super.key,
    required this.achievement,
    this.useImageAssets = true,
  });

  @override
  Widget build(BuildContext context) {
    final locked = achievement.diasMolduraAtual == 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            AchievementBadgeWidget(
              achievement:    achievement,
              useImageAssets: useImageAssets,
              size:           64,
              showLabel:      false,
              showProgress:   false,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(achievement.categoria.icone,
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(achievement.categoria.label,
                          style: AppTextStyles.habitName),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    locked
                        ? 'Nenhum dia registrado ainda'
                        : achievement.nomeMoldura,
                    style: AppTextStyles.frameDays,
                  ),
                  const SizedBox(height: 8),
                  if (!locked) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value:     achievement.progressoParaProximo,
                        minHeight: 5,
                        color:     AppColors.frameForDays(
                            achievement.diasMolduraAtual).ring,
                        backgroundColor: AppColors.surfaceCard,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${achievement.streakAtual} dias',
                          style: AppTextStyles.streakBadge,
                        ),
                        if (achievement.proximoMarco != null)
                          Text(
                            'Próximo: ${achievement.proximoMarco} dias',
                            style: AppTextStyles.xpLabel,
                          ),
                      ],
                    ),
                  ],
                  if (locked)
                    Text(
                      achievement.categoria.descricao,
                      style: AppTextStyles.xpLabel,
                      maxLines: 2,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
