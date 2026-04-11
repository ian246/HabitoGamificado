import 'dart:convert';
import 'achievement.dart';
import 'achievement_trail.dart';

/// ─────────────────────────────────────────────────────────────
/// UserProfile — perfil local do usuário
///
/// Salvo inteiro em SharedPreferences['user_profile'].
/// Não há autenticação remota na v1 — tudo é local.
/// ─────────────────────────────────────────────────────────────
class UserProfile {
  final String nome;
  final String apelido;
  final String pinHash; // SHA-256 do PIN (nunca texto puro)
  final int xpTotal;
  final bool darkMode;
  final bool notificacoesAtivas;
  final DateTime criadoEm;
  final DateTime ultimoAcesso;

  /// Uma conquista por categoria
  final Map<AchievementCategory, Achievement> conquistas;

  /// Datas em que todos os hábitos foram 100% concluídos
  final List<String> diasPerfeitos;

  /// Progresso de cada trilha de conquista.
  /// Chave = AchievementTrail.id   Valor = progresso atual (int)
  final Map<String, int> trailProgress;

  /// Chave do título escolhido pelo usuário para exibição (formato: "trailId|tierIndex2").
  /// Null significa usar o fallback automático (maior tier conquistado).
  final String? selectedTitleKey;

  const UserProfile({
    required this.nome,
    required this.apelido,
    required this.pinHash,
    this.xpTotal = 0,
    this.darkMode = true,
    this.notificacoesAtivas = true,
    required this.criadoEm,
    required this.ultimoAcesso,
    this.conquistas = const {},
    this.diasPerfeitos = const [],
    this.trailProgress = const {},
    this.selectedTitleKey,
  });

  // ── Factory para novo perfil ──────────────────────────────
  factory UserProfile.create({
    required String nome,
    required String apelido,
    required String pinHash,
  }) {
    final now = DateTime.now();

    // Cria conquistas iniciais para todas as categorias
    final conquistas = <AchievementCategory, Achievement>{
      for (final cat in AchievementCategory.values)
        cat: Achievement(categoria: cat),
    };

    return UserProfile(
      nome: nome,
      apelido: apelido,
      pinHash: pinHash,
      criadoEm: now,
      ultimoAcesso: now,
      conquistas: conquistas,
      trailProgress: const {},
    );
  }

  // ── Propriedades derivadas ────────────────────────────────

  /// Nível atual (1–9) baseado no XP total
  int get nivel {
    const xpLevels = [0, 150, 350, 700, 1200, 2000, 3000, 5000, 8000];
    int level = 1;
    for (int i = 0; i < xpLevels.length; i++) {
      if (xpTotal >= xpLevels[i]) level = i + 1;
    }
    return level.clamp(1, 9);
  }

  /// Nome do nível atual
  String get nomeDonivel {
    const nomes = [
      'Broto',
      'Muda',
      'Arbusto',
      'Árvore',
      'Floresta',
      'Estrela',
      'Oceano',
      'Cosmos',
      'Mestre',
    ];
    return nomes[nivel - 1];
  }

  /// XP necessário para o próximo nível
  int get xpProximoNivel {
    const xpLevels = [150, 350, 700, 1200, 2000, 3000, 5000, 8000, 8000];
    return xpLevels[nivel - 1];
  }

  /// XP do início do nível atual
  int get xpNivelAtual {
    const xpLevels = [0, 150, 350, 700, 1200, 2000, 3000, 5000, 8000];
    return xpLevels[nivel - 1];
  }

  /// Progresso de 0.0 a 1.0 dentro do nível atual
  double get progressoNivel {
    final range = xpProximoNivel - xpNivelAtual;
    if (range <= 0) return 1.0;
    return ((xpTotal - xpNivelAtual) / range).clamp(0.0, 1.0);
  }

  // ── Título ativo ──────────────────────────────────────────

  /// Retorna o título que deve ser exibido no app.
  /// Usa o título selecionado pelo usuário; se nenhum, usa o de maior prestígio.
  ({AchievementTrail trail, TrailLevel level})? get activeTitle {
    if (selectedTitleKey != null) {
      final found = AchievementTrails.levelByKey(selectedTitleKey!, trailProgress);
      if (found != null) return found;
    }
    return AchievementTrails.highestEarnedLevel(trailProgress);
  }

