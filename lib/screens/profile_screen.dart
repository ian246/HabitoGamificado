import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';
import '../main.dart';
import 'signup_screen.dart';

class ProfileScreen extends StatefulWidget {
  final UserProfile?  profile;
  final VoidCallback? onProfileUpdate;

  const ProfileScreen({
    super.key,
    this.profile,
    this.onProfileUpdate,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _darkMode = widget.profile?.darkMode ?? false;
  }

  Future<void> _toggleDark(bool value) async {
    setState(() => _darkMode = value);
    final profile = widget.profile;
    if (profile == null) return;
    final atualizado = profile.copyWith(darkMode: value);
    await StorageService.instance.saveProfile(atualizado);
    if (!mounted) return;
    HabitFlowApp.of(context).setTheme(value);
    widget.onProfileUpdate?.call();
  }

  Future<void> _resetApp() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Resetar app?'),
        content: const Text(
          'Isso apagará todos os hábitos, conquistas e o perfil. '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Apagar tudo')),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await StorageService.instance.clearAll();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignupScreen()),
        (_) => false,
      );
    }
  }

  Future<void> _exportar() async {
    final json = await StorageService.instance.exportAll();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Backup dos dados'),
        content: SingleChildScrollView(
          child: SelectableText(json,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final theme   = profile != null
        ? AppColors.themeForXp(profile.xpTotal)
        : AppColors.levelThemes.first;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Avatar e info ──────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius:          40,
                  backgroundColor: theme.surface,
                  child: Text(
                    profile?.apelido.isNotEmpty == true
                        ? profile!.apelido[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                        fontSize:   32,
                        fontWeight: FontWeight.w700,
                        color:      theme.primary),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  profile?.apelido ?? 'Usuário',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  profile?.nome ?? '',
                  style: AppTextStyles.greeting,
                ),
                const SizedBox(height: 12),

                // Badges de nível e XP
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Badge(
                      label: 'Nível ${profile?.nivel ?? 1}',
                      sub:   profile?.nomeDonivel ?? 'Broto',
                      color: theme.primary,
                    ),
                    const SizedBox(width: 12),
                    _Badge(
                      label: '${profile?.xpTotal ?? 0} XP',
                      sub:   'Total acumulado',
                      color: AppColors.streak,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Barra de progresso do nível
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value:           profile?.progressoNivel ?? 0,
                    minHeight:       6,
                    color:           theme.primary,
                    backgroundColor: AppColors.surfaceCard,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile != null
                      ? 'Faltam ${profile.xpProximoNivel - profile.xpTotal} XP para o próximo nível'
                      : '',
                  style: AppTextStyles.xpLabel,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Configurações ──────────────────────────────────
        Text('Configurações', style: AppTextStyles.sectionLabel),
        const SizedBox(height: 8),

        Card(
          child: Column(
            children: [
              SwitchListTile(
                title:     const Text('Modo escuro'),
                subtitle:  Text('Tema escuro para o app',
                    style: AppTextStyles.xpLabel),
                secondary: const Icon(Icons.dark_mode_outlined),
                value:     _darkMode,
                onChanged: _toggleDark,
                activeColor: AppColors.primary,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title:   const Text('Notificações'),
                subtitle: Text(
                  profile?.notificacoesAtivas == true
                      ? 'Ativas'
                      : 'Desativadas',
                  style: AppTextStyles.xpLabel,
                ),
                trailing: Switch(
                  value: profile?.notificacoesAtivas ?? true,
                  onChanged: (v) async {
                    if (profile == null) return;
                    final atualizado =
                        profile.copyWith(notificacoesAtivas: v);
                    await StorageService.instance.saveProfile(atualizado);
                    widget.onProfileUpdate?.call();
                  },
                  activeColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Dados ──────────────────────────────────────────
        Text('Dados', style: AppTextStyles.sectionLabel),
        const SizedBox(height: 8),

        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.file_download_outlined,
                    color: AppColors.primary),
                title: const Text('Exportar backup'),
                subtitle: Text('JSON com todos os seus dados',
                    style: AppTextStyles.xpLabel),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _exportar,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.delete_forever_outlined,
                    color: AppColors.error),
                title: Text('Resetar app',
                    style:
                        TextStyle(color: AppColors.error)),
                subtitle: Text('Apaga todos os dados',
                    style: AppTextStyles.xpLabel),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _resetApp,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Info do app ────────────────────────────────────
        Center(
          child: Text(
            'HabitFlow v1.0  ·  Dados locais  ·  Sem internet',
            style: AppTextStyles.xpLabel,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final String sub;
  final Color  color;

  const _Badge({
    required this.label,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color)),
            const SizedBox(height: 2),
            Text(sub, style: AppTextStyles.xpLabel),
          ],
        ),
      );
}
