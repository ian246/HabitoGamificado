import 'dart:convert';

/// ─────────────────────────────────────────────────────────────
/// AchievementCategory — categorias de conquista
/// ─────────────────────────────────────────────────────────────
enum AchievementCategory {
  manha,      // hábitos da manhã
  tarde,      // hábitos da tarde
  noite,      // hábitos da noite
  geral,      // qualquer hábito concluído
  perfeito,   // todos os hábitos do dia 100%
}

extension AchievementCategoryExt on AchievementCategory {
  String get label {
    switch (this) {
      case AchievementCategory.manha:    return 'Manhã';
      case AchievementCategory.tarde:    return 'Tarde';
      case AchievementCategory.noite:    return 'Noite';
      case AchievementCategory.geral:    return 'Sequência Geral';
      case AchievementCategory.perfeito: return 'Perfeccionista';
    }
  }

  String get icone {
    switch (this) {
      case AchievementCategory.manha:    return '🌅';
      case AchievementCategory.tarde:    return '☀️';
      case AchievementCategory.noite:    return '🌙';
      case AchievementCategory.geral:    return '🔥';
      case AchievementCategory.perfeito: return '⭐';
    }
  }

  String get descricao {
    switch (this) {
      case AchievementCategory.manha:
        return 'Dias com todos os hábitos da manhã concluídos';
      case AchievementCategory.tarde:
        return 'Dias com todos os hábitos da tarde concluídos';
      case AchievementCategory.noite:
        return 'Dias com todos os hábitos da noite concluídos';
      case AchievementCategory.geral:
        return 'Dias consecutivos com ao menos 1 hábito 100% feito';
      case AchievementCategory.perfeito:
        return 'Dias com 100% de todos os hábitos concluídos';
    }
  }

  String get valor => name; // para serialização
}

/// ─────────────────────────────────────────────────────────────
/// Achievement — conquista de uma categoria específica
///
/// Cada categoria tem seu próprio streak e histórico de marcos
/// desbloqueados. O usuário pode ser Mestre da Manhã e Prata
/// da Noite ao mesmo tempo.
/// ─────────────────────────────────────────────────────────────
class Achievement {
  final AchievementCategory categoria;
  final int                 streakAtual;
  final int                 melhorStreak;

  /// Marcos já desbloqueados (ex: [5, 10, 15, 30])
  final List<int>           marcosDesbloqueados;

  /// Datas em que o dia foi contado para esta categoria ('yyyy-MM-dd')
  final List<String>        diasConcluidos;

  const Achievement({
    required this.categoria,
    this.streakAtual          = 0,
    this.melhorStreak         = 0,
    this.marcosDesbloqueados  = const [],
    this.diasConcluidos       = const [],
  });

  // ── Marcos do sistema ────────────────────────────────────
  static const List<int> todos = [5, 10, 15, 30, 50, 75, 100, 150, 200, 300];

  // ── Propriedades derivadas ───────────────────────────────

  /// Próximo marco a desbloquear (null = todos desbloqueados)
  int? get proximoMarco {
    for (final m in todos) {
      if (!marcosDesbloqueados.contains(m)) return m;
    }
    return null;
  }

  /// Dias faltando para o próximo marco
  int get diasParaProximo {
    final next = proximoMarco;
    if (next == null) return 0;
    return next - streakAtual;
  }

  /// Progresso (0.0–1.0) em direção ao próximo marco
  double get progressoParaProximo {
    final next = proximoMarco;
    if (next == null) return 1.0;

    // Marco anterior (piso)
    int prev = 0;
    for (final m in todos) {
      if (m < next && marcosDesbloqueados.contains(m)) prev = m;
    }
    final range = next - prev;
    if (range <= 0) return 1.0;
    return ((streakAtual - prev) / range).clamp(0.0, 1.0);
  }

  /// Nome da moldura atual baseado no maior marco desbloqueado
  String get nomeMoldura {
    if (marcosDesbloqueados.isEmpty)           return 'Sem moldura';
    final maior = marcosDesbloqueados.reduce((a, b) => a > b ? a : b);
    if (maior >= 300) return 'Mestre';
    if (maior >= 200) return 'Diamante';
    if (maior >= 150) return 'Esmeralda';
    if (maior >= 75)  return 'Platina';
    if (maior >= 30)  return 'Ouro';
    return 'Prata';
  }

