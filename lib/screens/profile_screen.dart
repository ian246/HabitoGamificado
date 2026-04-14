import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_app_habitos/services/notification_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/achievement_trail.dart';
import '../models/user_profile.dart';
import '../models/achievement.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../main.dart';
import 'signup_screen.dart';
import 'login_screen.dart' show kProfilePhotoKey;

class ProfileScreen extends StatefulWidget {
  final UserProfile? profile;
  final VoidCallback? onProfileUpdate;

  const ProfileScreen({super.key, this.profile, this.onProfileUpdate});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _darkMode = false;
  String? _photoPath;
  bool _signingOut = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _darkMode = widget.profile?.darkMode ?? false;
    _loadPhoto();
  }

  // ── Foto de perfil ────────────────────────────────────────────────────────

  Future<void> _loadPhoto() async {
    final profile = widget.profile;

    // Prioridade 1: foto local trocada pelo usuário (useLocalPhoto)
    if (profile != null &&
        profile.useLocalPhoto &&
        profile.photoUrl.isNotEmpty) {
      if (File(profile.photoUrl).existsSync()) {
        setState(() => _photoPath = profile.photoUrl);
        return;
      }
    }

    // Prioridade 2: caminho salvo em SharedPreferences (compatibilidade v1)
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(kProfilePhotoKey);
    if (path != null && File(path).existsSync()) {
      setState(() => _photoPath = path);
      return;
    }

    // Prioridade 3: URL remota do Google (deixa _photoPath null e usa NetworkImage no avatar)
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceHover,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Câmera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Galeria'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            if (_photoPath != null)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                ),
                title: const Text('Remover foto'),
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove(kProfilePhotoKey);
                  setState(() => _photoPath = null);

                  // Atualiza perfil: volta para URL do Google
                  final profile = widget.profile;
                  if (profile != null) {
                    final updated = profile.copyWith(
                      photoUrl: profile.isFirebaseUser
                          ? (AuthService.instance.currentUser?.photoURL ?? '')
                          : '',
                      useLocalPhoto: false,
                    );
                    await AuthService.instance.saveProfile(updated);
                    if (profile.isFirebaseUser) {
                      await AuthService.instance.updatePhotoUrl(
                        profile.uid,
                        updated.photoUrl,
                      );
                    }
                    widget.onProfileUpdate?.call();
                  }
                  if (!mounted) return;
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 85,
    );
    if (picked == null) return;

    // Salva localmente (SharedPreferences — compatibilidade v1)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kProfilePhotoKey, picked.path);
    setState(() => _photoPath = picked.path);

    // Atualiza o perfil com o novo caminho e flag de foto local
    final profile = widget.profile;
    if (profile != null) {
      final updated = profile.copyWith(
        photoUrl: picked.path,
        useLocalPhoto: true,
      );
      await AuthService.instance.saveProfile(updated);
      if (profile.isFirebaseUser) {
        await AuthService.instance.updatePhotoUrl(profile.uid, picked.path);
      }
      widget.onProfileUpdate?.call();
    }
  }

  // ── Título ────────────────────────────────────────────────────────────────

  Future<void> _selectTitle(BuildContext ctx) async {
    final profile = widget.profile;
    if (profile == null) return;
    final unlocked = AchievementTrails.allUnlockedLevels(profile.trailProgress);
    if (unlocked.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('Conquiste seu primeiro título primeiro! 🏆'),
        ),
      );
      return;
    }
    await showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TitleSelectionSheet(
        unlocked: unlocked,
        currentKey: profile.selectedTitleKey,
        onSelect: (key) async {
          final updated = profile.copyWith(selectedTitleKey: key);
          await AuthService.instance.saveProfile(updated);
          widget.onProfileUpdate?.call();
        },
      ),
    );
  }

  // ── Dark mode ─────────────────────────────────────────────────────────────

  Future<void> _toggleDark(bool value) async {
    setState(() => _darkMode = value);
    final profile = widget.profile;
    if (profile == null) return;
    await AuthService.instance.saveProfile(profile.copyWith(darkMode: value));
    if (!mounted) return;
    HabitFlowApp.of(context).setTheme(value);
    widget.onProfileUpdate?.call();
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text(
          'Cada conta Google tem seus próprios hábitos.\nAo sair, os dados locais serão limpos para proteger sua privacidade.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sair e limpar dados'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _signingOut = true);

    // Limpa TUDO localmente para garantir isolamento total (v2.1)
    await StorageService.instance.clearAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kProfilePhotoKey);
    await NotificationService.instance.cancelAll();

    await AuthService.instance.signOut();
    // StreamBuilder no main.dart detecta o logout e volta para LoginScreen.
  }

  // ── Reset local ───────────────────────────────────────────────────────────

  Future<void> _resetApp() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Resetar app?'),
        content: const Text('Apagará todos os dados. Não pode ser desfeito.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Apagar tudo'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await StorageService.instance.clearAll();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(kProfilePhotoKey);
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
          child: SelectableText(
            json,
            style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────


  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        // ── 1. Header (Avatar, Nome, Nível) — idêntico ao original
        _buildIdentityHeader(context, profile),
        const SizedBox(height: 20),

        // ── 2. Jornada da Patente — idêntico ao original
        if (profile != null) _buildRankJourney(context, profile),
        if (profile != null) const SizedBox(height: 20),

        // ── 3. Atributos do Jogador — idêntico ao original
        if (profile != null) _buildPlayerStats(context, profile),
        if (profile != null) const SizedBox(height: 20),

        // ── 4. Conta Google (NOVO — só aparece se usuário Firebase)
        if (profile != null && profile.isFirebaseUser) ...[
          _buildAccountSection(context, profile),
          const SizedBox(height: 20),
        ],

        // ── 5. Configurações — idêntico ao original
        Text('Configurações', style: AppTextStyles.sectionLabel),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Modo escuro'),
                subtitle: Text(
                  'Tema escuro do app',
                  style: AppTextStyles.xpLabel,
                ),
                secondary: Icon(
                  _darkMode
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  color: _darkMode ? AppColors.blueAccent : AppColors.streak,
                ),
                value: _darkMode,
                onChanged: _toggleDark,
                activeColor: AppColors.primary,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Notificações'),
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
                    await AuthService.instance.saveProfile(
                      profile.copyWith(notificacoesAtivas: v),
                    );
                    widget.onProfileUpdate?.call();
                  },
                  activeColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── 6. Dados — idêntico ao original
        Text('Dados', style: AppTextStyles.sectionLabel),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.file_download_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Exportar backup'),
                subtitle: Text(
                  'JSON com todos os seus dados',
                  style: AppTextStyles.xpLabel,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _exportar,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(
                  Icons.delete_forever_outlined,
                  color: AppColors.error,
                ),
                title: const Text(
                  'Resetar app',
                  style: TextStyle(color: AppColors.error),
                ),
                subtitle: Text(
                  'Apaga todos os dados',
                  style: AppTextStyles.xpLabel,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _resetApp,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Center(
          child: Text(
            profile?.isFirebaseUser == true
                ? 'HabitFlow  ·  Sincronizado com Google'
                : 'HabitFlow  ·  Dados locais',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SEÇÃO NOVA: Conta Google
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildAccountSection(BuildContext context, UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Conta', style: AppTextStyles.sectionLabel),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              // Chip da conta conectada
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Google conectado',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(profile.email, style: AppTextStyles.xpLabel),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),

              // Botão sair
              ListTile(
                leading: _signingOut
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout_rounded, color: AppColors.error),
                title: const Text(
                  'Sair da conta',
                  style: TextStyle(color: AppColors.error),
                ),
                subtitle: Text(
                  'Dados ficam salvos na nuvem',
                  style: AppTextStyles.xpLabel,
                ),
                onTap: _signingOut ? null : _handleSignOut,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SUB-WIDGETS GAMIFICADOS — idênticos ao original, apenas avatar atualizado
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildIdentityHeader(BuildContext context, UserProfile? profile) {
    final theme = profile != null
        ? AppColors.themeForXp(profile.xpTotal)
        : AppColors.levelThemes.first;

    return Column(
      children: [
        // Avatar — agora suporta URL remota (Google) além de arquivo local
        GestureDetector(
          onTap: _pickPhoto,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              _ProfileAvatar(
                profile: profile,
                localPhotoPath: _photoPath,
                theme: theme,
                radius: 54,
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text(
          profile?.apelido ?? 'Usuário',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(profile?.nome ?? '', style: AppTextStyles.greeting),
        const SizedBox(height: 12),

        // Tag de Nível — idêntico ao original
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: theme.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.primary.withAlpha(50)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, size: 16, color: theme.primary),
              const SizedBox(width: 6),
              Text(
                'Nível ${profile?.nivel ?? 1} • ${profile?.nomeDonivel ?? "Broto"} • ${profile?.rank ?? "Prata"}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: theme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.primary.withAlpha(100),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${profile?.xpTotal ?? 0} XP',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.streak,
                ),
              ),
            ],
          ),
        ),

        // Tag de Título Ativo — idêntico ao original
        if (profile != null) ...[
          const SizedBox(height: 10),
          Builder(
            builder: (ctx) {
              final active = profile.activeTitle;
              final hasTitle = active != null;
              final titleColor = hasTitle
                  ? Color(active.level.tier.colorValue)
                  : AppColors.textHint;
              return GestureDetector(
                onTap: () => _selectTitle(ctx),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: titleColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: titleColor.withOpacity(0.4),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasTitle) ...[
                        Text(
                          active.trail.emoji,
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(width: 5),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 180),
                          child: Text(
                            active.level.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: titleColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ] else
                        Text(
                          'Sem título ainda',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textHint,
                          ),
                        ),
                      const SizedBox(width: 6),
                      Icon(Icons.edit_rounded, size: 12, color: titleColor),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  // Jornada da Patente — agora baseada em NÍVEL
  Widget _buildRankJourney(BuildContext context, UserProfile profile) {
    final currentLevel = profile.nivel;
    final currentFrame = AppColors.frameForLevel(currentLevel);

    int minLevel = 1;
    int nextLevelThreshold = 5;
    FrameColors? nextFrame = AppColors.gold;

    if (currentLevel < 5) {
      minLevel = 1;
      nextLevelThreshold = 5;
      nextFrame = AppColors.gold;
    } else if (currentLevel < 15) {
      minLevel = 5;
      nextLevelThreshold = 15;
      nextFrame = AppColors.platinum;
    } else if (currentLevel < 30) {
      minLevel = 15;
      nextLevelThreshold = 30;
      nextFrame = AppColors.emerald;
    } else if (currentLevel < 50) {
      minLevel = 30;
      nextLevelThreshold = 50;
      nextFrame = AppColors.diamond;
    } else if (currentLevel < 80) {
      minLevel = 50;
      nextLevelThreshold = 80;
      nextFrame = AppColors.master;
    } else {
      minLevel = 80;
      nextLevelThreshold = 80;
      nextFrame = null;
    }

    double progress = 1.0;
    if (nextFrame != null) {
      progress = ((currentLevel - minLevel) / (nextLevelThreshold - minLevel))
          .clamp(0.0, 1.0);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.map_rounded,
                  size: 20,
                  color: AppColors.streak,
                ),
                const SizedBox(width: 8),
                Text('Jornada da Patente', style: AppTextStyles.habitName),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    _buildFrameImage(currentFrame.name, size: 70),
                    const SizedBox(height: 8),
                    Text(
                      currentFrame.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: currentFrame.text,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Text(
                          'Nível $currentLevel',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: progress),
                            duration: const Duration(seconds: 1),
                            curve: Curves.easeOut,
                            builder: (_, val, __) => LinearProgressIndicator(
                              value: val,
                              minHeight: 8,
                              backgroundColor: AppColors.surfaceHover,
                              color: currentFrame.ring,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (nextFrame != null)
                          Text(
                            'Faltam ${nextLevelThreshold - currentLevel} níveis',
                            style: AppTextStyles.xpLabel.copyWith(fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                ),
                if (nextFrame != null)
                  Column(
                    children: [
                      _buildFrameImage(
                        nextFrame.name,
                        size: 70,
                        isLocked: true,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        nextFrame.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildFrameImage('Mestre', size: 70),
                      const SizedBox(height: 8),
                      const Text(
                        'Máximo',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.streak,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrameImage(
    String rawName, {
    double size = 60,
    bool isLocked = false,
  }) {
    final frameName = rawName.toLowerCase();
    final assetPath = 'assets/frames/${frameName}_frame.png';
    Widget image = Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surfaceHover,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.image_not_supported,
          color: Colors.grey,
          size: 24,
        ),
      ),
    );
    if (isLocked) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Opacity(opacity: 0.35, child: image),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(100),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ],
      );
    }
    return image;
  }

  Widget _buildPlayerStats(BuildContext context, UserProfile profile) {
    final totalDiasAtivos =
        profile.conquistas[AchievementCategory.geral]?.diasConcluidos.length ??
        0;
    final maxStreakGeral =
        profile.conquistas[AchievementCategory.geral]?.melhorStreak ?? 0;
    final diasPerfeitos = profile.diasPerfeitos.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Atributos de Jogador', style: AppTextStyles.sectionLabel),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _darkMode ? AppColors.darkCard : AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withAlpha(30)),
          ),
          child: Column(
            children: [
              _StatRow(
                icon: Icons.star_rounded,
                color: const Color(0xFFD4AF37),
                label: 'Dias Perfeitos (100%)',
                value: diasPerfeitos.toString(),
                description: 'Dias com todos os hábitos completados',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              _StatRow(
                icon: Icons.local_fire_department_rounded,
                color: AppColors.streak,
                label: 'Sequência Máxima',
                value: maxStreakGeral.toString(),
                description: 'Maior número de dias seguidos ativos',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              _StatRow(
                icon: Icons.event_available_rounded,
                color: AppColors.primary,
                label: 'Total de Dias Ativos',
                value: totalDiasAtivos.toString(),
                description: 'Dias em que você completou ao menos 1 hábito',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              _StatRow(
                icon: Icons.emoji_events_rounded,
                color: const Color(0xFFCD7F32), // Bronze/Cobre metálico
                label: 'Total de Conquistas',
                value: profile.totalAchievementsCount.toString(),
                description: 'Soma de todos os marcos desbloqueados',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Avatar unificado: local > URL Google > inicial do nome
// ─────────────────────────────────────────────────────────────
class _ProfileAvatar extends StatelessWidget {
  final UserProfile? profile;
  final String? localPhotoPath;
  final dynamic theme; // LevelTheme do AppColors
  final double radius;

  const _ProfileAvatar({
    required this.profile,
    required this.localPhotoPath,
    required this.theme,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Foto local (câmera/galeria)
    if (localPhotoPath != null && File(localPhotoPath!).existsSync()) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: theme.surface,
        backgroundImage: FileImage(File(localPhotoPath!)),
      );
    }

    // 2. URL remota do Google
    final remoteUrl = profile?.photoUrl ?? '';
    if (remoteUrl.startsWith('http') && !profile!.useLocalPhoto) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: theme.surface,
        backgroundImage: NetworkImage(remoteUrl),
        onBackgroundImageError: (_, __) {},
      );
    }

    // 3. Inicial do nome (fallback)
    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.surface,
      child: Text(
        profile?.apelido.isNotEmpty == true
            ? profile!.apelido[0].toUpperCase()
            : '?',
        style: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w700,
          color: theme.primary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Widgets auxiliares — idênticos ao original
// ─────────────────────────────────────────────────────────────
class _StatRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String description;

  const _StatRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                description,
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _TitleSelectionSheet extends StatefulWidget {
  final List<({AchievementTrail trail, TrailLevel level})> unlocked;
  final String? currentKey;
  final Future<void> Function(String? key) onSelect;

  const _TitleSelectionSheet({
    required this.unlocked,
    required this.currentKey,
    required this.onSelect,
  });

  @override
  State<_TitleSelectionSheet> createState() => _TitleSelectionSheetState();
}

class _TitleSelectionSheetState extends State<_TitleSelectionSheet> {
  late String? _selectedKey;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedKey = widget.currentKey;
  }

  Future<void> _confirm() async {
    setState(() => _saving = true);
    await widget.onSelect(_selectedKey);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceHover,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Escolha seu Título',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${widget.unlocked.length} títulos desbloqueados',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: widget.unlocked.length,
                itemBuilder: (_, i) {
                  final item = widget.unlocked[i];
                  final key = AchievementTrails.titleKey(
                    item.trail.id,
                    item.level.tier,
                  );
                  final isSelected = _selectedKey == key;
                  final tierColor = Color(item.level.tier.colorValue);

                  return GestureDetector(
                    onTap: () => setState(() => _selectedKey = key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? tierColor.withOpacity(0.12)
                            : (isDark
                                  ? AppColors.surfaceCard
                                  : Colors.grey.shade50),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? tierColor
                              : AppColors.surfaceHover,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            item.trail.emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.level.title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? tierColor : null,
                                  ),
                                ),
                                Text(
                                  '${item.trail.name} · ${item.level.tier.label}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isSelected
                                        ? tierColor.withOpacity(0.8)
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle_rounded,
                              color: tierColor,
                              size: 22,
                            )
                          else
                            Icon(
                              Icons.radio_button_unchecked_rounded,
                              color: AppColors.surfaceHover,
                              size: 22,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _confirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Confirmar título',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
