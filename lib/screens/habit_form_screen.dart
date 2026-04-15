import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/habit.dart';
import '../models/subtask.dart';
import '../services/storage_service.dart';
import '../core/utils/date_utils.dart';
import '../core/theme/app_text_styles.dart';

class HabitFormScreen extends StatefulWidget {
  final Habit? habitParaEditar;

  const HabitFormScreen({super.key, this.habitParaEditar});

  bool get isEditing => habitParaEditar != null;

  @override
  State<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends State<HabitFormScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _uuid     = const Uuid();

  String        _icone           = '🌱';
  String        _cor             = '#4A9E7C';
  String        _periodo         = 'manha';
  String        _frequencia      = 'diario';
  TimeOfDay     _horarioNotif    = const TimeOfDay(hour: 8, minute: 0);
  bool          _notifAtiva      = true;
  List<TextEditingController> _subtaskCtrls = [];

  static const _emojis = [
    '🌱','💧','📚','🏃','🧘','🐶','🌿','💪','🎯','✍️',
    '🎸','🍎','🌅','☀️','🌙','🏋️','🚴','🧹','🛌','🍵',
    '💊','🎨','🧠','❤️','🌊','🔥','⭐','🎵','📝','🤸',
  ];

  static const _cores = [
    '#4A9E7C', '#3A6B9E', '#9B59B6',
    '#F0B86A', '#E57373', '#50C878',
  ];

  @override
  void initState() {
    super.initState();
    final h = widget.habitParaEditar;
    if (h != null) {
      _nomeCtrl.text  = h.nome;
      _icone          = h.icone;
      _cor            = h.cor;
      _periodo        = h.periodo;
      _frequencia     = h.frequencia;
      _notifAtiva     = h.notificacaoAtiva;
      final parts     = h.notificacaoHora.split(':');
      _horarioNotif   = TimeOfDay(
        hour:   int.tryParse(parts[0]) ?? 8,
        minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
      );
      _subtaskCtrls = h.miniTarefas
          .map((s) => TextEditingController(text: s.nome))
          .toList();
    } else {
      _subtaskCtrls = [TextEditingController()];
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    for (final c in _subtaskCtrls) c.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _horarioNotif,
    );
    if (picked != null) setState(() => _horarioNotif = picked);
  }

  void _addSubtask() {
    if (_subtaskCtrls.length >= 8) return;
    setState(() => _subtaskCtrls.add(TextEditingController()));
  }

  void _removeSubtask(int index) {
    if (_subtaskCtrls.length <= 1) return;
    setState(() {
      _subtaskCtrls[index].dispose();
      _subtaskCtrls.removeAt(index);
    });
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;

    final hOrig = widget.habitParaEditar;
    final subtarefas = <Subtask>[];

    for (var i = 0; i < _subtaskCtrls.length; i++) {
      final text = _subtaskCtrls[i].text.trim();
      if (text.isEmpty) continue;

      // Se estamos editando, tenta encontrar a subtarefa original pelo índice ou nome
      // para preservar ID, estado 'feita' e 'criadoEm'.
      Subtask? original;
      if (hOrig != null && i < hOrig.miniTarefas.length) {
        original = hOrig.miniTarefas[i];
      }

      if (original != null && original.nome == text) {
        subtarefas.add(original);
      } else {
        // Se mudou o nome ou é nova, cria uma nova subtarefa
        subtarefas.add(Subtask(
          id: _uuid.v4(),
          nome: text,
        ));
      }
    }

    if (subtarefas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos uma mini tarefa.')),
      );
      return;
    }

    final hora = '${_horarioNotif.hour.toString().padLeft(2, '0')}:'
        '${_horarioNotif.minute.toString().padLeft(2, '0')}';

    final Habit habit;
    if (widget.isEditing) {
      habit = widget.habitParaEditar!.copyWith(
        nome:            _nomeCtrl.text.trim(),
        icone:           _icone,
        cor:             _cor,
        periodo:         _periodo,
        frequencia:      _frequencia,
        notificacaoHora: hora,
        notificacaoAtiva: _notifAtiva,
        miniTarefas:     subtarefas,
      );
    } else {
      // Regra de Negócio: Limite de criação diária (Anti-Spam)
      final profile = StorageService.instance.loadProfile();
      if (profile != null) {
        final today = HabitDateUtils.todayKey();
        if (!profile.canCreateHabitToday(today)) {
          _showLimitReachedDialog();
          return;
        }
      }

      habit = Habit.create(
        id:              _uuid.v4(),
        nome:            _nomeCtrl.text.trim(),
        icone:           _icone,
        cor:             _cor,
        periodo:         _periodo,
        frequencia:      _frequencia,
        notificacaoHora: hora,
        notificacaoAtiva: _notifAtiva,
        miniTarefas:     subtarefas,
      );
    }

