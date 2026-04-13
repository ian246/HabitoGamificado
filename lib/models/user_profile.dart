import 'dart:convert';
import 'achievement.dart';
import 'achievement_trail.dart';

/// ─────────────────────────────────────────────────────────────
/// UserProfile — perfil do usuário (v2: Firebase Auth + local)
///
/// Correções v2.1:
///   • apelido agora é persistido no Firebase ('apelido' em toFirebase)
///     e lido de volta em fromFirebase com fallback para split do displayName.
///   • totalAchievementsCount agora inclui trilhas desbloqueadas, não apenas
///     marcos por categoria — corrige stats.conquistas_total zerado no banco.
///   • fromFirebase preserva o apelido customizado pelo usuário entre
///     reinstalações e logins em novos dispositivos.
/// ─────────────────────────────────────────────────────────────
class UserProfile {
  // ── Campos de identidade (v2: Firebase) ──────────────────
  final String uid;
  final String email;
  final String photoUrl;
  final bool useLocalPhoto;

  // ── Campos locais originais (v1 — não alterados) ─────────
  final String nome;
  final String apelido;
  final String pinHash;
  final int xpTotal;
  final bool darkMode;
  final bool notificacoesAtivas;
  final DateTime criadoEm;
  final DateTime ultimoAcesso;
  final Map<AchievementCategory, Achievement> conquistas;
  final List<String> diasPerfeitos;
  final Map<String, int> trailProgress;
  final String? selectedTitleKey;
  final bool setupComplete;

  const UserProfile({
    this.uid = '',
    this.email = '',
    this.photoUrl = '',
    this.useLocalPhoto = false,
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
    this.setupComplete = false,
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

  // ── Factories Firebase (v2) ───────────────────────────────

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
  /// FIX v2.1: lê 'apelido' salvo no banco (campo novo).
  /// Fallback: split do displayName para perfis antigos que não tinham o campo.
  factory UserProfile.fromFirebase(String uid, Map<String, dynamic> data) {
    final stats = data['stats'] as Map? ?? {};
    final prefs = data['preferences'] as Map? ?? {};
    final gamification = data['gamification'] as Map? ?? {};

    final displayName = data['displayName'] as String? ?? '';

    // FIX: lê apelido do banco; fallback para split apenas em perfis antigos.
    final apelido = (data['apelido'] as String?)?.isNotEmpty == true
        ? data['apelido'] as String
        : displayName.split(' ').first;

    // Reconstrói conquistas
    final conquistasRaw = gamification['conquistas'] is Map
        ? Map<String, dynamic>.from(gamification['conquistas'] as Map)
        : <String, dynamic>{};

    final conquistas = <AchievementCategory, Achievement>{};
    for (final cat in AchievementCategory.values) {
      final raw = conquistasRaw[cat.valor];
      conquistas[cat] = raw != null
          ? Achievement.fromJson(Map<String, dynamic>.from(raw as Map))
          : Achievement(categoria: cat);
    }

    return UserProfile(
      uid: uid,
      email: data['email'] as String? ?? '',
      photoUrl: data['photoUrl'] as String? ?? '',
      nome: displayName,
      apelido: apelido, // FIX: usa o apelido persistido
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
      trailProgress: gamification['trailProgress'] is Map
          ? Map<String, int>.from(gamification['trailProgress'] as Map)
          : {},
      selectedTitleKey: gamification['selectedTitleKey'] as String?,
      setupComplete: prefs['setupComplete'] as bool? ?? true,
    );
  }

  /// Serializa para gravar no Realtime Database.
  ///
  /// FIX v2.1: inclui 'apelido' para preservar o nome customizado pelo usuário.
  /// FIX v2.1: conquistas_total agora conta trilhas desbloqueadas corretamente.
  Map<String, dynamic> toFirebase() {
    return {
      'displayName': nome,
      'apelido': apelido, // FIX: persiste o apelido customizado
      'email': email,
      'photoUrl': useLocalPhoto ? '' : photoUrl,
      'criadoEm': criadoEm.toIso8601String(),
      'stats': {
        'level': nivel,
        'xp': xpTotal,
        'rank': _rankFromLevel(nivel),
        // FIX: usa totalAchievementsCount que agora inclui trilhas
        'conquistas_total': totalAchievementsCount,
      },
      'preferences': {
        'theme': darkMode ? 'dark' : 'light',
        'notifications': notificacoesAtivas,
        'setupComplete': setupComplete,
      },
      'gamification': {
        'conquistas': conquistas.map((k, v) => MapEntry(k.valor, v.toJson())),
        'diasPerfeitos': diasPerfeitos,
        'trailProgress': trailProgress,
        if (selectedTitleKey != null) 'selectedTitleKey': selectedTitleKey,
      },
    };
  }

  String get rank => _rankFromLevel(nivel);

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

  bool get isFirebaseUser => uid.isNotEmpty;
  String get effectivePhotoUrl => photoUrl;

  /// FIX v2.1: conta TANTO marcos de categoria QUANTO tiers de trilha desbloqueados.
  ///
  /// Antes: contava apenas marcosDesbloqueados nas categorias → sempre 0 quando
  ///        o usuário só progrediu nas trilhas, sem hábitos completos por categoria.
  ///
  /// Agora: soma marcosDesbloqueados (categorias) + tiers de trilha alcançados.
  int get totalAchievementsCount {
    // Conquistas por categoria (Achievement.marcosDesbloqueados)
    int count = conquistas.values.fold(
      0,
      (sum, a) => sum + a.marcosDesbloqueados.length,
    );

    // Trilhas: cada tier cujo threshold foi atingido conta como 1 conquista
    for (final trail in AchievementTrails.all) {
      final progress = trailProgress[trail.id] ?? 0;
      for (final tier in trail.levels) {
        if (progress >= tier.threshold) count++;
      }
    }

    return count;
  }

  // ── copyWith ──────────────────────────────────────────────
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
    bool? setupComplete,
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
    setupComplete: setupComplete ?? this.setupComplete,
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
    'uid': uid,
    'email': email,
    'photoUrl': photoUrl,
    'useLocalPhoto': useLocalPhoto,
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
    'setupComplete': setupComplete,
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
      uid: json['uid'] as String? ?? '',
      email: json['email'] as String? ?? '',
      photoUrl: json['photoUrl'] as String? ?? '',
      useLocalPhoto: json['useLocalPhoto'] as bool? ?? false,
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
      setupComplete: json['setupComplete'] as bool? ?? true,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory UserProfile.fromJsonString(String raw) =>
      UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  @override
  String toString() =>
      'UserProfile(apelido: $apelido, nivel: $nivel, xp: $xpTotal, uid: $uid)';

  static String _rankFromLevel(int nivel) {
    const ranks = [
      'Prata',
      'Prata',
      'Ouro',
      'Ouro',
      'Platina',
      'Platina',
      'Esmeralda',
      'Diamante',
      'Mestre',
    ];
    return ranks[(nivel - 1).clamp(0, 8)];
  }
}
