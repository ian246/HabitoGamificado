import 'dart:convert';
import 'achievement.dart';
import 'achievement_trail.dart';

/// ─────────────────────────────────────────────────────────────
/// UserProfile — perfil do usuário (v2: Firebase Auth + local)
///
/// O que mudou em relação à v1:
///   + uid          → Firebase UID (vazio = perfil local legado)
///   + email        → conta Google conectada
///   + photoUrl     → URL remota (Google) ou caminho local
///   + useLocalPhoto → true quando o usuário trocou a foto via image_picker
///   + factory UserProfile.newFromGoogle  → novo usuário Google
///   + factory UserProfile.fromFirebase   → carrega do Realtime Database
///   + toFirebase()                       → serializa para o banco
///
/// O que NÃO mudou:
///   - Todos os campos de gamificação (xpTotal, conquistas, trailProgress…)
///   - Toda a lógica derivada (nivel, nomeDonivel, progressoNivel, activeTitle…)
///   - copyWith, toJson, fromJson, fromJsonString (compatibilidade v1 total)
///   - pinHash mantido (usuários legados que usam PIN continuam funcionando)
/// ─────────────────────────────────────────────────────────────
class UserProfile {
  // ── Campos de identidade (v2: Firebase) ──────────────────
  /// Firebase UID. Vazio em perfis locais legados da v1.
  final String uid;

  /// E-mail da conta Google. Vazio em perfis locais.
  final String email;

  /// URL remota (foto do Google) OU caminho local (image_picker).
  /// Use [effectivePhotoUrl] para resolver qual exibir.
  final String photoUrl;

  /// true = [photoUrl] é um caminho local (usuário trocou a foto).
  /// false = [photoUrl] é uma URL remota do Google.
  final bool useLocalPhoto;

  // ── Campos locais originais (v1 — não alterados) ─────────
  final String nome;
  final String apelido;
  final String pinHash; // SHA-256 do PIN — vazio para usuários Google
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

  /// Chave do título escolhido pelo usuário (formato: "trailId|tierIndex2").
  /// Null = usar o fallback automático (maior tier conquistado).
  final String? selectedTitleKey;