  /// Dias que representam o nível da moldura atual
  int get diasMolduraAtual =>
      marcosDesbloqueados.isEmpty ? 0 : marcosDesbloqueados.last;

  // ── copyWith ────────────────────────────────────────────
  Achievement copyWith({
    AchievementCategory? categoria,
    int?                 streakAtual,
    int?                 melhorStreak,
    List<int>?           marcosDesbloqueados,
    List<String>?        diasConcluidos,
  }) => Achievement(
    categoria:           categoria           ?? this.categoria,
    streakAtual:         streakAtual         ?? this.streakAtual,
    melhorStreak:        melhorStreak        ?? this.melhorStreak,
    marcosDesbloqueados: marcosDesbloqueados ?? this.marcosDesbloqueados,
    diasConcluidos:      diasConcluidos      ?? this.diasConcluidos,
  );

  /// Registra um dia concluído e recalcula streak e marcos
  /// Retorna (Achievement atualizado, List<int> novos marcos desbloqueados)
  (Achievement, List<int>) registrarDia(String chaveData) {
    if (diasConcluidos.contains(chaveData)) {
      return (this, []); // dia já registrado
    }

    final novosDias = [...diasConcluidos, chaveData]..sort();

    // Recalcula streak
    int streak = _calcularStreakDaLista(novosDias);

    // Verifica novos marcos
    final novosMarcos = <int>[];
    final marcosAtuais = [...marcosDesbloqueados];
    for (final m in todos) {
      if (!marcosAtuais.contains(m) && streak >= m) {
        marcosAtuais.add(m);
        novosMarcos.add(m);
      }
    }

    final atualizado = copyWith(
      streakAtual:         streak,
      melhorStreak:        streak > melhorStreak ? streak : melhorStreak,
      marcosDesbloqueados: marcosAtuais,
      diasConcluidos:      novosDias,
    );

    return (atualizado, novosMarcos);
  }

  // ── Helpers privados ─────────────────────────────────────
  int _calcularStreakDaLista(List<String> dias) {
    if (dias.isEmpty) return 0;
    final hoje    = _toKey(DateTime.now());
    final ontem   = _toKey(DateTime.now().subtract(const Duration(days: 1)));
    final sorted  = [...dias]..sort((a, b) => b.compareTo(a)); // mais recente primeiro

    // Só conta se hoje ou ontem estiver na lista
    if (sorted.first != hoje && sorted.first != ontem) return 0;

    int streak    = 0;
    DateTime? ref = sorted.first == hoje ? DateTime.now() : DateTime.now().subtract(const Duration(days: 1));

    for (final key in sorted) {
      final d = DateTime.parse(key);
      if (ref == null) break;
      final diff = ref.difference(d).inDays;
      if (diff == 0 || (streak == 0 && diff <= 1)) {
        streak++;
        ref = d.subtract(const Duration(days: 1));
      } else if (diff == 1) {
        streak++;
        ref = d.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  String _toKey(DateTime d) =>
      '${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  // ── Serialização ────────────────────────────────────────
  Map<String, dynamic> toJson() => {
    'categoria':           categoria.valor,
    'streakAtual':         streakAtual,
    'melhorStreak':        melhorStreak,
    'marcosDesbloqueados': marcosDesbloqueados,
    'diasConcluidos':      diasConcluidos,
  };

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
    categoria: AchievementCategory.values.firstWhere(
      (e) => e.valor == json['categoria'],
      orElse: () => AchievementCategory.geral,
    ),
    streakAtual:         json['streakAtual']  as int? ?? 0,
    melhorStreak:        json['melhorStreak'] as int? ?? 0,
    marcosDesbloqueados: List<int>.from(json['marcosDesbloqueados'] as List? ?? []),
    diasConcluidos:      List<String>.from(json['diasConcluidos']   as List? ?? []),
  );

  String toJsonString()                  => jsonEncode(toJson());
  factory Achievement.fromJsonString(String raw) =>
      Achievement.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  @override
  String toString() =>
      'Achievement(${categoria.label}, streak: $streakAtual, moldura: $nomeMoldura)';
}
