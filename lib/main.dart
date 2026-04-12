import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  // Firebase — inicializa antes de qualquer outro service
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Cache offline: app salva e lê dados sem internet, sincroniza ao voltar
  FirebaseDatabase.instance.setPersistenceEnabled(true);

  // Services locais (mantém lógica original da v1)
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
  ThemeMode _themeMode = ThemeMode.dark;

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

  // Chamado pela ProfileScreen ao toggar o switch — atualiza em tempo real
  void setTheme(bool isDark) {
    setState(() => _themeMode = isDark ? ThemeMode.dark : ThemeMode.light);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'HabitFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      // StreamBuilder é o árbitro de navegação.
      // Firebase emite:
      //   null  → não logado → LoginScreen (ou SignupScreen se também não tiver perfil local)
      //   User  → logado    → HomeScreen
      home: StreamBuilder<User?>(
        stream: AuthService.instance.authStateChanges,
        builder: (context, snapshot) {
          // Firebase verificando token (~1s na abertura)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _SplashScreen();
          }

          if (snapshot.data != null) {
            // Usuário autenticado — vai para Home
            return const HomeScreen();
          }

          // Não logado — decide entre Login (tem perfil local) e Signup (novo)
          if (!StorageService.instance.hasProfile) {
            return const SignupScreen();
          }
          return const LoginScreen();
        },
      ),
      routes: {
        '/home': (_) => const HomeScreen(),
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
      },
    );
  }
}

/// Splash enquanto o Firebase verifica o token de autenticação.
/// Aparece por ~1s — evita mostrar tela branca na abertura.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
