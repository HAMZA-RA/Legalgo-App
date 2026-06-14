import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:legalgo_mobile/core/widgets/legalgo_mark.dart';

class ClientShellScreen extends StatelessWidget {
  const ClientShellScreen({
    super.key,
    required this.currentPath,
    required this.child,
  });

  final String currentPath;
  final Widget child;

  static const _destinations = [
    _ShellDestination('/client/dashboard', 'Dashboard', Icons.dashboard_outlined, Icons.dashboard_rounded),
    _ShellDestination('/client/requests', 'Requests', Icons.folder_copy_outlined, Icons.folder_copy_rounded),
    _ShellDestination('/client/documents', 'Documents', Icons.description_outlined, Icons.description_rounded),
    _ShellDestination('/client/payments', 'Payments', Icons.credit_card_outlined, Icons.credit_card_rounded),
    _ShellDestination('/client/profile', 'Profile', Icons.person_outline, Icons.person_rounded),
    _ShellDestination('/client/settings', 'Settings', Icons.settings_outlined, Icons.settings_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex(currentPath);
    final useRail = MediaQuery.sizeOf(context).width >= 760;

    if (useRail) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              NavigationRail(
                selectedIndex: selectedIndex,
                extended: MediaQuery.sizeOf(context).width >= 1100,
                leading: const Padding(
                  padding: EdgeInsets.fromLTRB(12, 12, 12, 24),
                  child: LegalGoMark(compact: true),
                ),
                destinations: [
                  for (final destination in _destinations)
                    NavigationRailDestination(
                      icon: Icon(destination.icon),
                      selectedIcon: Icon(destination.selectedIcon),
                      label: Text(destination.label),
                    ),
                ],
                onDestinationSelected: (index) => context.go(_destinations[index].path),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: child),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: [
          for (final destination in _destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.label,
            ),
        ],
        onDestinationSelected: (index) => context.go(_destinations[index].path),
      ),
    );
  }
}

int _selectedIndex(String path) {
  final index = ClientShellScreen._destinations.indexWhere((item) => path.startsWith(item.path));
  return index < 0 ? 0 : index;
}

class _ShellDestination {
  const _ShellDestination(this.path, this.label, this.icon, this.selectedIcon);

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
