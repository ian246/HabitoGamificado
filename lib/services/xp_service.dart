import 'package:flutter/foundation.dart';
import 'package:flutter_app_habitos/models/daily_activity.dart';

import '../models/habit.dart';
import '../models/user_profile.dart';
import '../models/achievement.dart';
import '../core/utils/date_utils.dart';
import 'storage_service.dart';
import 'auth_service.dart';
import 'notification_service.dart';

/// ─────────────────────────────────────────────────────────────
/// XpResult — resultado de uma ação que pode gerar XP
///
/// Usado para as telas saberem o que aconteceu e
/// dispararem as animações certas.
/// ─────────────────────────────────────────────────────────────
class XpResult {
  final int xpGanho;
  final bool subioDeNivel;
  final int? novoNivel;
  final String? nomeNivel;
  final List<int> novosMarcosDesbloqueados; // dias de streak
  final List<String> novasMolduras; // nomes das molduras

  const XpResult({
    this.xpGanho = 0,
    this.subioDeNivel = false,
    this.novoNivel,
    this.nomeNivel,
    this.novosMarcosDesbloqueados = const [],
    this.novasMolduras = const [],
  });

  bool get temEvento => xpGanho > 0 || subioDeNivel || novasMolduras.isNotEmpty;

  @override
  String toString() =>
      'XpResult(xp: $xpGanho, levelUp: $subioDeNivel, molduras: $novasMolduras)';
}

/// ─────────────────────────────────────────────────────────────
/// XpService — orquestrador principal de XP e gamificação
///
/// Padrão Singleton: XpService.instance
///
/// Responsabilidades:
///   1. Calcular XP ganho por ação
///   2. Atualizar UserProfile
///   3. Atualizar Achievements
///   4. Detectar level-up e novas molduras
///   5. Disparar notificações de recompensa
///   6. Persistir tudo via StorageService
/// ─────────────────────────────────────────────────────────────
class XpService {
  XpService._();
  static final XpService instance = XpService._();

  // ── Tabela de XP ─────────────────────────────────────────
  static const int _xpPorSubtarefa = 5;
  static const int _xpHabitoCompleto = 20;
  static const int _xpDiaPerfeito = 50;
  static const int _xpStreakSemanal = 30;
  static const int _xpNovaMoldura = 100;

  // ── Monotonicidade (Anti-Exploit) ─────────────────────────
  static const Duration _rewardGap = Duration(hours: 20);

  // ── Ação: marcar subtarefa ────────────────────────────────