  const UserProfile({
    // v2
    this.uid = '',
    this.email = '',
    this.photoUrl = '',
    this.useLocalPhoto = false,
    // v1 (sem alteração)
    required this.nome,
    required this.apelido,
    this.pinHash = '',
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

  // ── Factory original (v1 — não alterado) ─────────────────
  factory UserProfile.create({
    required String nome,
    required String apelido,
    required String pinHash,
  }) {
    final now = DateTime.now();
    return UserProfile(
      nome: nome,
      apelido: apelido,
      pinHash: pinHash,
      criadoEm: now,
      ultimoAcesso: now,
      conquistas: {
        for (final cat in AchievementCategory.values)
          cat: Achievement(categoria: cat),
      },
      trailProgress: const {},
    );
  }

  // ── Factories Firebase (v2 — novos) ───────────────────────

  /// Cria perfil para novo usuário que logou com Google pela primeira vez.
  /// Gamificação começa do zero; dados de identidade vêm do Google.
  factory UserProfile.newFromGoogle({
    required String uid,
    required String displayName,
    required String email,
    required String photoUrl,
  }) {
    final now = DateTime.now();
    return UserProfile(
      uid: uid,
      email: email,
      photoUrl: photoUrl,
      nome: displayName,
      apelido: displayName.split(' ').first,
      criadoEm: now,
      ultimoAcesso: now,
      conquistas: {
        for (final cat in AchievementCategory.values)
          cat: Achievement(categoria: cat),
      },
      trailProgress: const {},
    );
  }

  /// Reconstrói o perfil a partir do snapshot do Realtime Database.
  ///
  /// Estratégia de merge:
  ///   - Campos de gamificação (xpTotal, conquistas, trailProgress, diasPerfeitos)
  ///     são lidos do banco se existirem, senão voltam ao zero.
  ///   - conquistas e trailProgress ficam no banco em formato JSON para
  ///     preservar todo o progresso entre reinstalações.
  factory UserProfile.fromFirebase(String uid, Map<String, dynamic> data) {
    final stats = data['stats'] as Map? ?? {};
    final prefs = data['preferences'] as Map? ?? {};
    final gamification = data['gamification'] as Map? ?? {};

    // Reconstrói conquistas (se salvas no banco)
    final conquistasRaw =
        gamification['conquistas'] as Map<String, dynamic>? ?? {};
    final conquistas = <AchievementCategory, Achievement>{};
    for (final cat in AchievementCategory.values) {
      final raw = conquistasRaw[cat.valor];
      conquistas[cat] = raw != null
          ? Achievement.fromJson(raw as Map<String, dynamic>)
          : Achievement(categoria: cat);
    }

    return UserProfile(
      uid: uid,
      email: data['email'] as String? ?? '',
      photoUrl: data['photoUrl'] as String? ?? '',
      nome: data['displayName'] as String? ?? '',
      apelido: (data['displayName'] as String? ?? '').split(' ').first,
      xpTotal: (stats['xp'] as num?)?.toInt() ?? 0,
      darkMode: prefs['theme'] == 'dark',
      notificacoesAtivas: prefs['notifications'] as bool? ?? true,
      criadoEm: data['criadoEm'] != null
          ? DateTime.parse(data['criadoEm'] as String)
          : DateTime.now(),
      ultimoAcesso: DateTime.now(),
      conquistas: conquistas,
      diasPerfeitos: List<String>.from(
        gamification['diasPerfeitos'] as List? ?? [],
      ),
      trailProgress: Map<String, int>.from(
        gamification['trailProgress'] as Map? ?? {},
      ),
      selectedTitleKey: gamification['selectedTitleKey'] as String?,
    );
  }

  /// Serializa para gravar no Realtime Database.
  ///
  /// Estrutura flat com 3 nós:
  ///   stats        → dados de gamificação (level, xp, rank)
  ///   preferences  → tema, notificações
  ///   gamification → conquistas, trilhas, diasPerfeitos (preserva progresso)
  Map<String, dynamic> toFirebase() {
    return {
      'displayName': nome,
      'email': email,
      // Não sobe caminho local para o banco — só URL remota
      'photoUrl': useLocalPhoto ? '' : photoUrl,
      'criadoEm': criadoEm.toIso8601String(),
      'stats': {'level': nivel, 'xp': xpTotal, 'rank': _rankFromLevel(nivel)},
      'preferences': {
        'theme': darkMode ? 'dark' : 'light',
        'notifications': notificacoesAtivas,
      },
      // Gamificação completa sobe para o banco — preserva tudo entre reinstalações
      'gamification': {
        'conquistas': conquistas.map((k, v) => MapEntry(k.valor, v.toJson())),
        'diasPerfeitos': diasPerfeitos,
        'trailProgress': trailProgress,
        if (selectedTitleKey != null) 'selectedTitleKey': selectedTitleKey,
      },
    };
  }

  // ── Propriedades derivadas (v1 — não alteradas) ───────────

  int get nivel {
    const xpLevels = [0, 150, 350, 700, 1200, 2000, 3000, 5000, 8000];
    int level = 1;
    for (int i = 0; i < xpLevels.length; i++) {
      if (xpTotal >= xpLevels[i]) level = i + 1;
    }
    return level.clamp(1, 9);
  }

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

  int get xpProximoNivel {
    const xpLevels = [150, 350, 700, 1200, 2000, 3000, 5000, 8000, 8000];
    return xpLevels[nivel - 1];
  }

  int get xpNivelAtual {
    const xpLevels = [0, 150, 350, 700, 1200, 2000, 3000, 5000, 8000];
    return xpLevels[nivel - 1];
  }

  double get progressoNivel {
    final range = xpProximoNivel - xpNivelAtual;
    if (range <= 0) return 1.0;
    return ((xpTotal - xpNivelAtual) / range).clamp(0.0, 1.0);
  }

  ({AchievementTrail trail, TrailLevel level})? get activeTitle {
    if (selectedTitleKey != null) {
      final found = AchievementTrails.levelByKey(
        selectedTitleKey!,
        trailProgress,
      );
      if (found != null) return found;
    }
    return AchievementTrails.highestEarnedLevel(trailProgress);
  }

  // ── Propriedade auxiliar (v2) ─────────────────────────────

  /// True se o perfil está vinculado ao Firebase (UID real).
  bool get isFirebaseUser => uid.isNotEmpty;

  /// Resolve qual URL/caminho exibir como foto de perfil.
  /// Prioridade: foto local trocada pelo usuário > URL do Google > vazio.
  String get effectivePhotoUrl => photoUrl;

  // ── copyWith (v1 + v2 campos adicionados) ────────────────
  UserProfile copyWith({
    String? uid,
    String? email,
    String? photoUrl,
    bool? useLocalPhoto,
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
    uid: uid ?? this.uid,
    email: email ?? this.email,
    photoUrl: photoUrl ?? this.photoUrl,
    useLocalPhoto: useLocalPhoto ?? this.useLocalPhoto,
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

  // ── Métodos de negócio (v1 — não alterados) ──────────────

  UserProfile incrementarTrilha(String trailId, int quantidade) {
    final novo = Map<String, int>.from(trailProgress);
    novo[trailId] = (novo[trailId] ?? 0) + quantidade;
    return copyWith(trailProgress: novo);
  }

  UserProfile adicionarXp(int quantidade) =>
      copyWith(xpTotal: xpTotal + quantidade);

  UserProfile atualizarConquista(AchievementCategory cat, Achievement nova) {
    final novas = Map<AchievementCategory, Achievement>.from(conquistas);
    novas[cat] = nova;
    return copyWith(conquistas: novas);
  }

  UserProfile registrarDiaPerfeito(String chaveData) {
    if (diasPerfeitos.contains(chaveData)) return this;
    return copyWith(diasPerfeitos: [...diasPerfeitos, chaveData]);
  }

  UserProfile atualizarAcesso() => copyWith(ultimoAcesso: DateTime.now());

  // ── Serialização local (v1 — não alterada) ───────────────
  Map<String, dynamic> toJson() => {
    // v2
    'uid': uid,
    'email': email,
    'photoUrl': photoUrl,
    'useLocalPhoto': useLocalPhoto,
    // v1
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
      // v2 (com fallback para perfis antigos que não tinham esses campos)
      uid: json['uid'] as String? ?? '',
      email: json['email'] as String? ?? '',
      photoUrl: json['photoUrl'] as String? ?? '',
      useLocalPhoto: json['useLocalPhoto'] as bool? ?? false,
      // v1 (não alterado)
      nome: json['nome'] as String,
      apelido: json['apelido'] as String,
      pinHash: json['pinHash'] as String? ?? '',
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
      'UserProfile(apelido: $apelido, nivel: $nivel, xp: $xpTotal, uid: $uid)';

  // ── Helpers privados ──────────────────────────────────────
  static String _rankFromLevel(int nivel) {
    const ranks = [
      'Bronze',
      'Bronze',
      'Prata',
      'Prata',
      'Ouro',
      'Ouro',
      'Platina',
      'Esmeralda',
      'Mestre',
    ];
    return ranks[(nivel - 1).clamp(0, 8)];
  }
}
