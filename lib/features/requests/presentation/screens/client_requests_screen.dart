import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:legalgo_mobile/core/widgets/state_views.dart';
import 'package:legalgo_mobile/features/shared/domain/legalgo_models.dart';
import 'package:legalgo_mobile/features/shared/presentation/providers/legalgo_providers.dart';
import 'package:legalgo_mobile/features/shared/presentation/widgets/portal_widgets.dart';

class ClientRequestsScreen extends ConsumerWidget {
  const ClientRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(clientRequestsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Requests')),
      body: requestsAsync.when(
        loading: () => const LoadingView(message: 'Loading requests'),
        error: (error, _) => ErrorStateView(message: error.toString(), onRetry: () => ref.invalidate(clientRequestsProvider)),
        data: (requests) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(clientRequestsProvider),
          child: requests.isEmpty
              ? const EmptyStateView(icon: Icons.folder_open_outlined, title: 'No requests', message: 'Your LegalGo request history is empty.')
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: requests.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _RequestCard(request: requests[index]),
                ),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final LegalRequest request;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/client/requests/${request.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(request.reference, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              const SizedBox(height: 8),
              Text(request.service?.title ?? 'Service unavailable'),
              Text(request.pack?.title ?? 'No pack', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [StatusChip(value: request.status), StatusChip(value: request.paymentStatus)]),
            ],
          ),
        ),
      ),
    );
  }
}