  // ── copyWith ─────────────────────────────────────────────
  UserProfile copyWith({
    String? nome,
    String? apelido,
    String? pinHash,
    int? xpTotal,
    bool? darkMode,
    bool? notificacoesAtivas,
    DateTime? criadoEm,
    DateTime? ultimoAcesso,
    Map<AchievementCategory, Achievement>? conquistas,
    List<String>? diasPerfeitos,
    Map<String, int>? trailProgress,
    Object? selectedTitleKey = _sentinel,
  }) => UserProfile(
    nome: nome ?? this.nome,
    apelido: apelido ?? this.apelido,
    pinHash: pinHash ?? this.pinHash,
    xpTotal: xpTotal ?? this.xpTotal,
    darkMode: darkMode ?? this.darkMode,
    notificacoesAtivas: notificacoesAtivas ?? this.notificacoesAtivas,
    criadoEm: criadoEm ?? this.criadoEm,
    ultimoAcesso: ultimoAcesso ?? this.ultimoAcesso,
    conquistas: conquistas ?? this.conquistas,
    diasPerfeitos: diasPerfeitos ?? this.diasPerfeitos,
    trailProgress: trailProgress ?? this.trailProgress,
    selectedTitleKey: selectedTitleKey == _sentinel
        ? this.selectedTitleKey
        : selectedTitleKey as String?,
  );

  static const Object _sentinel = Object();

  /// Incrementa o progresso de uma trilha de conquistas
  UserProfile incrementarTrilha(String trailId, int quantidade) {
    final novo = Map<String, int>.from(trailProgress);
    novo[trailId] = (novo[trailId] ?? 0) + quantidade;
    return copyWith(trailProgress: novo);
  }

  /// Adiciona XP e retorna o perfil atualizado
  UserProfile adicionarXp(int quantidade) =>
      copyWith(xpTotal: xpTotal + quantidade);

  /// Atualiza a conquista de uma categoria
  UserProfile atualizarConquista(AchievementCategory cat, Achievement nova) {
    final novas = Map<AchievementCategory, Achievement>.from(conquistas);
    novas[cat] = nova;
    return copyWith(conquistas: novas);
  }

  /// Registra um dia perfeito
  UserProfile registrarDiaPerfeito(String chaveData) {
    if (diasPerfeitos.contains(chaveData)) return this;
    return copyWith(diasPerfeitos: [...diasPerfeitos, chaveData]);
  }

  /// Atualiza o último acesso para agora
  UserProfile atualizarAcesso() => copyWith(ultimoAcesso: DateTime.now());

  // ── Serialização ─────────────────────────────────────────
  Map<String, dynamic> toJson() => {
    'nome': nome,
    'apelido': apelido,
    'pinHash': pinHash,
    'xpTotal': xpTotal,
    'darkMode': darkMode,
    'notificacoesAtivas': notificacoesAtivas,
    'criadoEm': criadoEm.toIso8601String(),
    'ultimoAcesso': ultimoAcesso.toIso8601String(),
    'conquistas': conquistas.map((k, v) => MapEntry(k.valor, v.toJson())),
    'diasPerfeitos': diasPerfeitos,
    'trailProgress': trailProgress,
    if (selectedTitleKey != null) 'selectedTitleKey': selectedTitleKey,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final conquistasRaw = json['conquistas'] as Map<String, dynamic>? ?? {};
    final conquistas = <AchievementCategory, Achievement>{};
    for (final cat in AchievementCategory.values) {
      final raw = conquistasRaw[cat.valor];
      conquistas[cat] = raw != null
          ? Achievement.fromJson(raw as Map<String, dynamic>)
          : Achievement(categoria: cat);
    }

    return UserProfile(
      nome: json['nome'] as String,
      apelido: json['apelido'] as String,
      pinHash: json['pinHash'] as String,
      xpTotal: json['xpTotal'] as int? ?? 0,
      darkMode: json['darkMode'] as bool? ?? true,
      notificacoesAtivas: json['notificacoesAtivas'] as bool? ?? true,
      criadoEm: DateTime.parse(json['criadoEm'] as String),
      ultimoAcesso: DateTime.parse(json['ultimoAcesso'] as String),
      conquistas: conquistas,
      diasPerfeitos: List<String>.from(json['diasPerfeitos'] as List? ?? []),
      trailProgress: Map<String, int>.from(json['trailProgress'] as Map? ?? {}),
      selectedTitleKey: json['selectedTitleKey'] as String?,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory UserProfile.fromJsonString(String raw) =>
      UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  @override
  String toString() =>
      'UserProfile(apelido: $apelido, nivel: $nivel, xp: $xpTotal)';
}
