import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://coxhpaaadqutvglqrvmh.supabase.co',
    publishableKey: 'sb_publishable_f3o0MEx1lDWT2E-_9pRC4Q_HidYD35i',
  );

  runApp(const BmiAiApp());
}

class BmiAiApp extends StatelessWidget {
  const BmiAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BMI AI',
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    final session = supabase.auth.currentSession;

    if (session != null) {
      return const HomeScreen();
    }

    return const SplashScreen();
  }
}
