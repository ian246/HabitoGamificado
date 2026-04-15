import '../core/utils/date_utils.dart';

/// ─────────────────────────────────────────────────────────────
/// Subtask — mini tarefa de um hábito
/// ─────────────────────────────────────────────────────────────
class Subtask {
  final String id;
  final String nome;
  final bool   feita;
  final DateTime criadoEm;

  Subtask({
    required this.id,
    required this.nome,
    this.feita = false,
    DateTime? criadoEm,
  }) : criadoEm = criadoEm ?? DateTime.now();

  // ── Cópia com campo alterado ───────────────────────────────
  Subtask copyWith({String? id, String? nome, bool? feita, DateTime? criadoEm}) => Subtask(
    id:    id    ?? this.id,
    nome:  nome  ?? this.nome,
    feita: feita ?? this.feita,
    criadoEm: criadoEm ?? this.criadoEm,
  );

  /// Verifica se a subtarefa foi criada HOJE (UTC).
  bool get isNewToday {
    final today = HabitDateUtils.todayKey();
    final createdDate = criadoEm.toUtc().toIso8601String().split('T')[0];
    return createdDate == today;
  }

  // ── Serialização ───────────────────────────────────────────
  Map<String, dynamic> toJson() => {
    'id':    id,
    'nome':  nome,
    'feita': feita,
    'criadoEm': criadoEm.toIso8601String(),
  };

  factory Subtask.fromJson(Map<String, dynamic> json) => Subtask(
    id:    json['id']    as String,
    nome:  json['nome']  as String,
    feita: json['feita'] as bool?   ?? false,
    criadoEm: json['criadoEm'] != null 
        ? DateTime.parse(json['criadoEm'] as String)
        : DateTime.now(),
  );

  @override
  String toString() => 'Subtask(id: $id, nome: $nome, feita: $feita)';

  @override
  bool operator ==(Object other) =>
      other is Subtask && other.id == id && other.nome == nome && other.feita == feita;

  @override
  int get hashCode => Object.hash(id, nome, feita);
}
