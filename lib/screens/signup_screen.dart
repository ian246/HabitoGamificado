import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'home_screen.dart';

/// ─────────────────────────────────────────────────────────────
/// SignupScreen v3 — criação / personalização de perfil
///
/// Dois modos:
///   googleProfile != null → usuário autenticado no Google
///     • Badge com foto + e-mail no canto superior direito
///     • Campos pré-preenchidos com dados do Google
///     • Sem PIN (Google é a camada de segurança)
///
///   googleProfile == null → modo offline
///     • Formulário completo com PIN de 4 dígitos
/// ─────────────────────────────────────────────────────────────
class SignupScreen extends StatefulWidget {
  /// Perfil criado pelo AuthService após autenticação Google.
  /// null = fluxo offline.
  final UserProfile? googleProfile;

  const SignupScreen({super.key, this.googleProfile});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _apelidoCtrl;
  final _pinCtrl = TextEditingController();
  final _pinConfCtrl = TextEditingController();
  bool _obscurePin = true;
  bool _isLoading = false;

  bool get _isGoogleUser => widget.googleProfile != null;

  @override
  void initState() {
    super.initState();
    // Pré-preenche com dados do Google quando disponível
    final nome = widget.googleProfile?.nome ?? '';
    _nomeCtrl = TextEditingController(text: nome);
    _apelidoCtrl = TextEditingController(
      text: _primeiroNome(nome),
    );
  }

  String _primeiroNome(String nome) {
    if (nome.trim().isEmpty) return '';
    return nome.trim().split(' ').first;
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _apelidoCtrl.dispose();
    _pinCtrl.dispose();
    _pinConfCtrl.dispose();
    super.dispose();
  }

  Future<void> _criarPerfil() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    UserProfile profile;

    if (_isGoogleUser) {
      // Atualiza o perfil Google com o apelido escolhido pelo usuário.
      // NOTA: UserProfile.copyWith deve aceitar 'nome' e 'apelido'.
      // Caso não compile, adicione esses parâmetros ao método copyWith do modelo.
      profile = widget.googleProfile!.copyWith(
        nome: _nomeCtrl.text.trim(),
        apelido: _apelidoCtrl.text.trim(),
        setupComplete: true,
      );
    } else {
      // Cria perfil local com PIN
      profile = UserProfile.create(
        nome: _nomeCtrl.text.trim(),
        apelido: _apelidoCtrl.text.trim(),
        pinHash: _pinCtrl.text,
      ).copyWith(setupComplete: true);
      // Solicita permissão de notificação no fluxo offline
      await NotificationService.instance.requestPermission();
    }

    await AuthService.instance.saveProfile(profile);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // ── Formulário ────────────────────────────────────
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                28,
                _isGoogleUser ? 64 : 24, // espaço para o badge
                28,
                24,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),

                    // ── Cabeçalho ─────────────────────────────
                    Text(
                      _isGoogleUser ? '🎉' : '🌱',
                      style: const TextStyle(fontSize: 48),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Crie seu perfil',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isGoogleUser
                          ? 'Personalize como você quer ser chamado no app.'
                          : 'Seus dados ficam apenas neste dispositivo.',
                      style: AppTextStyles.greeting,
                    ),
                    const SizedBox(height: 36),

                    // ── Nome completo ─────────────────────────
                    _label('Nome completo'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nomeCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'Ex: João Silva',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Informe seu nome'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // ── Apelido ───────────────────────────────
                    _label('Apelido (exibido no app)'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _apelidoCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'Ex: João',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Informe um apelido'
                          : null,
                    ),

                    // ── PIN (somente offline) ─────────────────
                    if (!_isGoogleUser) ...[
                      const SizedBox(height: 16),
                      _label('PIN de 4 dígitos'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _pinCtrl,
                        keyboardType: TextInputType.number,
                        obscureText: _obscurePin,
                        maxLength: 4,
                        decoration: InputDecoration(
                          hintText: '••••',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePin
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePin = !_obscurePin),
                          ),
                          counterText: '',
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Informe um PIN';
                          if (v.length < 4) return 'PIN deve ter 4 dígitos';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _label('Confirmar PIN'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _pinConfCtrl,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 4,
                        decoration: const InputDecoration(
                          hintText: '••••',
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                          counterText: '',
                        ),
                        validator: (v) {
                          if (v != _pinCtrl.text) return 'PINs não coincidem';
                          return null;
                        },
                      ),
                    ],

                    const SizedBox(height: 36),

                    // ── Botão principal ───────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _criarPerfil,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _isGoogleUser
                                    ? 'Começar minha jornada'
                                    : 'Criar meu perfil offline',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        _isGoogleUser
                            ? 'Conta vinculada ao Google · dados salvos na nuvem'
                            : 'Dados salvos localmente · sem conta · sem internet',
                        style: AppTextStyles.xpLabel,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Badge Google (canto superior direito) ─────────
            if (_isGoogleUser)
              Positioned(
                top: 12,
                right: 16,
                child: _GoogleAccountBadge(profile: widget.googleProfile!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text, style: AppTextStyles.sectionLabel);
}

// ─────────────────────────────────────────────────────────────
// Badge que mostra a conta Google vinculada
// ─────────────────────────────────────────────────────────────
class _GoogleAccountBadge extends StatelessWidget {
  final UserProfile profile;
  const _GoogleAccountBadge({required this.profile});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasPhoto = profile.photoUrl.isNotEmpty;
    final hasEmail = profile.email.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar
          CircleAvatar(
            radius: 13,
            backgroundImage:
                hasPhoto ? NetworkImage(profile.photoUrl) : null,
            backgroundColor: AppColors.primary.withOpacity(0.18),
            child: !hasPhoto
                ? Icon(
                    Icons.person_rounded,
                    size: 15,
                    color: AppColors.primary,
                  )
                : null,
          ),
          const SizedBox(width: 7),
          // E-mail
          Text(
            hasEmail ? profile.email : 'Google',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
