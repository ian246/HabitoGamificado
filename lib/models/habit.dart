import 'dart:convert';
import 'subtask.dart';

/// ─────────────────────────────────────────────────────────────
/// Habit — modelo principal do HabitFlow
///
/// Período:    'manha' | 'tarde' | 'noite'
/// Frequência: 'diario' | 'seg-sex' | 'custom'
///
/// historicoConclusao — Map<'yyyy-MM-dd', double>
///   valor 0.0 = nenhuma subtarefa feita
///   valor 1.0 = todas as subtarefas feitas
///   valor 0.5 = metade feita
/// ─────────────────────────────────────────────────────────────
class Habit {
  final String              id;
  final String              nome;
  final String              icone;
  final String              cor;           // hex ex: '#4A9E7C'
  final String              periodo;       // 'manha' | 'tarde' | 'noite'
  final String              frequencia;    // 'diario' | 'seg-sex' | 'custom'
  final List<int>           diasCustom;    // [1,2,3,4,5] = seg a sex (weekday Dart)
  final String              notificacaoHora; // 'HH:mm' ex: '07:30'
  final bool                notificacaoAtiva;
  final List<Subtask>       miniTarefas;
  final int                 streakAtual;
  final int                 melhorStreak;
  final Map<String, double> historicoConclusao;
  final DateTime            criadoEm;

  const Habit({
    required this.id,
    required this.nome,
    required this.icone,
    required this.cor,
    required this.periodo,
    required this.frequencia,
    required this.diasCustom,
    required this.notificacaoHora,
    required this.notificacaoAtiva,
    required this.miniTarefas,
    required this.streakAtual,
    required this.melhorStreak,
    required this.historicoConclusao,
    required this.criadoEm,
  });

  // ── Factory para criar um hábito novo ─────────────────────
  factory Habit.create({
    required String       id,
    required String       nome,
    required String       icone,
    String                cor              = '#4A9E7C',
    String                periodo          = 'manha',
    String                frequencia       = 'diario',
    List<int>             diasCustom       = const [],
    String                notificacaoHora  = '08:00',
    bool                  notificacaoAtiva = true,
    required List<Subtask> miniTarefas,
  }) => Habit(
    id:                  id,
    nome:                nome,
    icone:               icone,
    cor:                 cor,
    periodo:             periodo,
    frequencia:          frequencia,
    diasCustom:          diasCustom,
    notificacaoHora:     notificacaoHora,
    notificacaoAtiva:    notificacaoAtiva,
    miniTarefas:         miniTarefas,
    streakAtual:         0,
    melhorStreak:        0,
    historicoConclusao:  {},
    criadoEm:            DateTime.now(),
  );

  // ── Propriedades derivadas ────────────────────────────────

  /// Subtarefas concluídas hoje
  int get subtarefasFeitas => miniTarefas.where((s) => s.feita).length;

  /// Total de subtarefas
  int get totalSubtarefas => miniTarefas.length;

  /// Progresso de 0.0 a 1.0 (baseado nas subtarefas do dia)
  double get progressoHoje {
    if (miniTarefas.isEmpty) return 0.0;
    return subtarefasFeitas / totalSubtarefas;
  }

  /// Verdadeiro se todas as subtarefas foram feitas
  bool get completoHoje => progressoHoje >= 1.0;

  /// Progresso histórico de uma data específica ('yyyy-MM-dd')
  double progressoNaData(String chave) => historicoConclusao[chave] ?? 0.0;

  /// Verifica se o hábito deve ser exibido hoje (baseado na frequência)
  bool get ativoHoje {
    if (frequencia == 'diario') return true;
    if (frequencia == 'seg-sex') {
      final dow = DateTime.now().weekday; // 1=seg ... 7=dom
      return dow >= 1 && dow <= 5;
    }
    if (frequencia == 'custom' && diasCustom.isNotEmpty) {
      return diasCustom.contains(DateTime.now().weekday);
    }
    return true;
  }

