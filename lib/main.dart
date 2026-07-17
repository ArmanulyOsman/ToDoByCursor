import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/local_task_repository.dart';
import 'data/supabase_task_repository.dart';
import 'data/task_repository.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final source = await _createTaskSource();
  runApp(
    TodoApp(
      repository: source.repository,
      cloudSyncEnabled: source.cloudSyncEnabled,
    ),
  );
}

Future<_TaskSource> _createTaskSource() async {
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  const supabaseKey = supabasePublishableKey.isNotEmpty
      ? supabasePublishableKey
      : supabaseAnonKey;

  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    return _TaskSource(LocalTaskRepository(), false);
  }

  try {
    await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);
    final client = Supabase.instance.client;
    final user =
        client.auth.currentUser ?? (await client.auth.signInAnonymously()).user;
    if (user != null) {
      return _TaskSource(
        SupabaseTaskRepository(client: client, userId: user.id),
        true,
      );
    }
  } catch (_) {
    // Локальный режим сохраняет работоспособность приложения без сети.
  }
  return _TaskSource(LocalTaskRepository(), false);
}

class _TaskSource {
  const _TaskSource(this.repository, this.cloudSyncEnabled);

  final TaskRepository repository;
  final bool cloudSyncEnabled;
}

class TodoApp extends StatelessWidget {
  const TodoApp({
    super.key,
    required this.repository,
    this.cloudSyncEnabled = false,
  });

  final TaskRepository repository;
  final bool cloudSyncEnabled;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF625BE8);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      surface: Colors.white,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Мои задачи',
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF2C2E3A)),
          bodyMedium: TextStyle(color: Color(0xFF2C2E3A)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF6F7FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
            side: const BorderSide(color: Color(0xFFE2E3EA)),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
      home: HomeScreen(
        repository: repository,
        cloudSyncEnabled: cloudSyncEnabled,
      ),
    );
  }
}
