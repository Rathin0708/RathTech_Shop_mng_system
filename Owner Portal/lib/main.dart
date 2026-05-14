import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase prior to launching app viewports
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: RathTechOwnerPortalApp(),
    ),
  );
}

class RathTechOwnerPortalApp extends ConsumerWidget {
  const RathTechOwnerPortalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'RathTech SaaS Owner Portal',
      debugShowCheckedModeBanner: false,
      
      // Theme Layer Configuration
      themeMode: ThemeMode.system, // Follow system UI lightness automatically
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      
      // Router Routing Hook
      routerConfig: router,
    );
  }
}
