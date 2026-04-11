import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/habit.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';
import '../services/xp_service.dart';
import '../services/notification_service.dart';
import '../widgets/habit_card.dart';
import '../widgets/xp_header.dart';
import 'habit_form_screen.dart';
import 'habit_detail_screen.dart';
import 'achievements_screen.dart';
import 'progress_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<Habit> _habits = [];
  UserProfile? _profile;
  bool _loading = true;

  String _greetingText() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bom dia';
    if (h < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final habits = await StorageService.instance.loadAllHabits();
    final profile = StorageService.instance.loadProfile();
    if (!mounted) return;
    setState(() {
      _habits = habits;
      _profile = profile;
      _loading = false;
    });
    // Re-agenda notificações ao abrir o app
    await NotificationService.instance.rescheduleAll(_habits);
  }

  // ── Ações ─────────────────────────────────────────────────
  Future<void> _onSubtaskToggle(Habit habit, String subtaskId) async {
    if (_profile == null) return;

    final (habitAtualizado, result) = await XpService.instance.onSubtaskChecked(
      habit,
      subtaskId,
      _profile!,
    );

    // Reload state
    await _load();

    if (!mounted) return;

    // Verificar dia perfeito
    if (habitAtualizado.completoHoje) {
      await _checkPerfectDay();
    }

    // Mostrar eventos de XP
    if (result.temEvento) {
      _showXpEvent(result);
    }
  }

  Future<void> _checkPerfectDay() async {
    if (_profile == null) return;
    final todayDone = _habits.every((h) => !h.ativoHoje || h.completoHoje);
    if (!todayDone) return;

    final result = await XpService.instance.onPerfectDay(_profile!);
    await _load();
    if (!mounted || !result.temEvento) return;
    _showXpEvent(result);
  }

  Future<void> _onDeleteHabit(String id) async {
    await StorageService.instance.deleteHabit(id);
    await NotificationService.instance.cancelHabit(id);
    await _load();
  }

  Future<void> _onAddHabit() async {
    final novo = await Navigator.of(
      context,
    ).push<Habit>(MaterialPageRoute(builder: (_) => const HabitFormScreen()));
    if (novo != null) {
      await StorageService.instance.saveHabit(novo);
      try {
        await NotificationService.instance.scheduleHabit(novo);
      } catch (e) {
        debugPrint('Erro ao agendar notificação (permissão): $e');
      }
      if (_profile != null) {
        final result = await XpService.instance.onHabitCreated(_profile!);
        if (result.temEvento && mounted) _showXpEvent(result);
      }
      await _load();
    }
  }

  Future<void> _onEditHabit(Habit habit) async {
    final editado = await Navigator.of(context).push<Habit>(
      MaterialPageRoute(
        builder: (_) => HabitFormScreen(habitParaEditar: habit),
      ),
    );
    if (editado != null) {
      await StorageService.instance.saveHabit(editado);
      try {
        await NotificationService.instance.scheduleHabit(editado);
      } catch (e) {
        debugPrint('Erro ao reagendar notificação (permissão): $e');
      }
      await _load();
    }
  }

  Future<void> _onHabitTap(Habit habit) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => HabitDetailScreen(habit: habit)));
    await _load(); // recarrega caso tenha editado no detalhe
  }

  void _showXpEvent(XpResult result) {
    final parts = <String>[];
    if (result.xpGanho > 0) parts.add('+${result.xpGanho} XP');
    if (result.subioDeNivel) {
      parts.add('Nível ${result.novoNivel}! ${result.nomeNivel}');
    }
    for (final m in result.novasMolduras) {
      parts.add('🏆 $m desbloqueada!');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(parts.join(' · ')),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _currentIndex,
              children: [
                _HabitListTab(
                  habits: _habits,
                  onSubtaskToggle: _onSubtaskToggle,
                  onEdit: _onEditHabit,
                  onDelete: _onDeleteHabit,
                  onTap: _onHabitTap,
                  profile: _profile,
                ),
                ProgressScreen(habits: _habits),
                AchievementsScreen(profile: _profile),
                ProfileScreen(profile: _profile, onProfileUpdate: _load),
              ],
            ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _onAddHabit,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Novo hábito'),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedFontSize: 13,
        unselectedFontSize: 11,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart_rounded),
            label: 'Progresso',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_outlined),
            activeIcon: Icon(Icons.emoji_events_rounded),
            label: 'Conquistas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final titles = ['HabitFlow', 'Progresso', 'Conquistas', 'Perfil'];

    return AppBar(
      title: _currentIndex == 0 && _profile != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_greetingText()}, ${_profile!.apelido}',
                  style: AppTextStyles.username,
                ),
                const SizedBox(height: 8),
                XpHeader(profile: _profile!, onRefresh: _load),
              ],
            )
          : Text(titles[_currentIndex]),
      toolbarHeight: _currentIndex == 0 && _profile != null
          ? 180 // Maior espaço para nova UI do XpHeader
          : kToolbarHeight,
    );
  }
}

// ── Aba de lista de hábitos ─────────────────────────────────
class _HabitListTab extends StatelessWidget {
  final List<Habit> habits;
  final Function(Habit, String) onSubtaskToggle;
  final Function(Habit) onEdit;
  final Function(String) onDelete;
  final Function(Habit) onTap;
  final UserProfile? profile;

  const _HabitListTab({
    required this.habits,
    required this.onSubtaskToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
    this.profile,
  });

  String get _currentPeriod {
    final h = DateTime.now().hour;
    if (h < 12) return 'manha';
    if (h < 18) return 'tarde';
    return 'noite';
  }

  List<Habit> get _habitsDoPeriodo =>
      habits.where((h) => h.ativoHoje && h.periodo == _currentPeriod).toList();

  List<Habit> get _outrosHabitos =>
      habits.where((h) => h.ativoHoje && h.periodo != _currentPeriod).toList();

  @override
  Widget build(BuildContext context) {
    if (habits.isEmpty) {
      return _EmptyState();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        // Hábitos do período atual
        if (_habitsDoPeriodo.isNotEmpty) ...[
          _SectionHeader(label: _periodLabel(_currentPeriod), isActive: true),
          ..._habitsDoPeriodo.map(
            (h) => HabitCard(
              habit: h,
              onSubtaskToggle: (id) => onSubtaskToggle(h, id),
              onEdit: () => onEdit(h),
              onDelete: () => onDelete(h.id),
              onTap: () => onTap(h),
            ),
          ),
        ],

        // Outros hábitos do dia
        if (_outrosHabitos.isNotEmpty) ...[
          const SizedBox(height: 8),
          _SectionHeader(label: 'Outros hábitos de hoje'),
          ..._outrosHabitos.map(
            (h) => HabitCard(
              habit: h,
              onSubtaskToggle: (id) => onSubtaskToggle(h, id),
              onEdit: () => onEdit(h),
              onDelete: () => onDelete(h.id),
              onTap: () => onTap(h),
            ),
          ),
        ],
      ],
    );
  }

  String _periodLabel(String p) {
    switch (p) {
      case 'tarde':
        return '☀️  Tarde';
      case 'noite':
        return '🌙  Noite';
      default:
        return '🌅  Manhã';
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool isActive;
  const _SectionHeader({required this.label, this.isActive = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4),
    child: Text(
      label,
      style: AppTextStyles.sectionLabel.copyWith(
        color: isActive ? AppColors.primary : AppColors.textSecondary,
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🌱', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 16),
        Text(
          'Nenhum hábito ainda',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'Toque em "Novo hábito" para começar.',
          style: AppTextStyles.greeting,
        ),
      ],
    ),
  );
}
