import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routing/app_router.dart';
import 'core/services/connectivity_provider.dart';
import 'core/theme/app_theme.dart';

// NOTE: Run 'flutterfire configure' in User Portal directory to generate firebase_options.dart.
// Once generated, uncomment the following lines to wire up Firebase.
/*
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
*/

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase conditionally to prevent initial runtime crashes before config
  try {
    /*
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    */
    debugPrint("🚀 System bootstrapped. Please complete 'flutterfire configure' to connect Cloud Sync.");
  } catch (e) {
    debugPrint("⚠️ Firebase not initialized yet: $e");
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

    return MaterialApp.router(
      title: 'RathTech POS Terminal',
      debugShowCheckedModeBanner: false,
      
      // Aesthetic Dark/Light Configuration
      themeMode: ThemeMode.system,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      
      // Root Navigation Configuration
      routerConfig: router,
    );
  }
}
