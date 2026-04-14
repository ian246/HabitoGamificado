import '../theme/app_colors.dart';

/// ─────────────────────────────────────────────────────────────
/// XpCalculator — lógica de XP e níveis do HabitFlow
///
/// Todas as regras de ganho de XP ficam aqui.
/// Nenhuma tela calcula XP — elas chamam esse serviço.
///
/// Regras de XP:
///   +5   por mini tarefa concluída
///   +20  bonus ao completar 100% de um hábito
///   +50  bonus de "dia perfeito" (todos os hábitos 100%)
///   +30  bonus semanal de streak (a cada 7 dias)
///   +100 bonus único ao desbloquear nova moldura
/// ─────────────────────────────────────────────────────────────

abstract final class XpCalculator {
  // ── Valores de XP ─────────────────────────────────────────
  static const int perSubtask        = 5;
  static const int habitCompleteBonus = 20;
  static const int perfectDayBonus   = 50;
  static const int weeklyStreakBonus  = 30;
  static const int frameUnlockBonus  = 100;

  // ── Marcos de conquista — agora alinhados com nível de XP
  /// Níveis que desbloqueiam uma nova moldura (visual)
  static const List<int> frameMilestones = [5, 15, 30, 50, 80];

  // ── Cálculos de ganho ─────────────────────────────────────

  /// XP ganho ao marcar uma mini tarefa
  static int onSubtaskCheck() => perSubtask;

  /// XP ganho ao completar todas as mini tarefas de um hábito
  /// [isAlreadyComplete] evita duplo bônus se chamar de novo
  static int onHabitComplete({bool isAlreadyComplete = false}) =>
      isAlreadyComplete ? 0 : habitCompleteBonus;

  /// XP ganho quando todos os hábitos do dia foram 100% concluídos
  /// [alreadyGrantedToday] evita repetição no mesmo dia
  static int onPerfectDay({bool alreadyGrantedToday = false}) =>
      alreadyGrantedToday ? 0 : perfectDayBonus;

  /// XP ganho ao completar um múltiplo de 7 dias de streak
  /// [streakDays] — streak atual após incremento
  static int onStreakMilestone(int streakDays) =>
      streakDays > 0 && streakDays % 7 == 0 ? weeklyStreakBonus : 0;

  /// XP ganho ao desbloquear uma nova moldura
  /// [wasAlreadyUnlocked] evita bônus repetido
  static int onFrameUnlock({bool wasAlreadyUnlocked = false}) =>
      wasAlreadyUnlocked ? 0 : frameUnlockBonus;

  // ── Informações de nível ───────────────────────────────────

  /// Retorna o LevelTheme correspondente ao XP atual
  static LevelTheme levelForXp(int xp) => AppColors.themeForXp(xp);

  /// Número do nível (1–9) pelo XP atual
  static int levelNumber(int xp) => AppColors.themeForXp(xp).level;

  /// Nome do nível pelo XP atual
  static String levelName(int xp) => AppColors.themeForXp(xp).name;

  /// Progresso de 0.0 a 1.0 dentro do nível atual
  static double levelProgress(int xp) =>
      AppColors.themeForXp(xp).progressTo(xp);

  /// XP faltando para o próximo nível
  static int xpToNextLevel(int xp) {
    final theme = AppColors.themeForXp(xp);
    final next  = theme.xpForNext;
    return (next - xp).clamp(0, next);
  }

  /// Verifica se o usuário subiu de nível com este ganho
  /// Útil para disparar animação de level-up
  static bool didLevelUp(int xpBefore, int xpAfter) =>
      levelNumber(xpBefore) < levelNumber(xpAfter);

  // ── Molduras ───────────────────────────────────────────────

  /// Retorna o próximo marco de dias para o streak atual
  /// Ex: streak = 12 → próximo marco = 15
  static int? nextMilestone(int currentStreak) {
    for (final m in frameMilestones) {
      if (currentStreak < m) return m;
    }
    return null; // já atingiu todos
  }

  /// Verifica se o streak atual acabou de bater um marco
  static bool isNewMilestone(int streakBefore, int streakAfter) {
    for (final m in frameMilestones) {
      if (streakBefore < m && streakAfter >= m) return true;
    }
    return false;
  }

  /// Quantos dias faltam para o próximo marco
  static int daysToNextMilestone(int currentStreak) {
    final next = nextMilestone(currentStreak);
    if (next == null) return 0;
    return next - currentStreak;
  }

  /// Progresso (0.0 a 1.0) em direção ao próximo marco de moldura
  static double milestoneProgress(int currentStreak) {
    if (frameMilestones.isEmpty) return 1.0;

    int prevMilestone = 0;
    for (final m in frameMilestones) {
      if (currentStreak < m) {
        final range    = m - prevMilestone;
        final progress = currentStreak - prevMilestone;
        return (progress / range).clamp(0.0, 1.0);
      }
      prevMilestone = m;
    }
    return 1.0; // todos os marcos atingidos
  }

  // ── Resumo de XP para log/debug ───────────────────────────
  /// Gera um mapa com o total de XP que uma sessão renderia
  static Map<String, int> sessionSummary({
    required int subtasksChecked,
    required int habitsCompleted,
    required bool perfectDay,
    required int streakAfter,
    required bool newFrameUnlocked,
  }) {
    return {
      'subtarefas':    subtasksChecked  * perSubtask,
      'habitos100':    habitsCompleted  * habitCompleteBonus,
      'diaPerfeit o':  perfectDay ? perfectDayBonus : 0,
      'streakSemanal': onStreakMilestone(streakAfter),
      'novaMoldura':   newFrameUnlocked ? frameUnlockBonus : 0,
    };
  }

  /// Total de XP de uma sessão
  static int totalFromSummary(Map<String, int> summary) =>
      summary.values.fold(0, (a, b) => a + b);
}
