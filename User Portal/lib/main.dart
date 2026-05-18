import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routing/app_router.dart';
import 'core/services/connectivity_provider.dart';
import 'core/theme/app_theme.dart';

import 'core/theme/theme_provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("🔥 Firebase connected to project: rathtech-a73db");
  } catch (e) {
    debugPrint("⚠️ Firebase initialization error: $e");
  }

  runApp(
    const ProviderScope(
      child: RathTechUserPOSApp(),
    ),
  );
}

class RathTechUserPOSApp extends ConsumerWidget {
  const RathTechUserPOSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize connectivity watcher immediately on app bootstrap to start auto-sync listeners
    ref.read(connectivityServiceProvider.notifier);
    
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'RathTech POS Terminal',
      debugShowCheckedModeBanner: false,
      
      // Aesthetic Dark/Light Configuration
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      
      // Root Navigation Configuration
      routerConfig: router,
    );
  }
}
