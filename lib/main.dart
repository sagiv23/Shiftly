import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'providers/settings_provider.dart';
import 'providers/shift_provider.dart';
import 'screens/splash_screen.dart';
import 'services/persistence_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final persistenceService = PersistenceService();
  await persistenceService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(persistenceService),
        ),
        ChangeNotifierProvider(
          create: (_) => ShiftProvider(persistenceService),
        ),
      ],
      child: const SalaryTrackerApp(),
    ),
  );
}

class SalaryTrackerApp extends StatelessWidget {
  const SalaryTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'Planet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('he', 'IL')],
      locale: const Locale('he', 'IL'),
      home: const SplashScreen(),
    );
  }
}
