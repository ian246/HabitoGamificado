/// ─────────────────────────────────────────────────────────────
/// achievement_trail.dart
///
/// Sistema de Trilhas de Conquistas do HabitFlow.
///
/// Estrutura:
///   • 8 Trilhas independentes (O Constante, O Dedicado, etc.)
///   • Cada trilha tem 6 tiers: Prata → Ouro → Platina →
///     Esmeralda → Diamante → Mestre
///   • O progresso é salvo em UserProfile via Map<String, int>
///     onde a chave é o ID da trilha e o valor é o progresso atual
///
/// Chave de persistência no SharedPreferences (via UserProfile):
///   'trail_constante': 12    (12 dias de streak)
///   'trail_dedicado': 47     (47 hábitos concluídos)
///   etc.
/// ─────────────────────────────────────────────────────────────

// ── Tier (nível de raridade de uma conquista) ─────────────────
enum AchievementTier { prata, ouro, platina, esmeralda, diamante, mestre }

extension AchievementTierExt on AchievementTier {
  String get label {
    switch (this) {
      case AchievementTier.prata:
        return 'Prata';
      case AchievementTier.ouro:
        return 'Ouro';
      case AchievementTier.platina:
        return 'Platina';
      case AchievementTier.esmeralda:
        return 'Esmeralda';
      case AchievementTier.diamante:
        return 'Diamante';
      case AchievementTier.mestre:
        return 'Mestre';
    }
  }

  /// Caminho do PNG em assets/conquests/
  String get assetPath {
    switch (this) {
      case AchievementTier.prata:
        return 'assets/conquests/conquista_prata.png';
      case AchievementTier.ouro:
        return 'assets/conquests/conquista_ouro.png';
      case AchievementTier.platina:
        return 'assets/conquests/conquista_platina.png';
      case AchievementTier.esmeralda:
        return 'assets/conquests/conquista_esmeralda.png';
      case AchievementTier.diamante:
        return 'assets/conquests/conquista_diamante.png';
      case AchievementTier.mestre:
        return 'assets/conquests/conquista_mestre.png';
    }
  }

  /// Cor associada ao tier (usada em textos e bordas)
  int get colorValue {
    switch (this) {
      case AchievementTier.prata:
        return 0xFFB0B8C1;
      case AchievementTier.ouro:
        return 0xFFD4AF37;
      case AchievementTier.platina:
        return 0xFF9EA8B3;
      case AchievementTier.esmeralda:
        return 0xFF1A7A4A;
      case AchievementTier.diamante:
        return 0xFF1A6B9E;
      case AchievementTier.mestre:
        return 0xFF6B2FA0;
    }
  }

  int get index2 {
    switch (this) {
      case AchievementTier.prata:
        return 0;
      case AchievementTier.ouro:
        return 1;
      case AchievementTier.platina:
        return 2;
      case AchievementTier.esmeralda:
        return 3;
      case AchievementTier.diamante:
        return 4;
      case AchievementTier.mestre:
        return 5;
    }
  }
}

// ── Definição de um nível dentro de uma trilha ────────────────
class TrailLevel {
  final AchievementTier tier;
  final int threshold; // valor necessário para atingir este tier
  final String description; // ex: '15 a 50 hábitos concluídos'
  final String title; // título honorífico conquistado ao atingir este tier

  const TrailLevel({
    required this.tier,
    required this.threshold,
    required this.description,
    required this.title,
  });
}

// ── Definição de uma trilha completa ─────────────────────────
class AchievementTrail {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final List<TrailLevel> levels; // sempre 6, de Prata a Mestre

  const AchievementTrail({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.levels,
  });

  /// Tier atual com base no progresso
  AchievementTier? currentTier(int progress) {
    AchievementTier? current;
    for (final lvl in levels) {
      if (progress >= lvl.threshold) current = lvl.tier;
    }
    return current;
  }

  /// Próximo tier ainda não atingido
  TrailLevel? nextLevel(int progress) {
    for (final lvl in levels) {
      if (progress < lvl.threshold) return lvl;
    }
    return null; // todos os tiers atingidos
  }

  /// Progresso de 0.0 a 1.0 em direção ao próximo tier
  double progressToNext(int progress) {
    final next = nextLevel(progress);
    if (next == null) return 1.0;

    // Tier anterior (piso)
    int prev = 0;
    for (final lvl in levels) {
      if (lvl.tier == next.tier) break;
      prev = lvl.threshold;
    }

    final range = next.threshold - prev;
    if (range <= 0) return 1.0;
    return ((progress - prev) / range).clamp(0.0, 1.0);
  }

