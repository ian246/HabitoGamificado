import 'package:flutter/material.dart';
import 'app_colors.dart';

/// ─────────────────────────────────────────────────────────────
/// AppTextStyles — estilos de texto reutilizáveis
///
/// Uso direto (sem contexto):
///   Text('Olá', style: AppTextStyles.habitName)
///
/// Preferir o TextTheme via contexto para dark mode automático:
///   Text('Olá', style: Theme.of(context).textTheme.titleMedium)
///
/// Use AppTextStyles para casos onde você precisa de um estilo
/// específico com cor fixa (ex: dentro de um CustomPainter).
/// ─────────────────────────────────────────────────────────────
abstract final class AppTextStyles {
  // ── Nível e XP ───────────────────────────────────────────────
  static const TextStyle levelName = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle levelBadge = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  static const TextStyle xpLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // ── Cards de hábito ──────────────────────────────────────────
  static const TextStyle habitName = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle habitNameDone = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    decoration: TextDecoration.lineThrough,
  );

  static const TextStyle subtaskLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle subtaskDone = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint,
    decoration: TextDecoration.lineThrough,
  );

  static const TextStyle progressPercent = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  // ── Streak ───────────────────────────────────────────────────
  static const TextStyle streakCount = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.streak,
  );

  static const TextStyle streakLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle streakBadge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.streakDark,
  );

  // ── Conquistas / molduras ─────────────────────────────────────
  static const TextStyle frameName = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle frameDays = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle achievementUnlocked = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // ── Formulário ───────────────────────────────────────────────
  static const TextStyle sectionLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  static const TextStyle inputText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  // ── Período do dia ───────────────────────────────────────────
  static const TextStyle periodChip = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  // ── Gráfico (CustomPainter usa diretamente) ──────────────────
  static const TextStyle chartAxisLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle chartValue = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  // ── Greeting na AppBar ───────────────────────────────────────
  static const TextStyle greeting = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle username = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
}
