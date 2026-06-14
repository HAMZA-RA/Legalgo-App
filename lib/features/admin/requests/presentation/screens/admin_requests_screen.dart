import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:legalgo_mobile/core/widgets/state_views.dart';
import 'package:legalgo_mobile/features/shared/domain/legalgo_models.dart';
import 'package:legalgo_mobile/features/shared/presentation/providers/legalgo_providers.dart';
import 'package:legalgo_mobile/features/shared/presentation/widgets/portal_widgets.dart';

class AdminRequestsScreen extends ConsumerStatefulWidget {
  const AdminRequestsScreen({super.key});

  @override
  ConsumerState<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends ConsumerState<AdminRequestsScreen> {
  final _search = TextEditingController();
  String? _status;
  String? _paymentStatus;
  int _page = 1;

  AdminRequestsQuery get _query => AdminRequestsQuery(search: _search.text, status: _status, paymentStatus: _paymentStatus, page: _page);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(adminRequestsProvider(_query));
    return Scaffold(
      appBar: AppBar(title: const Text('Requests')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            TextField(controller: _search, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Search requests'), onSubmitted: (_) => setState(() => _page = 1)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: DropdownButtonFormField<String?>(value: _status, decoration: const InputDecoration(labelText: 'Status'), items: const [DropdownMenuItem(value: null, child: Text('All')), DropdownMenuItem(value: 'pending_payment', child: Text('Pending payment')), DropdownMenuItem(value: 'documents_requested', child: Text('Docs requested')), DropdownMenuItem(value: 'processing', child: Text('Processing')), DropdownMenuItem(value: 'completed', child: Text('Completed'))], onChanged: (value) => setState(() { _status = value; _page = 1; }))),
              const SizedBox(width: 10),
              Expanded(child: DropdownButtonFormField<String?>(value: _paymentStatus, decoration: const InputDecoration(labelText: 'Payment'), items: const [DropdownMenuItem(value: null, child: Text('All')), DropdownMenuItem(value: 'pending', child: Text('Pending')), DropdownMenuItem(value: 'paid', child: Text('Paid')), DropdownMenuItem(value: 'failed', child: Text('Failed'))], onChanged: (value) => setState(() { _paymentStatus = value; _page = 1; }))),
            ]),
          ]),
        ),
        Expanded(
          child: requestsAsync.when(
            loading: () => const LoadingView(message: 'Loading requests'),
            error: (error, _) => ErrorStateView(message: error.toString(), onRetry: () => ref.invalidate(adminRequestsProvider(_query))),
            data: (page) => RefreshIndicator(
              onRefresh: () async => ref.invalidate(adminRequestsProvider(_query)),
              child: page.items.isEmpty
                  ? const EmptyStateView(icon: Icons.folder_copy_outlined, title: 'No requests', message: 'No requests match the selected filters.')
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: page.items.length + 1,
                      itemBuilder: (context, index) {
                        if (index == page.items.length) {
                          return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text('Page ${page.page} of ${page.totalPages}'),
                            Row(children: [
                              IconButton(onPressed: page.page <= 1 ? null : () => setState(() => _page--), icon: const Icon(Icons.chevron_left)),
                              IconButton(onPressed: page.page >= page.totalPages ? null : () => setState(() => _page++), icon: const Icon(Icons.chevron_right)),
                            ]),
                          ]);
                        }
                        final request = page.items[index];
                        return _AdminRequestCard(request: request, onStatus: () => _changeStatus(request));
                      },
                    ),
            ),
          ),
        ),
      ]),
    );
  }

  Future<void> _changeStatus(LegalRequest request) async {
    final selected = ValueNotifier<String>(request.status);
    final reason = TextEditingController();
    final status = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update ${request.reference}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          ValueListenableBuilder<String>(
            valueListenable: selected,
            builder: (context, value, _) => DropdownButtonFormField<String>(
              value: value,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: 'documents_requested', child: Text('Documents requested')),
                DropdownMenuItem(value: 'documents_received', child: Text('Documents received')),
                DropdownMenuItem(value: 'processing', child: Text('Processing')),
                DropdownMenuItem(value: 'completed', child: Text('Completed')),
                DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
              ],
              onChanged: (next) => selected.value = next ?? value,
            ),
          ),
          const SizedBox(height: 12),
          TextField(controller: reason, decoration: const InputDecoration(labelText: 'Reason for rejection/cancellation')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, selected.value), child: const Text('Update')),
        ],
      ),
    );
    if (status == null || status == request.status) {
      selected.dispose();
      reason.dispose();
      return;
    }
    if (!mounted) {
      selected.dispose();
      reason.dispose();
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(legalGoRepositoryProvider).updateRequestStatus(request.id, status, reason: reason.text);
      ref.invalidate(adminRequestsProvider(_query));
      ref.invalidate(requestDetailsProvider(request.id));
      messenger.showSnackBar(const SnackBar(content: Text('Request status updated')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('Status update failed: $error')));
    } finally {
      selected.dispose();
      reason.dispose();
    }
  }
}

class _AdminRequestCard extends StatelessWidget {
  const _AdminRequestCard({required this.request, required this.onStatus});

  final LegalRequest request;
  final VoidCallback onStatus;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(request.reference, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
            IconButton(onPressed: () => context.go('/admin/requests/${request.id}'), icon: const Icon(Icons.open_in_new_rounded)),
          ]),
          Text(request.service?.title ?? 'Service unavailable'),
          Text(request.user?.email ?? request.customerEmail ?? 'No customer'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [StatusChip(value: request.status), StatusChip(value: request.paymentStatus)]),
          Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: onStatus, icon: const Icon(Icons.edit_outlined), label: const Text('Change status'))),
        ]),
      ),
    );
  }
}


