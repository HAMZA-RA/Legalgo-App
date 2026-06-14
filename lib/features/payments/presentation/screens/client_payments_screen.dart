import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalgo_mobile/core/widgets/state_views.dart';
import 'package:legalgo_mobile/features/shared/presentation/providers/legalgo_providers.dart';
import 'package:legalgo_mobile/features/shared/presentation/widgets/portal_widgets.dart';

class ClientPaymentsScreen extends ConsumerWidget {
  const ClientPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(clientPaymentsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: paymentsAsync.when(
        loading: () => const LoadingView(message: 'Loading payments'),
        error: (error, _) => ErrorStateView(message: error.toString(), onRetry: () => ref.invalidate(clientPaymentsProvider)),
        data: (payments) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(clientPaymentsProvider),
          child: payments.isEmpty
              ? const EmptyStateView(icon: Icons.payments_outlined, title: 'No payments', message: 'LegalGo payments linked to your account will appear here.')
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: payments.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.credit_card_rounded),
                        title: Text(money(payment.amount)),
                        subtitle: Text('${payment.request?.reference ?? 'No reference'} • ${compactDate(payment.paymentDate)}'),
                        trailing: StatusChip(value: payment.status),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