  // ── copyWith ──────────────────────────────────────────────
  Habit copyWith({
    String?              id,
    String?              nome,
    String?              icone,
    String?              cor,
    String?              periodo,
    String?              frequencia,
    List<int>?           diasCustom,
    String?              notificacaoHora,
    bool?                notificacaoAtiva,
    List<Subtask>?       miniTarefas,
    int?                 streakAtual,
    int?                 melhorStreak,
    Map<String, double>? historicoConclusao,
    DateTime?            criadoEm,
  }) => Habit(
    id:                  id                 ?? this.id,
    nome:                nome               ?? this.nome,
    icone:               icone              ?? this.icone,
    cor:                 cor                ?? this.cor,
    periodo:             periodo            ?? this.periodo,
    frequencia:          frequencia         ?? this.frequencia,
    diasCustom:          diasCustom         ?? this.diasCustom,
    notificacaoHora:     notificacaoHora    ?? this.notificacaoHora,
    notificacaoAtiva:    notificacaoAtiva   ?? this.notificacaoAtiva,
    miniTarefas:         miniTarefas        ?? this.miniTarefas,
    streakAtual:         streakAtual        ?? this.streakAtual,
    melhorStreak:        melhorStreak       ?? this.melhorStreak,
    historicoConclusao:  historicoConclusao ?? this.historicoConclusao,
    criadoEm:            criadoEm           ?? this.criadoEm,
  );

  // ── Marcar/desmarcar subtarefa ────────────────────────────
  /// Retorna um novo Habit com a subtarefa alternada
  Habit toggleSubtask(String subtaskId) {
    final novaLista = miniTarefas.map((s) {
      return s.id == subtaskId ? s.copyWith(feita: !s.feita) : s;
    }).toList();
    return copyWith(miniTarefas: novaLista);
  }

  /// Retorna um novo Habit com o histórico do dia salvo
  /// Chame isso ao final do dia ou ao concluir 100%
  Habit salvarProgressoHoje(String chaveData) {
    final novoHistorico = Map<String, double>.from(historicoConclusao);
    novoHistorico[chaveData] = progressoHoje;
    return copyWith(historicoConclusao: novoHistorico);
  }

  /// Retorna um novo Habit com streak atualizado
  Habit atualizarStreak(int novoStreak) => copyWith(
    streakAtual:  novoStreak,
    melhorStreak: novoStreak > melhorStreak ? novoStreak : melhorStreak,
  );

  /// Reseta as subtarefas para o novo dia (todas desmarcadas)
  Habit resetarParaHoje() {
    final resetadas = miniTarefas
        .map((s) => s.copyWith(feita: false))
        .toList();
    return copyWith(miniTarefas: resetadas);
  }

  // ── Serialização JSON ────────────────────────────────────
  Map<String, dynamic> toJson() => {
    'id':                  id,
    'nome':                nome,
    'icone':               icone,
    'cor':                 cor,
    'periodo':             periodo,
    'frequencia':          frequencia,
    'diasCustom':          diasCustom,
    'notificacaoHora':     notificacaoHora,
    'notificacaoAtiva':    notificacaoAtiva,
    'miniTarefas':         miniTarefas.map((s) => s.toJson()).toList(),
    'streakAtual':         streakAtual,
    'melhorStreak':        melhorStreak,
    'historicoConclusao':  historicoConclusao,
    'criadoEm':            criadoEm.toIso8601String(),
  };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
    id:               json['id']               as String,
    nome:             json['nome']             as String,
    icone:            json['icone']            as String,
    cor:              json['cor']              as String? ?? '#4A9E7C',
    periodo:          json['periodo']          as String? ?? 'manha',
    frequencia:       json['frequencia']       as String? ?? 'diario',
    diasCustom:       List<int>.from(json['diasCustom'] as List? ?? []),
    notificacaoHora:  json['notificacaoHora']  as String? ?? '08:00',
    notificacaoAtiva: json['notificacaoAtiva'] as bool?   ?? true,
    miniTarefas: (json['miniTarefas'] as List? ?? [])
        .map((e) => Subtask.fromJson(e as Map<String, dynamic>))
        .toList(),
    streakAtual:  json['streakAtual']  as int? ?? 0,
    melhorStreak: json['melhorStreak'] as int? ?? 0,
    historicoConclusao: (json['historicoConclusao'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, (v as num).toDouble())),
    criadoEm: DateTime.parse(json['criadoEm'] as String),
  );

  /// Serializa para String (usado no SharedPreferences)
  String toJsonString() => jsonEncode(toJson());

  factory Habit.fromJsonString(String raw) =>
      Habit.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  @override
  String toString() => 'Habit(id: $id, nome: $nome, streak: $streakAtual)';

  @override
  bool operator ==(Object other) => other is Habit && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
