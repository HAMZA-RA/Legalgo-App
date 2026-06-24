import 'package:flutter/material.dart';
import 'package:legalgo_mobile/core/design_system/app_colors.dart';
import 'package:legalgo_mobile/core/design_system/app_radius.dart';
import 'package:legalgo_mobile/core/design_system/app_shadows.dart';
import 'package:legalgo_mobile/core/design_system/app_spacing.dart';

class PremiumNavDestination {
  const PremiumNavDestination(
    this.path,
    this.label,
    this.icon,
    this.selectedIcon,
  );

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class PremiumBottomNavigation extends StatelessWidget {
  const PremiumBottomNavigation({
    super.key,
    required this.currentPath,
    required this.primaryDestinations,
    required this.moreDestinations,
    required this.onDestinationSelected,
    required this.onMoreSelected,
  });

  final String currentPath;
  final List<PremiumNavDestination> primaryDestinations;
  final List<PremiumNavDestination> moreDestinations;
  final ValueChanged<String> onDestinationSelected;
  final VoidCallback onMoreSelected;

  @override
  Widget build(BuildContext context) {
    final moreSelected = moreDestinations.any(
      (destination) => currentPath.startsWith(destination.path),
    );
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardSurface(context),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.subtleBorder(context)),
            boxShadow: AppShadows.elevated(context),
          ),
          child: Row(
            children: [
              for (final destination in primaryDestinations)
                Expanded(
                  child: _PremiumBottomNavItem(
                    label: destination.label,
                    icon: destination.icon,
                    selectedIcon: destination.selectedIcon,
                    selected: currentPath.startsWith(destination.path),
                    onTap: () => onDestinationSelected(destination.path),
                  ),
                ),
              Expanded(
                child: _PremiumBottomNavItem(
                  label: 'Plus',
                  icon: Icons.more_horiz_rounded,
                  selectedIcon: Icons.more_horiz_rounded,
                  selected: moreSelected,
                  onTap: onMoreSelected,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PremiumMoreSheetItem extends StatelessWidget {
  const PremiumMoreSheetItem({
    super.key,
    required this.destination,
    required this.selected,
    required this.onTap,
    this.danger = false,
  });

  final PremiumNavDestination destination;
  final bool selected;
  final bool danger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = danger
        ? colorScheme.error
        : selected
        ? colorScheme.primary
        : colorScheme.onSurface;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .10),
          borderRadius: AppRadius.icon,
        ),
        child: Icon(
          selected ? destination.selectedIcon : destination.icon,
          color: color,
        ),
      ),
      title: Text(
        destination.label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}

class _PremiumBottomNavItem extends StatelessWidget {
  const _PremiumBottomNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.softIndigo.withValues(alpha: .10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? selectedIcon : icon,
              color: selected ? AppColors.softIndigo : AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(height: 3),
            SizedBox(
              height: 11,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: selected
                        ? AppColors.softIndigo
                        : AppColors.textMuted,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
