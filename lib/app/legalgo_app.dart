import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalgo_mobile/app/router/app_router.dart';
import 'package:legalgo_mobile/app/theme/app_theme.dart';
import 'package:legalgo_mobile/app/theme/theme_controller.dart';
import 'package:legalgo_mobile/features/auth/presentation/providers/auth_providers.dart';

class LegalGoApp extends ConsumerStatefulWidget {
  const LegalGoApp({super.key});

  @override
  ConsumerState<LegalGoApp> createState() => _LegalGoAppState();
}

class _LegalGoAppState extends ConsumerState<LegalGoApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(authControllerProvider.notifier).bootstrap());
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeControllerProvider);

    return MaterialApp.router(
      title: 'LegalGo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