  /// Chame quando o usuário marcar uma subtarefa.
  /// Retorna o Habit atualizado e o XpResult.
  Future<(Habit, XpResult)> onSubtaskChecked(
    Habit habit,
    String subtaskId,
    UserProfile profile,
  ) async {
    final eraCompleto = habit.completoHoje;
    final today = HabitDateUtils.todayKey();

    // 0. Validação de Monotonicidade (Time Travel / Clock Shift)
    final agora = DateTime.now();
    if (profile.lastGlobalRewardTimestamp != null) {
      final diff = agora.difference(profile.lastGlobalRewardTimestamp!);
      // Se tentou premiar uma data futura e agora voltou pro passado, ou se o gap é muito curto
      if (agora.isBefore(profile.lastGlobalRewardTimestamp!) ||
          (diff < _rewardGap && !profile.activityLog.containsKey(today))) {
        // Bloqueia ganho de XP se for tentativa de exploit de novo ciclo
        return (habit, const XpResult());
      }
    }

    // 1. Acesso ao log centralizado
    final activity = profile.activityLog[today] ?? DailyActivity(date: today);
    final subtaskIndex = habit.miniTarefas.indexWhere((s) => s.id == subtaskId);
    if (subtaskIndex == -1) return (habit, const XpResult());

    // ── 2. Alterna a subtarefa ──────────────────────────
    var habitAtualizado = habit.toggleSubtask(subtaskId);
    final subtask = habitAtualizado.miniTarefas[subtaskIndex];
    final subtaskFeita = subtask.feita;
    final jaGanhouXpSub = activity.isSubtaskRewarded(habit.id, subtaskIndex);

    // PERSISTÊNCIA: Sempre salvar o hábito localmente para manter o estado da UI (checks/progress)
    await StorageService.instance.saveHabitLocal(habitAtualizado);

    // Se desmarcou, apenas retorna (já salvamos acima)
    if (!subtaskFeita) {
      if (profile.isFirebaseUser) {
        await AuthService.instance.saveHabitRemote(habitAtualizado);
      }
      return (habitAtualizado, const XpResult());
    }

    // Se Marcou:
    // 3. Validação de "Cota Diária" (Itens novos não dão XP hoje)
    final newItem = habit.isNewToday || subtask.isNewToday;
    
    int xp = (jaGanhouXpSub || newItem) ? 0 : _xpPorSubtarefa;
    var perfilAtual = profile;

    if (!jaGanhouXpSub) {
      // Registrar no LOG CENTRALIZADO
      final novosSubKeys = Set<String>.from(activity.rewardedSubtaskKeys)
        ..add('${habit.id}:$subtaskIndex');

      perfilAtual = perfilAtual.copyWith(
        activityLog: {
          ...perfilAtual.activityLog,
          today: activity.copyWith(rewardedSubtaskKeys: novosSubKeys),
        },
        lastGlobalRewardTimestamp: agora,
      );

      // Trilha Guerreiro: só progride se não for item novo (Cota Diária)
      if (!newItem) {
        perfilAtual = perfilAtual.incrementarTrilha(
          'guerreiro',
          1,
          todayKey: today,
        );
      }
    }

    // 3. Bônus se completou o hábito agora
    if (habitAtualizado.completoHoje && !eraCompleto) {
      final activityUpdated = perfilAtual.activityLog[today]!;
      final jaGanhouXpComp = activityUpdated.isHabitRewarded(habit.id);

      if (!jaGanhouXpComp) {
        // Só ganha XP de conclusão se o hábito não for novo hoje
        if (!habit.isNewToday) {
          xp += _xpHabitoCompleto;
        }

        // Registrar conclusão no LOG CENTRALIZADO (sempre registra para evitar duplo prêmio amanhã)
        final novosHabComps = Set<String>.from(
          activityUpdated.rewardedHabitCompletions,
        )..add(habit.id);

        perfilAtual = perfilAtual.copyWith(
          activityLog: {
            ...perfilAtual.activityLog,
            today: activityUpdated.copyWith(
              rewardedHabitCompletions: novosHabComps,
            ),
          },
          lastGlobalRewardTimestamp: agora,
        );

        // Trilha Dedicado: só progride se não for item novo
        if (!habit.isNewToday) {
          perfilAtual = perfilAtual.incrementarTrilha(
            'dedicado',
            1,
            todayKey: today,
          );

          // Ao fechar todas as subtarefas de um hábito da manhã:
          if (habitAtualizado.periodo == 'manha') {
            perfilAtual = perfilAtual.incrementarTrilha(
              'madrugador',
              1,
              todayKey: today,
            );
          }
        }

        // Streak: atualizar 'constante'
        final streakAtual = habitAtualizado.streakAtual;
        final streakSalvo = perfilAtual.trailProgress['constante'] ?? 0;
        if (streakAtual > streakSalvo) {
          perfilAtual = perfilAtual.incrementarTrilha(
            'constante',
            streakAtual - streakSalvo,
          );
        }
      }
    }

    // Aplica XP e verifica level-up
    final nivelAntes = perfilAtual.nivel;
    final novoPerfil = await _aplicarXp(perfilAtual, xp);
    final subiu = novoPerfil.nivel > nivelAntes;

    // Verifica conquistas se hábito completou
    XpResult resultado;
    if (habitAtualizado.completoHoje && !eraCompleto) {
      final (perfilFinal, conquResult) = await _verificarConquistas(
        novoPerfil,
        habitAtualizado,
      );
      xp += conquResult.xpGanho;
      resultado = XpResult(
        xpGanho: xp,
        subioDeNivel: subiu || conquResult.subioDeNivel,
        novoNivel: subiu ? novoPerfil.nivel : conquResult.novoNivel,
        nomeNivel: subiu ? novoPerfil.nomeDonivel : conquResult.nomeNivel,
        novosMarcosDesbloqueados: conquResult.novosMarcosDesbloqueados,
        novasMolduras: conquResult.novasMolduras,
      );
      // Notificações de recompensa
      for (final m in conquResult.novasMolduras) {
        await NotificationService.instance.showFrameUnlocked(m);
      }
      if (subiu || conquResult.subioDeNivel) {
        final nivel = perfilFinal.nivel;
        await NotificationService.instance.showLevelUp(
          nivel,
          perfilFinal.nomeDonivel,
        );
      }
    } else {
      await AuthService.instance.saveProfile(novoPerfil);
      resultado = XpResult(
        xpGanho: xp,
        subioDeNivel: subiu,
        novoNivel: subiu ? novoPerfil.nivel : null,
        nomeNivel: subiu ? novoPerfil.nomeDonivel : null,
      );
    }

    // Sincronização Remota (v2.1)
    if (novoPerfil.isFirebaseUser) {
      await AuthService.instance.saveHabitRemote(habitAtualizado);
    }

    return (habitAtualizado, resultado);
  }

