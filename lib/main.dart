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

  // Services locais
  await StorageService.instance.init();
  await NotificationService.instance.init();

  if (StorageService.instance.needsDailyReset()) {
    await StorageService.instance.performDailyReset();
  }

  runApp(HabitFlowApp(key: HabitFlowApp.appKey));
}

class HabitFlowApp extends StatefulWidget {
  const HabitFlowApp({super.key});

  /// Permite resetar o estado global de qualquer lugar (ex: LoginScreen)
  static final GlobalKey<HabitFlowAppState> appKey = GlobalKey<HabitFlowAppState>();

  static HabitFlowAppState of(BuildContext context) =>
      context.findAncestorStateOfType<HabitFlowAppState>()!;

  @override
  State<HabitFlowApp> createState() => HabitFlowAppState();
}

class HabitFlowAppState extends State<HabitFlowApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  /// Quando true, o StreamBuilder exibe o SplashScreen e NÃO navega
  /// automaticamente — isso dá espaço para o LoginScreen concluir a
  /// navegação via Navigator depois do Google sign-in.
  bool _signingIn = false;

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

  /// Chamado pela ProfileScreen ao alternar o tema.
  void setTheme(bool isDark) {
    setState(() => _themeMode = isDark ? ThemeMode.dark : ThemeMode.light);
  }

  /// Chamado pelo LoginScreen para pausar/retomar o roteamento do StreamBuilder.
  void setSigningIn(bool value) {
    if (mounted) setState(() => _signingIn = value);
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
      home: StreamBuilder<User?>(
        stream: AuthService.instance.authStateChanges,
        builder: (context, snapshot) {
          // 1. Firebase verificando token (~1 s na abertura)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _SplashScreen();
          }

          // 2. Sign-in em progresso: aguarda o LoginScreen concluir a
          //    navegação via Navigator — evita conflito de rotas.
          if (_signingIn) {
            return const _SplashScreen();
          }

          bool isComplete = false;
          if (StorageService.instance.hasProfile) {
            isComplete = StorageService.instance.loadProfile()?.setupComplete ?? false;
          }

          // 3. Autenticado no Firebase + Perfil Configurado → Home
          if (snapshot.data != null && isComplete) {
            return const HomeScreen();
          }

          // 4. Não autenticado no Firebase, mas tem perfil local configurado (offline) → Home
          if (snapshot.data == null && isComplete) {
            return const HomeScreen();
          }

          // 5. Autenticado no Firebase, mas perfil INCOMPLETO → Cadastro
          if (snapshot.data != null && !isComplete) {
            return SignupScreen(
              googleProfile: StorageService.instance.loadProfile(),
            );
          }

          // 6. Novo usuário sem nenhum perfil → tela de boas-vindas
          return const LoginScreen();
        },
      ),
      routes: {
        '/home': (_) => const HomeScreen(),
        '/login': (_) => const LoginScreen(),
      },
    );
  }
}

/// Splash enquanto o Firebase verifica o token ou o sign-in está em progresso.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'HabitFlow',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 28),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
