import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalgo_mobile/core/widgets/state_views.dart';
import 'package:legalgo_mobile/features/shared/presentation/providers/legalgo_providers.dart';
import 'package:legalgo_mobile/features/shared/presentation/widgets/portal_widgets.dart';

class AdminSubscriptionsScreen extends ConsumerStatefulWidget {
  const AdminSubscriptionsScreen({super.key});

  @override
  ConsumerState<AdminSubscriptionsScreen> createState() => _AdminSubscriptionsScreenState();
}

class _AdminSubscriptionsScreenState extends ConsumerState<AdminSubscriptionsScreen> {
  String? _plan;
  String? _status;

  AdminSubscriptionsQuery get _query => AdminSubscriptionsQuery(plan: _plan, status: _status);

  @override
  Widget build(BuildContext context) {
    final subscriptionsAsync = ref.watch(adminSubscriptionsProvider(_query));
    return Scaffold(
      appBar: AppBar(title: const Text('Subscriptions')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _plan ?? 'all',
                    decoration: const InputDecoration(labelText: 'Plan'),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All')),
                      DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                      DropdownMenuItem(value: 'annual', child: Text('Annual')),
                      DropdownMenuItem(value: 'biannual', child: Text('Biannual')),
                    ],
                    onChanged: (value) => setState(() => _plan = value == 'all' ? null : value),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _status ?? 'all',
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All')),
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(value: 'past_due', child: Text('Past due')),
                      DropdownMenuItem(value: 'expired', child: Text('Expired')),
                      DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                    ],
                    onChanged: (value) => setState(() => _status = value == 'all' ? null : value),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: subscriptionsAsync.when(
              loading: () => const LoadingView(message: 'Loading subscriptions'),
              error: (error, _) => ErrorStateView(
                message: error.toString(),
                onRetry: () => ref.invalidate(adminSubscriptionsProvider(_query)),
              ),
              data: (subscriptions) => RefreshIndicator(
                onRefresh: () async => ref.invalidate(adminSubscriptionsProvider(_query)),
                child: subscriptions.isEmpty
                    ? const EmptyStateView(
                        icon: Icons.event_repeat_outlined,
                        title: 'No subscriptions',
                        message: 'No subscriptions match the selected filters.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: subscriptions.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final subscription = subscriptions[index];
                          return Card(
                            child: ExpansionTile(
                              leading: const Icon(Icons.event_repeat_outlined),
                              title: Text(subscription.user?.email ?? subscription.formula),
                              subtitle: Text('${subscription.plan?.title ?? subscription.formula} • ${money(subscription.displayAmount)}'),
                              trailing: StatusChip(value: subscription.status),
                              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              children: [
                                Align(alignment: Alignment.centerLeft, child: Text('Request: ${subscription.request?.reference ?? '-'}')),
                                Align(alignment: Alignment.centerLeft, child: Text('Renewal: ${subscription.renewalDate}')),
                                Align(alignment: Alignment.centerLeft, child: Text('Expiration: ${subscription.expiration}')),
                                const SizedBox(height: 8),
                                for (final payment in subscription.payments)
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(money(payment.amount)),
                                    subtitle: Text(compactDate(payment.paidAt)),
                                    trailing: StatusChip(value: payment.status),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