  bool isMaxed(int progress) => nextLevel(progress) == null;

  /// Retorna o TrailLevel atual conquistado (o de maior tier atingido)
  TrailLevel? currentLevel(int progress) {
    TrailLevel? current;
    for (final lvl in levels) {
      if (progress >= lvl.threshold) current = lvl;
    }
    return current;
  }
}

// ── As 8 trilhas do HabitFlow ─────────────────────────────────
abstract final class AchievementTrails {
  static const constante = AchievementTrail(
    id: 'constante',
    name: 'O Constante',
    emoji: '🔥',
    description: 'Dias seguidos sem quebrar a sequência',
    levels: [
      TrailLevel(
        tier: AchievementTier.prata,
        threshold: 5,
        description: '5 dias seguidos',
        title: 'Fagulha Inicial',
      ),
      TrailLevel(
        tier: AchievementTier.ouro,
        threshold: 15,
        description: '15 dias seguidos',
        title: 'Chama Constante',
      ),
      TrailLevel(
        tier: AchievementTier.platina,
        threshold: 30,
        description: '30 dias seguidos',
        title: 'Fogo Inabalável',
      ),
      TrailLevel(
        tier: AchievementTier.esmeralda,
        threshold: 75,
        description: '75 dias seguidos',
        title: 'Fornalha Implacável',
      ),
      TrailLevel(
        tier: AchievementTier.diamante,
        threshold: 150,
        description: '150 dias seguidos',
        title: 'Fênix da Rotina',
      ),
      TrailLevel(
        tier: AchievementTier.mestre,
        threshold: 300,
        description: '300 dias seguidos',
        title: 'O Imparável',
      ),
    ],
  );

  static const dedicado = AchievementTrail(
    id: 'dedicado',
    name: 'O Dedicado',
    emoji: '✅',
    description: 'Total de hábitos concluídos a 100%',
    levels: [
      TrailLevel(
        tier: AchievementTier.prata,
        threshold: 15,
        description: '15 hábitos concluídos',
        title: 'Aprendiz Focado',
      ),
      TrailLevel(
        tier: AchievementTier.ouro,
        threshold: 50,
        description: '50 hábitos concluídos',
        title: 'Executor Fiel',
      ),
      TrailLevel(
        tier: AchievementTier.platina,
        threshold: 100,
        description: '100 hábitos concluídos',
        title: 'Disciplina de Ferro',
      ),
      TrailLevel(
        tier: AchievementTier.esmeralda,
        threshold: 250,
        description: '250 hábitos concluídos',
        title: 'Vontade de Aço',
      ),
      TrailLevel(
        tier: AchievementTier.diamante,
        threshold: 500,
        description: '500 hábitos concluídos',
        title: 'Máquina de Hábitos',
      ),
      TrailLevel(
        tier: AchievementTier.mestre,
        threshold: 1000,
        description: '1000 hábitos concluídos',
        title: 'O Absoluto',
      ),
    ],
  );

  static const perfeccionista = AchievementTrail(
    id: 'perfeccionista',
    name: 'O Perfeccionista',
    emoji: '⭐',
    description: 'Dias com todos os hábitos 100% concluídos',
    levels: [
      TrailLevel(
        tier: AchievementTier.prata,
        threshold: 5,
        description: '5 dias perfeitos',
        title: 'Olho Atento',
      ),
      TrailLevel(
        tier: AchievementTier.ouro,
        threshold: 15,
        description: '15 dias perfeitos',
        title: 'Relógio Suíço',
      ),
      TrailLevel(
        tier: AchievementTier.platina,
        threshold: 30,
        description: '30 dias perfeitos',
        title: 'Arquiteto Impecável',
      ),
      TrailLevel(
        tier: AchievementTier.esmeralda,
        threshold: 60,
        description: '60 dias perfeitos',
        title: 'Sinfonia Perfeita',
      ),
      TrailLevel(
        tier: AchievementTier.diamante,
        threshold: 100,
        description: '100 dias perfeitos',
        title: 'Padrão Ouro',
      ),
      TrailLevel(
        tier: AchievementTier.mestre,
        threshold: 200,
        description: '200 dias perfeitos',
        title: 'A Engrenagem Perfeita',
      ),
    ],
  );

