import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:legalgo_mobile/core/widgets/state_views.dart';
import 'package:legalgo_mobile/features/shared/presentation/providers/legalgo_providers.dart';
import 'package:legalgo_mobile/features/shared/presentation/widgets/portal_widgets.dart';

class ClientDashboardScreen extends ConsumerWidget {
  const ClientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(clientRequestsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: requestsAsync.when(
        loading: () => const LoadingView(message: 'Loading dashboard'),
        error: (error, _) => ErrorStateView(message: error.toString(), onRetry: () => ref.invalidate(clientRequestsProvider)),
        data: (requests) {
          final inProgress = requests.where((item) => !{'completed', 'rejected', 'cancelled'}.contains(item.status)).length;
          final completed = requests.where((item) => item.status == 'completed').length;
          final recent = requests.take(5).toList();
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(clientRequestsProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                const ScreenHeader(title: 'Your LegalGo workspace', subtitle: 'Track active files, payments, and documents from one place.'),
                ResponsiveGrid(
                  children: [
                    MetricTile(title: 'Total requests', value: '${requests.length}', icon: Icons.folder_copy_outlined),
                    MetricTile(title: 'In progress', value: '$inProgress', icon: Icons.timelapse_outlined),
                    MetricTile(title: 'Completed', value: '$completed', icon: Icons.verified_outlined),
                  ],
                ),
                const SizedBox(height: 18),
                Text('Recent requests', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                if (recent.isEmpty)
                  const SizedBox(height: 260, child: EmptyStateView(icon: Icons.folder_off_outlined, title: 'No requests yet', message: 'Your existing LegalGo requests will appear here.'))
                else
                  for (final request in recent)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: Text(request.reference),
                        subtitle: Text('${request.service?.title ?? 'Service'} • ${money(request.totalPrice)}'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.go('/client/requests/${request.id}'),
                      ),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}
