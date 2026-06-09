import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/database_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/settings/pin_screen.dart';
import 'screens/home/dashboard_screen.dart';
import 'screens/transactions/transactions_screen.dart';
import 'core/utils/formatters.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbProvider = DatabaseProvider();
  try {
    await dbProvider.loadAll();
  } catch (e) {
    debugPrint('DB init error: $e');
  }
  final settingsProvider = SettingsProvider();
  await settingsProvider.load();
  CurrencyFormatter.symbol = settingsProvider.currencySymbol;
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: dbProvider),
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const HisabiApp(),
    ),
  );
}

class HisabiApp extends StatelessWidget {
  const HisabiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'Hisabi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const SplashScreen(),
      onGenerateRoute: (routeSettings) {
        switch (routeSettings.name) {
          case '/pin':
            return MaterialPageRoute(builder: (_) => const PinScreen());
          case '/home':
            return MaterialPageRoute(builder: (_) => const DashboardScreen());
          case '/add-transaction':
            final args = routeSettings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (_) => AddTransactionScreen(initialType: args?['type'] as String?),
            );
        }
        return null;
      },
    );
  }
}
