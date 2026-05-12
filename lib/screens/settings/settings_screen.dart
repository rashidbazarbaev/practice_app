import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../models/student.dart';
import 'integrations_stub_screen.dart';
import '../profile/profile_edit_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    final studentProv = context.watch<StudentProvider>();
    final authProv = context.watch<app_auth.AuthProvider>();
    final student = studentProv.student;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: OutlinedButton.icon(
            onPressed: () => _confirmSignOut(context, authProv),
            icon: const Icon(Icons.logout, color: Color(0xFFF44336)),
            label: const Text(
              'Выйти из аккаунта',
              style: TextStyle(
                color: Color(0xFFF44336),
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              side: const BorderSide(color: Color(0xFFF44336)),
            ),
          ),
        ),
      ),
      body: ListView(
        children: [
          // ── Profile ──────────────────────────────────────────────────────
          _SectionHeader(title: 'Профиль'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                ListTile(
                  leading: _AvatarWidget(student: student),
                  title: Text(
                    student?.name ?? 'Студент',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(student?.faculty ?? ''),
                      Text(
                        '${student?.course ?? 1} курс',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: FilledButton.tonal(
                    onPressed: () => _editProfile(context, student),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Изменить'),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(Icons.email_outlined,
                      color: theme.colorScheme.outline),
                  title: Text(
                    authProv.user?.email ?? '—',
                    style: TextStyle(color: theme.colorScheme.outline),
                  ),
                  subtitle: const Text('Email аккаунта'),
                ),
              ],
            ),
          ),

          // ── Appearance ───────────────────────────────────────────────────
          _SectionHeader(title: 'Внешний вид'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_6_outlined),
                  title: const Text('Тема'),
                  subtitle: Text(_themeModeLabel(themeProv.themeMode)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showThemePicker(context, themeProv),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('Акцентный цвет'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: themeProv.accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => _showColorPicker(context, themeProv),
                ),
              ],
            ),
          ),

          // ── Integrations ─────────────────────────────────────────────────
          _SectionHeader(title: 'Интеграции (заготовка)'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                _IntegrationTile(
                  icon: Icons.calendar_month_outlined,
                  title: 'Расписание занятий',
                  subtitle: 'Синхронизация с расписанием',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) =>
                          const IntegrationsStubScreen(title: 'Расписание занятий'))),
                ),
                const Divider(height: 1, indent: 56),
                _IntegrationTile(
                  icon: Icons.sync_outlined,
                  title: 'Google Calendar',
                  subtitle: 'Синхронизация событий',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) =>
                          const IntegrationsStubScreen(title: 'Google Calendar'))),
                ),
                const Divider(height: 1, indent: 56),
                _IntegrationTile(
                  icon: Icons.school_outlined,
                  title: 'LMS / Moodle',
                  subtitle: 'Импорт заданий из системы',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) =>
                          const IntegrationsStubScreen(title: 'LMS / Moodle'))),
                ),
                const Divider(height: 1, indent: 56),
                _IntegrationTile(
                  icon: Icons.auto_awesome_outlined,
                  title: 'AI-помощник',
                  subtitle: 'Персональные рекомендации (скоро)',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) =>
                          const IntegrationsStubScreen(title: 'AI-помощник'))),
                ),
              ],
            ),
          ),

          // ── About ─────────────────────────────────────────────────────────
          _SectionHeader(title: 'О приложении'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Student Progress Tracker'),
              subtitle: Text('Версия 1.0.0'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _themeModeLabel(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return 'Системная';
      case AppThemeMode.light:
        return 'Светлая';
      case AppThemeMode.dark:
        return 'Тёмная';
    }
  }

  void _showThemePicker(BuildContext context, ThemeProvider themeProv) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Выберите тему',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ...AppThemeMode.values.map((mode) => ListTile(
                  title: Text(_themeModeLabel(mode)),
                  leading: Radio<AppThemeMode>(
                    value: mode,
                    groupValue: themeProv.themeMode,
                    onChanged: (v) {
                      if (v != null) themeProv.setThemeMode(v);
                      Navigator.pop(ctx);
                    },
                  ),
                  onTap: () {
                    themeProv.setThemeMode(mode);
                    Navigator.pop(ctx);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context, ThemeProvider themeProv) {
    final colors = [
      const Color(0xFF6C63FF),
      const Color(0xFF2196F3),
      const Color(0xFF4CAF50),
      const Color(0xFFFF5722),
      const Color(0xFFE91E63),
      const Color(0xFF9C27B0),
      const Color(0xFF00BCD4),
      const Color(0xFFFF9800),
      const Color(0xFF795548),
      const Color(0xFF607D8B),
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Акцентный цвет',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: colors
                  .map((c) => GestureDetector(
                        onTap: () {
                          themeProv.setAccentColor(c);
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: themeProv.accentColor == c
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: c.withValues(alpha: 0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: themeProv.accentColor == c
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 20)
                              : null,
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _editProfile(BuildContext context, Student? student) {
    if (student == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileEditScreen(student: student),
      ),
    );
  }

  void _confirmSignOut(
      BuildContext context, app_auth.AuthProvider authProv) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Выйти из аккаунта?'),
        content: Text(
          'Вы выйдете из аккаунта ${authProv.user?.email ?? ''}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              authProv.signOut();
            },
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF44336)),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }
}

class _AvatarWidget extends StatelessWidget {
  final Student? student;

  const _AvatarWidget({required this.student});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAvatar =
        student?.avatarPath != null && student!.avatarPath!.isNotEmpty;

    return CircleAvatar(
      radius: 24,
      backgroundColor: theme.colorScheme.primaryContainer,
      backgroundImage:
          hasAvatar ? FileImage(File(student!.avatarPath!)) : null,
      child: hasAvatar
          ? null
          : Text(
              student?.name.isNotEmpty == true
                  ? student!.name[0].toUpperCase()
                  : 'С',
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _IntegrationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _IntegrationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Скоро',
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
      onTap: onTap,
    );
  }
}
