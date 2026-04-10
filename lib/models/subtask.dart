/// ─────────────────────────────────────────────────────────────
/// Subtask — mini tarefa de um hábito
/// ─────────────────────────────────────────────────────────────
class Subtask {
  final String id;
  final String nome;
  final bool   feita;

  const Subtask({
    required this.id,
    required this.nome,
    this.feita = false,
  });

  // ── Cópia com campo alterado ───────────────────────────────
  Subtask copyWith({String? id, String? nome, bool? feita}) => Subtask(
    id:    id    ?? this.id,
    nome:  nome  ?? this.nome,
    feita: feita ?? this.feita,
  );

  // ── Serialização ───────────────────────────────────────────
  Map<String, dynamic> toJson() => {
    'id':    id,
    'nome':  nome,
    'feita': feita,
  };

  factory Subtask.fromJson(Map<String, dynamic> json) => Subtask(
    id:    json['id']    as String,
    nome:  json['nome']  as String,
    feita: json['feita'] as bool? ?? false,
  );

  @override
  String toString() => 'Subtask(id: $id, nome: $nome, feita: $feita)';

  @override
  bool operator ==(Object other) =>
      other is Subtask && other.id == id && other.nome == nome && other.feita == feita;

  @override
  int get hashCode => Object.hash(id, nome, feita);
}
