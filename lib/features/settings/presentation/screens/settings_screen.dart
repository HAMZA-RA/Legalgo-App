import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:legalgo_mobile/app/theme/theme_controller.dart';
import 'package:legalgo_mobile/core/design_system/design_system.dart';
import 'package:legalgo_mobile/features/auth/presentation/providers/auth_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeControllerProvider);
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.pageBackground(context),
      appBar: const PremiumAppBar(title: 'Paramètres'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenHorizontal,
          AppSpacing.xs,
          AppSpacing.screenHorizontal,
          AppSpacing.screenBottom,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: 'Apparence',
                    subtitle: 'Choisissez le thème utilisé sur cet appareil',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    child: SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(Icons.brightness_auto_outlined),
                            label: Text('Système'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode_outlined),
                            label: Text('Clair'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode_outlined),
                            label: Text('Sombre'),
                          ),
                        ],
                        selected: {themeMode},
                        onSelectionChanged: (selection) {
                          ref
                              .read(themeControllerProvider.notifier)
                              .setMode(selection.first);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  const SectionHeader(
                    title: 'Session',
                    subtitle: 'Gérez l’accès à votre espace',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: authState.isLoading
                            ? null
                            : () async {
                                await ref
                                    .read(authControllerProvider.notifier)
                                    .logout();
                                if (context.mounted) context.go('/login');
                              },
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Se déconnecter'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
