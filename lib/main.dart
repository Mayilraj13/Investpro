import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'core/constants/api_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use host machine's LAN IP only for mobile devices needing remote proxy access.
  // On web, localhost is used directly.
  // ApiConfig.baseHostOverride = '10.135.80.100';

  // Initialize Firebase (gracefully skips if running with placeholder config)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init skipped (configure Firebase first): $e');
  }

  runApp(const ProviderScope(child: InvestProApp()));
}

class InvestProApp extends ConsumerWidget {
  const InvestProApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'InvestPro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