  static const madrugador = AchievementTrail(
    id: 'madrugador',
    name: 'O Madrugador',
    emoji: '🌅',
    description: 'Hábitos da manhã concluídos a 100%',
    levels: [
      TrailLevel(
        tier: AchievementTier.prata,
        threshold: 10,
        description: '10 manhãs concluídas',
        title: 'Despertar Sereno',
      ),
      TrailLevel(
        tier: AchievementTier.ouro,
        threshold: 30,
        description: '30 manhãs concluídas',
        title: 'Raio de Sol',
      ),
      TrailLevel(
        tier: AchievementTier.platina,
        threshold: 75,
        description: '75 manhãs concluídas',
        title: 'Pioneiro da Alvorada',
      ),
      TrailLevel(
        tier: AchievementTier.esmeralda,
        threshold: 150,
        description: '150 manhãs concluídas',
        title: 'Arauto do Amanhecer',
      ),
      TrailLevel(
        tier: AchievementTier.diamante,
        threshold: 300,
        description: '300 manhãs concluídas',
        title: 'Senhor da Aurora',
      ),
      TrailLevel(
        tier: AchievementTier.mestre,
        threshold: 500,
        description: '500 manhãs concluídas',
        title: 'O Próprio Sol',
      ),
    ],
  );

  static const vespertino = AchievementTrail(
    id: 'vespertino',
    name: 'O Vespertino',
    emoji: '☀️',
    description: 'Hábitos da tarde concluídos a 100%',
    levels: [
      TrailLevel(
        tier: AchievementTier.prata,
        threshold: 10,
        description: '10 tardes concluídas',
        title: 'Sombra do Meio-Dia',
      ),
      TrailLevel(
        tier: AchievementTier.ouro,
        threshold: 30,
        description: '30 tardes concluídas',
        title: 'Sol a Pino',
      ),
      TrailLevel(
        tier: AchievementTier.platina,
        threshold: 75,
        description: '75 tardes concluídas',
        title: 'Motor da Tarde',
      ),
      TrailLevel(
        tier: AchievementTier.esmeralda,
        threshold: 150,
        description: '150 tardes concluídas',
        title: 'Brilho Vespertino',
      ),
      TrailLevel(
        tier: AchievementTier.diamante,
        threshold: 300,
        description: '300 tardes concluídas',
        title: 'Guardião do Crepúsculo',
      ),
      TrailLevel(
        tier: AchievementTier.mestre,
        threshold: 500,
        description: '500 tardes concluídas',
        title: 'Senhor do Zênite',
      ),
    ],
  );

  static const noturno = AchievementTrail(
    id: 'noturno',
    name: 'O Noturno',
    emoji: '🌙',
    description: 'Hábitos da noite concluídos a 100%',
    levels: [
      TrailLevel(
        tier: AchievementTier.prata,
        threshold: 10,
        description: '10 noites concluídas',
        title: 'Passo Furtivo',
      ),
      TrailLevel(
        tier: AchievementTier.ouro,
        threshold: 30,
        description: '30 noites concluídas',
        title: 'Coruja Atenta',
      ),
      TrailLevel(
        tier: AchievementTier.platina,
        threshold: 75,
        description: '75 noites concluídas',
        title: 'Sombra Silenciosa',
      ),
      TrailLevel(
        tier: AchievementTier.esmeralda,
        threshold: 150,
        description: '150 noites concluídas',
        title: 'Espectro da Meia-Noite',
      ),
      TrailLevel(
        tier: AchievementTier.diamante,
        threshold: 300,
        description: '300 noites concluídas',
        title: 'Caçador Lunar',
      ),
      TrailLevel(
        tier: AchievementTier.mestre,
        threshold: 500,
        description: '500 noites concluídas',
        title: 'O Astro Noturno',
      ),
    ],
  );

