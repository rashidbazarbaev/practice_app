import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'providers/student_provider.dart';
import 'providers/task_provider.dart';
import 'providers/note_provider.dart';
import 'providers/pomodoro_provider.dart';
import 'providers/auth_provider.dart' as app_auth;
import 'providers/schedule_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru', null);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const StudentProgressApp());
}

class StudentProgressApp extends StatelessWidget {
  const StudentProgressApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => app_auth.AuthProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => NoteProvider()),
        ChangeNotifierProvider(create: (_) => PomodoroProvider()),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProv, _) => MaterialApp(
          title: 'Student Progress Tracker',
          debugShowCheckedModeBanner: false,
          theme: themeProv.lightTheme,
          darkTheme: themeProv.darkTheme,
          themeMode: themeProv.flutterThemeMode,
          home: const _AppRouter(),
        ),
      ),
    );
  }
}

/// Listens to auth state and routes to Login or Main screen.
class _AppRouter extends StatelessWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<app_auth.AuthProvider>();

    switch (authProv.status) {
      case app_auth.AuthStatus.unknown:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case app_auth.AuthStatus.authenticated:
        return const MainScreen();
      case app_auth.AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}
