import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/habit.dart';

/// ─────────────────────────────────────────────────────────────
/// NotificationService — notificações locais Android
///
/// Padrão Singleton: NotificationService.instance
///
/// Inicializar no main.dart ANTES do runApp:
///   await NotificationService.instance.init();
///
// IMPORTANTE — AndroidManifest.xml:
//   Adicionar dentro de <manifest>:
//     <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
//     <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
//     <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/
//
//   Adicionar dentro de <application>:
//     <receiver android:exported="false"
//       android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver">
//       <intent-filter>
//         <action android:name="android.intent.action.BOOT_COMPLETED"/>
//         <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
//         <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
//       </intent-filter>
//     </receiver>
/// ─────────────────────────────────────────────────────────────
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ── Canal Android ─────────────────────────────────────────
  static const _channelId   = 'habitflow_habitos';
  static const _channelName = 'Hábitos';
  static const _channelDesc = 'Lembretes dos seus hábitos diários';

  // ── Inicialização ─────────────────────────────────────────
  Future<void> init() async {
    if (_initialized) return;

    // Inicializa timezones
    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/icon_habit_flow');
    const ios     = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Cria o canal Android (necessário para Android 8+)
    await _createChannel();

    _initialized = true;
  }

  Future<void> _createChannel() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description:    _channelDesc,
      importance:     Importance.high,
      playSound:      true,
      enableVibration: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _onNotificationTap(NotificationResponse response) {
    // Navegação ao tocar na notificação
    // Implemente aqui quando tiver o NavigatorKey configurado
    // Ex: navigatorKey.currentState?.pushNamed('/home')
  }

  // ── Permissões ────────────────────────────────────────────
  /// Solicita permissão de notificação (Android 13+)
  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? false;
  }

  /// Verifica se a permissão foi concedida
  Future<bool> hasPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.areNotificationsEnabled();
    return granted ?? false;
  }

  // ── Agendar por hábito ────────────────────────────────────

  /// Agenda a notificação diária de um hábito.
  /// Cancela a anterior automaticamente antes de reagendar.
  Future<void> scheduleHabit(Habit habit) async {
    if (!_initialized) await init();
    if (!habit.notificacaoAtiva) {
      await cancelHabit(habit.id);
      return;
    }

    // Cancela versão anterior
    await cancelHabit(habit.id);

    // Converte 'HH:mm' para hora e minuto
    final parts  = habit.notificacaoHora.split(':');
    final hour   = int.tryParse(parts[0]) ?? 8;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

    // Monta o TZDateTime para o próximo disparo
    final scheduledDate = _nextInstanceOf(hour, minute);

    // ID numérico único derivado do ID do hábito (SharedPreferences usa String)
    final notifId = _idFromHabitId(habit.id);

    await _plugin.zonedSchedule(
      id: notifId,
      title: '⏰ ${habit.icone} ${habit.nome}',
      body: _buildBody(habit),
      scheduledDate: scheduledDate,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription:     _channelDesc,
          importance:             Importance.high,
          priority:               Priority.high,
          icon:                   '@mipmap/icon_habit_flow',
          ticker:                 habit.nome,
          styleInformation: const BigTextStyleInformation(''),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // repete todo dia
    );
  }

  /// Cancela a notificação de um hábito pelo ID string
  Future<void> cancelHabit(String habitId) async {
    await _plugin.cancel(id: _idFromHabitId(habitId));
  }

  /// Reagenda todas as notificações ativas.
  /// Chamar ao iniciar o app (boot recovery).
  Future<void> rescheduleAll(List<Habit> habits) async {
    if (!_initialized) await init();
    for (final h in habits) {
      await scheduleHabit(h);
    }
  }

  /// Cancela absolutamente todas as notificações
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ── Notificação imediata (teste / desbloqueio de moldura) ─
  Future<void> showInstant({
    required String titulo,
    required String corpo,
    int id = 9999,
  }) async {
    if (!_initialized) await init();
    await _plugin.show(
      id: id,
      title: titulo,
      body: corpo,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority:   Priority.high,
          icon:       '@mipmap/icon_habit_flow',
        ),
      ),
    );
  }

  /// Notificação de nova moldura desbloqueada
  Future<void> showFrameUnlocked(String nomeMoldura) => showInstant(
    id:     9998,
    titulo: '🏆 Nova moldura desbloqueada!',
    corpo:  'Parabéns! Você conquistou a moldura $nomeMoldura.',
  );

  /// Notificação de subida de nível
  Future<void> showLevelUp(int nivel, String nomeNivel) => showInstant(
    id:     9997,
    titulo: '⭐ Nível $nivel — $nomeNivel!',
    corpo:  'Você subiu de nível. Continue assim!',
  );

  // ── Helpers privados ──────────────────────────────────────

  /// Converte String UUID em int para o ID da notificação
  int _idFromHabitId(String habitId) =>
      habitId.hashCode.abs() % 100000;

  /// Próxima ocorrência de hora:minuto a partir de agora
  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now      = tz.TZDateTime.now(tz.local);
    var   scheduled = tz.TZDateTime(
      tz.local,
      now.year, now.month, now.day,
      hour, minute,
    );
    // Se o horário já passou hoje, agenda para amanhã
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  String _buildBody(Habit habit) {
    final total     = habit.miniTarefas.length;
    final feitas    = habit.subtarefasFeitas;
    final pendentes = total - feitas;

    if (feitas == 0) {
      return 'Você tem $total ${total == 1 ? 'tarefa' : 'tarefas'} para fazer hoje.';
    }
    if (pendentes == 0) {
      return 'Hábito completo! Ótimo trabalho hoje 💚';
    }
    return '$feitas de $total tarefas feitas. Faltam $pendentes!';
  }
}
