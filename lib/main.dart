import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shiftly/providers/settings_provider.dart';
import 'package:shiftly/providers/shift_provider.dart';
import 'package:shiftly/providers/timer_provider.dart';
import 'package:shiftly/screens/splash_screen.dart';
import 'package:shiftly/services/notification_service.dart';
import 'package:shiftly/services/persistence_service.dart';
import 'package:shiftly/theme/app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Never let notification engine failure take down the whole app.
    try {
      await NotificationService.init();
    } catch (e) {
      debugPrint('NotificationService.init failed (non-fatal): $e');
    }

    await initializeDateFormatting('he_IL', null);

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
          ChangeNotifierProvider(
            create: (_) => TimerProvider(persistenceService),
          ),
        ],
        child: const SalaryTrackerApp(),
      ),
    );
  } catch (e) {
    debugPrint('Critical error during initialization: $e');
    // Still try to run the app even if some services fail
    runApp(
      const MaterialApp(
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('he', 'IL')],
        locale: Locale('he', 'IL'),
        home: Scaffold(
          body: Center(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text('שגיאה בעליית האפליקציה. נא לנסות שוב.'),
            ),
          ),
        ),
      ),
    );
  }
}

class SalaryTrackerApp extends StatelessWidget {
  const SalaryTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'Shiftly',
      navigatorKey: navigatorKey,
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
