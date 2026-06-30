import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:legalgo_mobile/core/design_system/design_system.dart';
import 'package:legalgo_mobile/core/widgets/legalgo_mark.dart';
import 'package:legalgo_mobile/features/auth/presentation/providers/auth_providers.dart';

class ClientShellScreen extends ConsumerWidget {
  const ClientShellScreen({
    super.key,
    required this.currentPath,
    required this.child,
  });

  final String currentPath;
  final Widget child;

  static const _primaryDestinations = [
    PremiumNavDestination(
      '/client/dashboard',
      'Accueil',
      Icons.dashboard_outlined,
      Icons.dashboard_rounded,
    ),
    PremiumNavDestination(
      '/client/requests',
      'Demandes',
      Icons.folder_copy_outlined,
      Icons.folder_copy_rounded,
    ),
    PremiumNavDestination(
      '/client/documents',
      'Documents',
      Icons.description_outlined,
      Icons.description_rounded,
    ),
  ];

  static const _moreDestinations = [
    PremiumNavDestination(
      '/client/notifications',
      'Notifications',
      Icons.notifications_none_rounded,
      Icons.notifications_rounded,
    ),
    PremiumNavDestination(
      '/client/payments',
      'Paiements',
      Icons.credit_card_outlined,
      Icons.credit_card_rounded,
    ),
    PremiumNavDestination(
      '/client/profile',
      'Profil',
      Icons.person_outline,
      Icons.person_rounded,
    ),
    PremiumNavDestination(
      '/client/settings',
      'Paramètres',
      Icons.tune_outlined,
      Icons.tune_rounded,
    ),
  ];

  static const _railDestinations = [
    ..._primaryDestinations,
    ..._moreDestinations,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _selectedIndex(currentPath);
    final useRail = MediaQuery.sizeOf(context).width >= 760;

    if (useRail) {
      return Scaffold(
        backgroundColor: AppColors.pageBackground(context),
        body: SafeArea(
          child: Row(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface(context),
                  borderRadius: AppRadius.card,
                  border: Border.all(color: AppColors.subtleBorder(context)),
                  boxShadow: AppShadows.soft(context),
                ),
                child: NavigationRail(
                  backgroundColor: Colors.transparent,
                  selectedIndex: selectedIndex,
                  extended: MediaQuery.sizeOf(context).width >= 1120,
                  indicatorColor: AppColors.softIndigo.withValues(alpha: .12),
                  leading: const Padding(
                    padding: EdgeInsets.fromLTRB(12, 14, 12, 24),
                    child: LegalGoMark(compact: true),
                  ),
                  destinations: [
                    for (final destination in _railDestinations)
                      NavigationRailDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(
                          destination.selectedIcon,
                          color: AppColors.softIndigo,
                        ),
                        label: Text(destination.label),
                      ),
                  ],
                  onDestinationSelected: (index) =>
                      context.go(_railDestinations[index].path),
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.pageBackground(context),
      body: child,
      bottomNavigationBar: PremiumBottomNavigation(
        currentPath: currentPath,
        primaryDestinations: _primaryDestinations,
        moreDestinations: _moreDestinations,
        onDestinationSelected: (path) => context.go(path),
        onMoreSelected: () => _showMoreSheet(context, ref),
      ),
    );
  }

  Future<void> _showMoreSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plus',
                style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                  color: Theme.of(sheetContext).colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              for (final destination in _moreDestinations)
                PremiumMoreSheetItem(
                  destination: destination,
                  selected: currentPath.startsWith(destination.path),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.go(destination.path);
                  },
                ),
              Divider(
                height: AppSpacing.xl,
                color: Theme.of(sheetContext).colorScheme.outlineVariant,
              ),
              PremiumMoreSheetItem(
                destination: const PremiumNavDestination(
                  '/login',
                  'Déconnexion',
                  Icons.logout_rounded,
                  Icons.logout_rounded,
                ),
                selected: false,
                danger: true,
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await ref.read(authControllerProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

int _selectedIndex(String path) {
  final index = ClientShellScreen._railDestinations.indexWhere(
    (item) => path.startsWith(item.path),
  );
  return index < 0 ? 0 : index;
}
