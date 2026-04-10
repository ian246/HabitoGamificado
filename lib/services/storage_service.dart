import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';
import '../models/user_profile.dart';

/// ─────────────────────────────────────────────────────────────
/// StorageService — CRUD completo via SharedPreferences
///
/// Padrão Singleton: StorageService.instance
///
/// Inicializar no main.dart ANTES do runApp:
///   await StorageService.instance.init();
///
/// Chaves usadas no SharedPreferences:
///   'user_profile'     → JSON do UserProfile
///   'habit_ids'        → JSON de List<String> com IDs
///   'habit_{id}'       → JSON de cada Habit
///   'last_reset_date'  → 'yyyy-MM-dd' do último reset diário
///   'perfect_day_{data}' → bool — dia perfeito registrado
/// ─────────────────────────────────────────────────────────────
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  late SharedPreferences _prefs;
  bool _initialized = false;

  // ── Chaves ────────────────────────────────────────────────
  static const _keyProfile      = 'user_profile';
  static const _keyHabitIds     = 'habit_ids';
  static const _keyLastReset    = 'last_reset_date';
  static const _prefixHabit     = 'habit_';

  // ── Inicialização ─────────────────────────────────────────
  Future<void> init() async {
    if (_initialized) return;
    _prefs       = await SharedPreferences.getInstance();
    _initialized = true;
  }

  void _assertInit() {
    assert(_initialized, 'StorageService não foi inicializado. Chame await StorageService.instance.init() no main.dart');
  }

  // ══════════════════════════════════════════════════════════
  // PERFIL DO USUÁRIO
  // ══════════════════════════════════════════════════════════

  /// Retorna true se há um perfil salvo (usuário já fez signup)
  bool get hasProfile {
    _assertInit();
    return _prefs.containsKey(_keyProfile);
  }

  /// Carrega o perfil. Retorna null se não existir.
  UserProfile? loadProfile() {
    _assertInit();
    final raw = _prefs.getString(_keyProfile);
    if (raw == null) return null;
    try {
      return UserProfile.fromJsonString(raw);
    } catch (e) {
      // Dado corrompido — remove e retorna null
      _prefs.remove(_keyProfile);
      return null;
    }
  }

  /// Salva ou atualiza o perfil
  Future<bool> saveProfile(UserProfile profile) {
    _assertInit();
    return _prefs.setString(_keyProfile, profile.toJsonString());
  }

  /// Deleta o perfil (logout / reset)
  Future<bool> deleteProfile() {
    _assertInit();
    return _prefs.remove(_keyProfile);
  }

  // ══════════════════════════════════════════════════════════
  // HÁBITOS
  // ══════════════════════════════════════════════════════════

  /// Retorna todos os IDs salvos
  List<String> _loadIds() {
    final raw = _prefs.getString(_keyHabitIds);
    if (raw == null) return [];
    return List<String>.from(jsonDecode(raw) as List);
  }

  Future<void> _saveIds(List<String> ids) async {
    await _prefs.setString(_keyHabitIds, jsonEncode(ids));
  }

  /// Carrega todos os hábitos na ordem em que foram criados
  Future<List<Habit>> loadAllHabits() async {
    _assertInit();
    final ids = _loadIds();
    final habits = <Habit>[];

    for (final id in ids) {
      final raw = _prefs.getString('$_prefixHabit$id');
      if (raw == null) continue;
      try {
        habits.add(Habit.fromJsonString(raw));
      } catch (_) {
        // Ignora entradas corrompidas
      }
    }
    return habits;
  }

  /// Carrega um hábito pelo ID. Retorna null se não existir.
  Habit? loadHabit(String id) {
    _assertInit();
    final raw = _prefs.getString('$_prefixHabit$id');
    if (raw == null) return null;
    try {
      return Habit.fromJsonString(raw);
    } catch (_) {
      return null;
    }
  }

  /// Salva um hábito (cria ou atualiza)
  Future<void> saveHabit(Habit habit) async {
    _assertInit();
    // Salva o dado do hábito
    await _prefs.setString('$_prefixHabit${habit.id}', habit.toJsonString());
    // Garante que o ID está na lista
    final ids = _loadIds();
    if (!ids.contains(habit.id)) {
      ids.add(habit.id);
      await _saveIds(ids);
    }
  }

  /// Salva uma lista inteira de hábitos de uma vez
  Future<void> saveAllHabits(List<Habit> habits) async {
    _assertInit();
    for (final h in habits) {
      await _prefs.setString('$_prefixHabit${h.id}', h.toJsonString());
    }
    await _saveIds(habits.map((h) => h.id).toList());
  }

  /// Deleta um hábito pelo ID
  Future<void> deleteHabit(String id) async {
    _assertInit();
    await _prefs.remove('$_prefixHabit$id');
    final ids = _loadIds()..remove(id);
    await _saveIds(ids);
  }

  /// Reordena os hábitos (drag & drop na lista)
  Future<void> reorderHabits(List<String> newOrder) async {
    _assertInit();
    await _saveIds(newOrder);
  }

  // ══════════════════════════════════════════════════════════
  // RESET DIÁRIO
  // ══════════════════════════════════════════════════════════

  /// Chave do dia atual ('yyyy-MM-dd')
  String get _todayKey {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4,'0')}-'
        '${now.month.toString().padLeft(2,'0')}-'
        '${now.day.toString().padLeft(2,'0')}';
  }

  /// Verifica se o reset diário já foi feito hoje.
  /// Chame no início do app. Se retornar true, faça o reset.
  bool needsDailyReset() {
    _assertInit();
    final lastReset = _prefs.getString(_keyLastReset);
    return lastReset != _todayKey;
  }

  /// Reseta as subtarefas de todos os hábitos e salva o
  /// progresso do dia anterior no histórico de cada um.
  Future<void> performDailyReset() async {
    _assertInit();
    final ontem  = _todayKey; // ainda é o dia anterior se chamado cedo
    final habits = await loadAllHabits();

    final resetados = habits.map((h) {
      // Salva progresso de hoje antes de resetar
      final comHistorico = h.salvarProgressoHoje(ontem);
      // Reseta subtarefas para o novo dia
      return comHistorico.resetarParaHoje();
    }).toList();

    await saveAllHabits(resetados);
    await _prefs.setString(_keyLastReset, _todayKey);
  }

  // ══════════════════════════════════════════════════════════
  // DIAGNÓSTICO / UTILITÁRIOS
  // ══════════════════════════════════════════════════════════

  /// Retorna quantos hábitos estão salvos
  int get habitCount => _loadIds().length;

  /// Limpa TUDO (apenas para debug/testes)
  Future<void> clearAll() async {
    _assertInit();
    await _prefs.clear();
  }

  /// Exporta todos os dados como JSON string (backup manual)
  Future<String> exportAll() async {
    _assertInit();
    final habits  = await loadAllHabits();
    final profile = loadProfile();

    return jsonEncode({
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'profile': profile?.toJson(),
      'habits':  habits.map((h) => h.toJson()).toList(),
    });
  }

  /// Importa dados de um JSON de backup
  Future<void> importAll(String jsonString) async {
    _assertInit();
    final data    = jsonDecode(jsonString) as Map<String, dynamic>;
    final profile = data['profile'];
    final habits  = data['habits'] as List? ?? [];

    if (profile != null) {
      await saveProfile(UserProfile.fromJson(profile as Map<String, dynamic>));
    }

    for (final h in habits) {
      await saveHabit(Habit.fromJson(h as Map<String, dynamic>));
    }
  }
}
