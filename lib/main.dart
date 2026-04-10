import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  await StorageService.instance.init();
  await NotificationService.instance.init();

  if (StorageService.instance.needsDailyReset()) {
    await StorageService.instance.performDailyReset();
  }

  runApp(const HabitFlowApp());
}

class HabitFlowApp extends StatefulWidget {
  const HabitFlowApp({super.key});

  static HabitFlowAppState of(BuildContext context) =>
      context.findAncestorStateOfType<HabitFlowAppState>()!;

  @override
  State<HabitFlowApp> createState() => HabitFlowAppState();
}

class HabitFlowAppState extends State<HabitFlowApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  void _loadTheme() {
    final profile = StorageService.instance.loadProfile();
    if (profile != null) {
      setState(() {
        _themeMode = profile.darkMode ? ThemeMode.dark : ThemeMode.light;
      });
    }
  }

  void setTheme(bool isDark) {
    setState(() => _themeMode = isDark ? ThemeMode.dark : ThemeMode.light);
  }

  @override
  Widget build(BuildContext context) {
    Widget home;
    if (!StorageService.instance.hasProfile) {
      home = const SignupScreen();
    } else {
      home = const LoginScreen();
    }

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'HabitFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      home: home,
      routes: {
        '/home': (_) => const HomeScreen(),
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
      },
    );
  }
}