  static const colecionador = AchievementTrail(
    id: 'colecionador',
    name: 'O Colecionador',
    emoji: '📚',
    description: 'Hábitos diferentes criados no app',
    levels: [
      TrailLevel(
        tier: AchievementTier.prata,
        threshold: 3,
        description: '3 hábitos criados',
        title: 'Primeiro Acervo',
      ),
      TrailLevel(
        tier: AchievementTier.ouro,
        threshold: 5,
        description: '5 hábitos criados',
        title: 'Guardião de Hábitos',
      ),
      TrailLevel(
        tier: AchievementTier.platina,
        threshold: 8,
        description: '8 hábitos criados',
        title: 'Curador de Rotinas',
      ),
      TrailLevel(
        tier: AchievementTier.esmeralda,
        threshold: 12,
        description: '12 hábitos criados',
        title: 'Arquivista Mestre',
      ),
      TrailLevel(
        tier: AchievementTier.diamante,
        threshold: 16,
        description: '16 hábitos criados',
        title: 'Senhor do Arsenal',
      ),
      TrailLevel(
        tier: AchievementTier.mestre,
        threshold: 20,
        description: '20 hábitos criados',
        title: 'O Lendário Colecionador',
      ),
    ],
  );

  static const guerreiro = AchievementTrail(
    id: 'guerreiro',
    name: 'O Guerreiro',
    emoji: '⚔️',
    description: 'Total de mini tarefas concluídas',
    levels: [
      TrailLevel(
        tier: AchievementTier.prata,
        threshold: 50,
        description: '50 tarefas concluídas',
        title: 'Escudeiro Ágil',
      ),
      TrailLevel(
        tier: AchievementTier.ouro,
        threshold: 150,
        description: '150 tarefas concluídas',
        title: 'Soldado Incansável',
      ),
      TrailLevel(
        tier: AchievementTier.platina,
        threshold: 300,
        description: '300 tarefas concluídas',
        title: 'Gladiador Focado',
      ),
      TrailLevel(
        tier: AchievementTier.esmeralda,
        threshold: 600,
        description: '600 tarefas concluídas',
        title: 'Ceifador de Tarefas',
      ),
      TrailLevel(
        tier: AchievementTier.diamante,
        threshold: 1000,
        description: '1000 tarefas concluídas',
        title: 'Senhor da Guerra',
      ),
      TrailLevel(
        tier: AchievementTier.mestre,
        threshold: 2000,
        description: '2000 tarefas concluídas',
        title: 'Lenda do Campo de Batalha',
      ),
    ],
  );

  /// Lista ordenada de todas as trilhas (para o ListView da tela)
  static const all = [
    constante,
    dedicado,
    perfeccionista,
    madrugador,
    vespertino,
    noturno,
    guerreiro,
    colecionador,
  ];

  // ── Helpers de título ──────────────────────────────────────

  /// Chave única para identificar um título: "trailId|tierIndex2"
  static String titleKey(String trailId, AchievementTier tier) =>
      '$trailId|${tier.index2}';

  /// Todos os níveis conquistados em todas as trilhas,
  /// ordenados por tier decrescente (Mestre primeiro).
  static List<({AchievementTrail trail, TrailLevel level})> allUnlockedLevels(
    Map<String, int> progress,
  ) {
    final result = <({AchievementTrail trail, TrailLevel level})>[];
    for (final trail in all) {
      final p = progress[trail.id] ?? 0;
      for (final lvl in trail.levels) {
        if (p >= lvl.threshold) result.add((trail: trail, level: lvl));
      }
    }
    result.sort((a, b) => b.level.tier.index2.compareTo(a.level.tier.index2));
    return result;
  }

  /// O nível conquistado de maior prestígio — usado como fallback automático
  static ({AchievementTrail trail, TrailLevel level})? highestEarnedLevel(
    Map<String, int> progress,
  ) {
    final list = allUnlockedLevels(progress);
    return list.isEmpty ? null : list.first;
  }

  /// Busca um nível específico pela sua chave ("trailId|tierIndex2").
  /// Retorna null se a chave for inválida ou o nível não tiver sido conquistado.
  static ({AchievementTrail trail, TrailLevel level})? levelByKey(
    String key,
    Map<String, int> progress,
  ) {
    final parts = key.split('|');
    if (parts.length != 2) return null;
    final trailId = parts[0];
    final tierIdx = int.tryParse(parts[1]);
    if (tierIdx == null) return null;
    try {
      final trail = all.firstWhere((t) => t.id == trailId);
      final p = progress[trail.id] ?? 0;
      for (final lvl in trail.levels) {
        if (lvl.tier.index2 == tierIdx && p >= lvl.threshold) {
          return (trail: trail, level: lvl);
        }
      }
    } catch (_) {}
    return null;
  }
}
