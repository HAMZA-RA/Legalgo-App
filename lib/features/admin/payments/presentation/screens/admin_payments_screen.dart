import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalgo_mobile/core/widgets/state_views.dart';
import 'package:legalgo_mobile/features/shared/presentation/providers/legalgo_providers.dart';
import 'package:legalgo_mobile/features/shared/presentation/widgets/portal_widgets.dart';

class AdminPaymentsScreen extends ConsumerStatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  ConsumerState<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends ConsumerState<AdminPaymentsScreen> {
  final _search = TextEditingController();
  String? _status;
  int _page = 1;
  AdminPaymentsQuery get _query => AdminPaymentsQuery(search: _search.text, status: _status, page: _page);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(adminPaymentsProvider(_query));
    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(child: TextField(controller: _search, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Search payments'), onSubmitted: (_) => setState(() => _page = 1))),
            const SizedBox(width: 10),
            SizedBox(width: 150, child: DropdownButtonFormField<String?>(value: _status, decoration: const InputDecoration(labelText: 'Status'), items: const [DropdownMenuItem(value: null, child: Text('All')), DropdownMenuItem(value: 'pending', child: Text('Pending')), DropdownMenuItem(value: 'paid', child: Text('Paid')), DropdownMenuItem(value: 'failed', child: Text('Failed'))], onChanged: (value) => setState(() { _status = value; _page = 1; }))),
          ]),
        ),
        Expanded(
          child: paymentsAsync.when(
            loading: () => const LoadingView(message: 'Loading payments'),
            error: (error, _) => ErrorStateView(message: error.toString(), onRetry: () => ref.invalidate(adminPaymentsProvider(_query))),
            data: (page) => RefreshIndicator(
              onRefresh: () async => ref.invalidate(adminPaymentsProvider(_query)),
              child: page.items.isEmpty
                  ? const EmptyStateView(icon: Icons.payments_outlined, title: 'No payments', message: 'No payments match the selected filters.')
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
                        final payment = page.items[index];
                        return Card(child: ListTile(leading: const Icon(Icons.credit_card_rounded), title: Text(money(payment.amount)), subtitle: Text('${payment.request?.reference ?? 'No reference'} • ${payment.stripeSessionId ?? 'No Stripe session'}'), trailing: StatusChip(value: payment.status)));
                      },
                    ),
            ),
          ),
        ),
      ]),
    );
  }
}