  // ── Verificar conquistas após hábito completo ─────────────

  /// Verifica conquistas de período + geral + perfeito
  Future<(UserProfile, XpResult)> _verificarConquistas(
    UserProfile profile,
    Habit habit,
  ) async {
    final hoje = HabitDateUtils.todayKey();
    int xp = 0;
    final novosMarcos = <int>[];
    final novasMolduras = <String>[];
    var perfil = profile;
    bool subiu = false;

    // ── Conquista do período do hábito ──────────────────────
    final catPeriodo = _categoriaParaPeriodo(habit.periodo);
    if (catPeriodo != null) {
      final conquista =
          perfil.conquistas[catPeriodo] ?? Achievement(categoria: catPeriodo);

      // Verifica se TODOS os hábitos desse período foram concluídos hoje
      // (aqui usamos apenas o hábito atual como trigger — a verificação
      //  completa de "todos do período" é feita na HomeScreen)
      final (novaConquista, marcos) = conquista.registrarDia(hoje);
      perfil = perfil.atualizarConquista(catPeriodo, novaConquista);

      if (marcos.isNotEmpty) {
        novosMarcos.addAll(marcos);
        novasMolduras.add(novaConquista.nomeMoldura);
        xp += _xpNovaMoldura * marcos.length;
      }
    }

    // ── Conquista geral ─────────────────────────────────────
    final conquGeral =
        perfil.conquistas[AchievementCategory.geral] ??
        Achievement(categoria: AchievementCategory.geral);
    final (novaGeral, marcosGeral) = conquGeral.registrarDia(hoje);
    perfil = perfil.atualizarConquista(AchievementCategory.geral, novaGeral);

    if (marcosGeral.isNotEmpty) {
      novosMarcos.addAll(marcosGeral);
      novasMolduras.add('Geral — ${novaGeral.nomeMoldura}');
      xp += _xpNovaMoldura * marcosGeral.length;
    }

    // ── Bônus de streak semanal (a cada 7 dias) ─────────────
    if (novaGeral.streakAtual > 0 && novaGeral.streakAtual % 7 == 0) {
      xp += _xpStreakSemanal;
    }

    // Aplica XP das conquistas
    if (xp > 0) {
      final nivelAntes = perfil.nivel;
      perfil = await _aplicarXp(perfil, xp);
      subiu = perfil.nivel > nivelAntes;
    } else {
      await AuthService.instance.saveProfile(perfil);
    }

    return (
      perfil,
      XpResult(
        xpGanho: xp,
        subioDeNivel: subiu,
        novoNivel: subiu ? perfil.nivel : null,
        nomeNivel: subiu ? perfil.nomeDonivel : null,
        novosMarcosDesbloqueados: novosMarcos,
        novasMolduras: novasMolduras,
      ),
    );
  }

  // ── Ação: dia perfeito ────────────────────────────────────

