/// ─────────────────────────────────────────────────────────────
/// HabitDateUtils — utilitários de data para o HabitFlow
///
/// Não importa 'package:intl' aqui para manter o arquivo
/// sem dependências externas. Use o intl nas telas quando
/// precisar de formatação localizada completa.
/// ─────────────────────────────────────────────────────────────

abstract final class HabitDateUtils {
  // ── Chave de armazenamento ─────────────────────────────────
  /// Converte DateTime para chave ISO usada no SharedPreferences
  /// Formato: 'yyyy-MM-dd' (ex: '2025-07-15')
  static String toKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Chave do dia atual
  static String todayKey() => toKey(DateTime.now());

  /// Chave de ontem
  static String yesterdayKey() =>
      toKey(DateTime.now().subtract(const Duration(days: 1)));

  /// Converte chave ISO de volta para DateTime
  static DateTime fromKey(String key) => DateTime.parse(key);

  // ── Comparações ────────────────────────────────────────────
  /// Verifica se duas datas são o mesmo dia (ignora hora)
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Verifica se a data é hoje
  static bool isToday(DateTime date) => isSameDay(date, DateTime.now());

  /// Verifica se a data é ontem
  static bool isYesterday(DateTime date) =>
      isSameDay(date, DateTime.now().subtract(const Duration(days: 1)));

  // ── Geração de intervalos ──────────────────────────────────
  /// Retorna as chaves dos últimos N dias (do mais antigo ao mais recente)
  static List<String> lastNDaysKeys(int n) {
    final today = DateTime.now();
    return List.generate(n, (i) {
      final date = today.subtract(Duration(days: n - 1 - i));
      return toKey(date);
    });
  }

  /// Retorna as chaves dos últimos 7 dias (para o WeekChart)
  static List<String> lastWeekKeys() => lastNDaysKeys(7);

  // ── Cálculo de streak ──────────────────────────────────────
  /// Calcula o streak atual a partir do histórico de conclusão.
  ///
  /// [history] — Map<String, double> onde:
  ///   chave = 'yyyy-MM-dd'
  ///   valor = percentual de conclusão (0.0 a 1.0)
  ///
  /// Considera "concluído" qualquer valor >= [threshold] (padrão: 1.0)
  ///
  /// Retorna:
  ///   0 se hoje não foi concluído E ontem não foi concluído
  ///   N dias de sequência contínua terminando hoje ou ontem
  static int calculateStreak(
    Map<String, double> history, {
    double threshold = 1.0,
  }) {
    final today     = DateTime.now();
    final todayKey_ = toKey(today);

    // Se hoje já foi concluído, conta a partir de hoje
    // Se hoje ainda não foi concluído mas ontem foi, conta a partir de ontem
    // Senão, streak é 0

    bool todayDone = (history[todayKey_] ?? 0.0) >= threshold;

    DateTime checkDate = todayDone
        ? today
        : today.subtract(const Duration(days: 1));

    // Verifica se o ponto de início tem conclusão
    if (!todayDone) {
      final checkKey = toKey(checkDate);
      if ((history[checkKey] ?? 0.0) < threshold) return 0;
    }

    int streak = 0;
    while (true) {
      final key  = toKey(checkDate);
      final done = (history[key] ?? 0.0) >= threshold;
      if (!done) break;
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Calcula o maior streak já atingido no histórico
  static int calculateBestStreak(
    Map<String, double> history, {
    double threshold = 1.0,
  }) {
    if (history.isEmpty) return 0;

    // Ordena as datas
    final sortedKeys = history.keys.toList()..sort();
    int best    = 0;
    int current = 0;

    for (int i = 0; i < sortedKeys.length; i++) {
      final value = history[sortedKeys[i]] ?? 0.0;
      if (value >= threshold) {
        // Verifica se é dia consecutivo ao anterior
        if (i > 0) {
          final prev = fromKey(sortedKeys[i - 1]);
          final curr = fromKey(sortedKeys[i]);
          final diff = curr.difference(prev).inDays;
          current = diff == 1 ? current + 1 : 1;
        } else {
          current = 1;
        }
        if (current > best) best = current;
      } else {
        current = 0;
      }
    }
    return best;
  }

  // ── Formatação simples (sem intl) ──────────────────────────
  static const _weekdays = [
    'segunda', 'terça', 'quarta', 'quinta',
    'sexta', 'sábado', 'domingo',
  ];

  static const _months = [
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
    'jul', 'ago', 'set', 'out', 'nov', 'dez',
  ];

  /// Ex: 'hoje', 'ontem', 'segunda', '15 jul'
  static String friendlyDate(DateTime date) {
    if (isToday(date))     return 'hoje';
    if (isYesterday(date)) return 'ontem';

    final dayOfWeek = date.weekday - 1; // 0 = segunda
    final now       = DateTime.now();
    final diff      = now.difference(date).inDays;

    if (diff < 7) return _weekdays[dayOfWeek];
    return '${date.day} ${_months[date.month - 1]}';
  }

  /// Período do dia em texto
  static String periodLabel(String period) {
    switch (period) {
      case 'manha': return 'Manhã';
      case 'tarde': return 'Tarde';
      case 'noite': return 'Noite';
      default:      return period;
    }
  }

  /// Retorna o período do dia atual baseado no horário
  static String currentPeriod() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'manha';
    if (hour < 18) return 'tarde';
    return 'noite';
  }
}