    Navigator.of(context).pop(habit);
  }

  void _showLimitReachedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Limite Diário'),
          ],
        ),
        content: const Text(
          'Você atingiu o limite de 3 novos hábitos por dia.\n\nFoque em manter a consistência com os hábitos atuais antes de adicionar mais! 🔥',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar hábito' : 'Novo hábito'),
        actions: [
          TextButton(
            onPressed: _salvar,
            child: const Text('Salvar',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Nome ──────────────────────────────────────
            _SectionCard(
              children: [
                _label('Nome do hábito'),
                const SizedBox(height: 8),
                TextFormField(
                  controller:         _nomeCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength:          40,
                  decoration: const InputDecoration(
                    hintText:    'Ex: Meditação matinal',
                    counterText: '',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Dê um nome ao hábito'
                          : null,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Ícone ─────────────────────────────────────
            _SectionCard(
              children: [
                Row(
                  children: [
                    _label('Ícone'),
                    const Spacer(),
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(_icone,
                          style: const TextStyle(fontSize: 20)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _emojis.map((e) {
                    final selected = e == _icone;
                    return GestureDetector(
                      onTap: () => setState(() => _icone = e),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary.withAlpha(30)
                              : AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(10),
                          border: selected
                              ? Border.all(color: AppColors.primary, width: 2)
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(e,
                            style: const TextStyle(fontSize: 20)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Cor de destaque ───────────────────────────
            _SectionCard(
              children: [
                _label('Cor de destaque'),
                const SizedBox(height: 10),
                Row(
                  children: _cores.map((hex) {
                    final color    = _hexToColor(hex);
                    final selected = hex == _cor;
                    return GestureDetector(
                      onTap: () => setState(() => _cor = hex),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 10),
                        width:  selected ? 36 : 30,
                        height: selected ? 36 : 30,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: selected
                              ? Border.all(
                                  color: color.withAlpha(180), width: 3)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Período ───────────────────────────────────
            _SectionCard(
              children: [
                _label('Período do dia'),
                const SizedBox(height: 10),
                SegmentedButton<String>(
                  selected:  {_periodo},
                  onSelectionChanged: (s) =>
                      setState(() => _periodo = s.first),
                  segments: const [
                    ButtonSegment(
                        value: 'manha',
                        label: Text('Manhã'),
                        icon: Icon(Icons.wb_twilight_outlined, size: 16)),
                    ButtonSegment(
                        value: 'tarde',
                        label: Text('Tarde'),
                        icon: Icon(Icons.wb_sunny_outlined, size: 16)),
                    ButtonSegment(
                        value: 'noite',
                        label: Text('Noite'),
                        icon: Icon(Icons.nights_stay_outlined, size: 16)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Frequência ────────────────────────────────
            _SectionCard(
              children: [
                _label('Frequência'),
                const SizedBox(height: 10),
                SegmentedButton<String>(
                  selected:  {_frequencia},
                  onSelectionChanged: (s) =>
                      setState(() => _frequencia = s.first),
                  segments: const [
                    ButtonSegment(value: 'diario',  label: Text('Diário')),
                    ButtonSegment(value: 'seg-sex', label: Text('Seg–Sex')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Mini tarefas ──────────────────────────────
            _SectionCard(
              children: [
                Row(
                  children: [
                    _label('Mini tarefas'),
                    const Spacer(),
                    if (_subtaskCtrls.length < 8)
                      TextButton.icon(
                        onPressed: _addSubtask,
                        icon:  const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Adicionar'),
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                ...List.generate(_subtaskCtrls.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller:         _subtaskCtrls[i],
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: 'Ex: Tarefa ${i + 1}',
                              isDense: true,
                            ),
                          ),
                        ),
                        if (_subtaskCtrls.length > 1)
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: AppColors.error, size: 20),
                            onPressed: () => _removeSubtask(i),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 12),

            // ── Notificação ───────────────────────────────
            _SectionCard(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value:    _notifAtiva,
                  onChanged: (v) => setState(() => _notifAtiva = v),
                  title:    _label('Notificação'),
                  subtitle: Text(
                    'Aparecer na barra de notificações',
                    style: AppTextStyles.xpLabel,
                  ),
                  activeColor: AppColors.primary,
                ),
                if (_notifAtiva) ...[
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.access_time_rounded,
                        color: AppColors.primary),
                    title: const Text('Horário do lembrete'),
                    subtitle: Text(
                      _horarioNotif.format(context),
                      style: AppTextStyles.habitName
                          .copyWith(color: AppColors.primary),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _pickTime,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 32),

            // ── Botão salvar ──────────────────────────────
            SizedBox(
              width:  double.infinity,
              height: 52,
              child:  FilledButton(
                onPressed: _salvar,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  widget.isEditing ? 'Salvar alterações' : 'Criar hábito',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  Widget _label(String text) => Text(text, style: AppTextStyles.sectionLabel);
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      );
}
