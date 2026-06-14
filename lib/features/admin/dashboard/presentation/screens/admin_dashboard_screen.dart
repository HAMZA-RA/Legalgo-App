import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalgo_mobile/core/widgets/state_views.dart';
import 'package:legalgo_mobile/features/shared/presentation/providers/legalgo_providers.dart';
import 'package:legalgo_mobile/features/shared/presentation/widgets/portal_widgets.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  String _period = '30d';

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(adminDashboardProvider(_period));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _period,
              items: const [
                DropdownMenuItem(value: '7d', child: Text('7d')),
                DropdownMenuItem(value: '30d', child: Text('30d')),
                DropdownMenuItem(value: '3m', child: Text('3m')),
                DropdownMenuItem(value: '12m', child: Text('12m')),
              ],
              onChanged: (value) => setState(() => _period = value ?? '30d'),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: dashboardAsync.when(
        loading: () => const LoadingView(message: 'Loading admin stats'),
        error: (error, _) => ErrorStateView(message: error.toString(), onRetry: () => ref.invalidate(adminDashboardProvider(_period))),
        data: (stats) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminDashboardProvider(_period)),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ResponsiveGrid(children: [
                MetricTile(title: 'Users', value: '${stats.summary.users}', icon: Icons.people_outline),
                MetricTile(title: 'Requests', value: '${stats.summary.requests}', icon: Icons.folder_copy_outlined),
                MetricTile(title: 'Revenue', value: money(stats.summary.paidRevenue), icon: Icons.euro_rounded),
                MetricTile(title: 'Subscriptions', value: '${stats.summary.subscriptions}', icon: Icons.event_repeat_outlined),
              ]),
              const SizedBox(height: 18),
              Text('Payment and request alerts', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              ResponsiveGrid(children: [
                MetricTile(title: 'Pending payments', value: '${stats.alerts.pendingPayments}', icon: Icons.pending_actions_outlined),
                MetricTile(title: 'Failed payments', value: '${stats.alerts.failedPayments}', icon: Icons.error_outline),
                MetricTile(title: 'Untreated requests', value: '${stats.alerts.untreatedRequests}', icon: Icons.hourglass_empty_rounded),
                MetricTile(title: 'Expiring subscriptions', value: '${stats.alerts.expiringSubscriptions}', icon: Icons.warning_amber_rounded),
              ]),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Subscription metrics', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    Text('Active: ${stats.domiciliationStats.active}'),
                    Text('Expired: ${stats.domiciliationStats.expired}'),
                    Text('Renewing soon: ${stats.domiciliationStats.renewingSoon}'),
                    Text('Generated amount: ${money(stats.domiciliationStats.generatedAmount.toString())}'),
                  ]),
                ),
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Services distribution', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    for (final service in stats.servicesDistribution.take(6))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(service.label),
                        subtitle: LinearProgressIndicator(value: (service.percentage / 100).clamp(0, 1).toDouble()),
                        trailing: Text('${service.count}'),
                      ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