  /// Chame quando detectar que TODOS os hábitos do dia foram concluídos.
  /// [alreadyGranted] evita duplo bônus — persista isso no perfil.
  Future<XpResult> onPerfectDay(UserProfile profile) async {
    final hoje = HabitDateUtils.todayKey();
    if (profile.diasPerfeitos.contains(hoje)) return const XpResult();

    int xp = _xpDiaPerfeito;

    // Conquista "Perfeccionista"
    final conquPerf =
        profile.conquistas[AchievementCategory.perfeito] ??
        Achievement(categoria: AchievementCategory.perfeito);
    final (novaConq, marcos) = conquPerf.registrarDia(hoje);

    var perfil = profile
        .atualizarConquista(AchievementCategory.perfeito, novaConq)
        .registrarDiaPerfeito(hoje);

    // Ao registrar dia perfeito:
    perfil = perfil.incrementarTrilha('perfeccionista', 1, todayKey: hoje);

    final novasMolduras = <String>[];
    if (marcos.isNotEmpty) {
      xp += _xpNovaMoldura * marcos.length;
      novasMolduras.add('Perfeccionista — ${novaConq.nomeMoldura}');
    }

    final nivelAntes = perfil.nivel;
    perfil = await _aplicarXp(perfil, xp);
    final subiu = perfil.nivel > nivelAntes;

    for (final m in novasMolduras) {
      await NotificationService.instance.showFrameUnlocked(m);
    }
    if (subiu) {
      await NotificationService.instance.showLevelUp(
        perfil.nivel,
        perfil.nomeDonivel,
      );
    }

    return XpResult(
      xpGanho: xp,
      subioDeNivel: subiu,
      novoNivel: subiu ? perfil.nivel : null,
      nomeNivel: subiu ? perfil.nomeDonivel : null,
      novosMarcosDesbloqueados: marcos,
      novasMolduras: novasMolduras,
    );
  }

  // ── Ação: criar hábito ────────────────────────────────────

  /// Chame quando o usuário criar um novo hábito
  Future<XpResult> onHabitCreated(UserProfile profile) async {
    final today = HabitDateUtils.todayKey();

    // Registra criação (Source of Truth)
    var perfil = profile.registrarCriacaoHabito(today);

    // Trilha Colecionador: Refinada para retenção (>= 7 dias)
    perfil = await _atualizarTrilhaColecionador(perfil);

    await AuthService.instance.saveProfile(perfil);
    return const XpResult();
  }

  /// Calcula quantos hábitos existem há mais de 7 dias e atualiza a trilha Colecionador.
  Future<UserProfile> _atualizarTrilhaColecionador(UserProfile profile) async {
    try {
      final habitos = await StorageService.instance.loadAllHabits();
      final hoje = DateTime.now();

      // Conta hábitos que "sobreviveram" pelo menos 7 dias (retenção real)
      final sobreviventes = habitos.where((h) {
        return hoje.difference(h.criadoEm).inDays >= 7;
      }).length;

      final progressAtual = profile.trailProgress['colecionador'] ?? 0;

      // A trilha só progride (impede que deletar hábitos baixe o nível da conquista já ganha)
      if (sobreviventes > progressAtual) {
        return profile.incrementarTrilha(
          'colecionador',
          sobreviventes - progressAtual,
        );
      }
    } catch (e) {
      debugPrint('Erro ao atualizar trilha colecionador: $e');
    }
    return profile;
  }

  // ── Helpers privados ──────────────────────────────────────

  /// Aplica XP ao perfil, salva e retorna o novo perfil
  Future<UserProfile> _aplicarXp(UserProfile profile, int xp) async {
    final atualizado = profile.adicionarXp(xp);
    await AuthService.instance.saveProfile(atualizado);
    return atualizado;
  }

  AchievementCategory? _categoriaParaPeriodo(String periodo) {
    switch (periodo) {
      case 'manha':
        return AchievementCategory.manha;
      case 'tarde':
        return AchievementCategory.tarde;
      case 'noite':
        return AchievementCategory.noite;
      default:
        return null;
    }
  }

  // ── Consultas ─────────────────────────────────────────────

  /// Retorna o perfil atual do SharedPreferences
  UserProfile? get currentProfile => StorageService.instance.loadProfile();

  /// Retorna o XP total atual
  int get currentXp => currentProfile?.xpTotal ?? 0;

  /// Retorna o nível atual
  int get currentLevel => currentProfile?.nivel ?? 1;
}
