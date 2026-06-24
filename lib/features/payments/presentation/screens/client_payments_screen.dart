import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalgo_mobile/core/design_system/design_system.dart';
import 'package:legalgo_mobile/core/widgets/state_views.dart';
import 'package:legalgo_mobile/features/shared/domain/legalgo_models.dart';
import 'package:legalgo_mobile/features/shared/presentation/providers/legalgo_providers.dart';
import 'package:legalgo_mobile/features/shared/presentation/widgets/portal_widgets.dart';

class ClientPaymentsScreen extends ConsumerWidget {
  const ClientPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(clientPaymentsProvider);
    return Scaffold(
      backgroundColor: AppColors.pageBackground(context),
      appBar: const PremiumAppBar(title: 'Paiements'),
      body: paymentsAsync.when(
        loading: () => const LoadingView(message: 'Chargement des paiements'),
        error: (error, _) => ErrorStateView(
          message: error.toString(),
          onRetry: () => ref.invalidate(clientPaymentsProvider),
        ),
        data: (payments) {
          final paid = payments
              .where((payment) => payment.status == 'paid')
              .length;
          final pending = payments
              .where((payment) => payment.status == 'pending')
              .length;
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(clientPaymentsProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.xs,
                AppSpacing.screenHorizontal,
                AppSpacing.screenBottom,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 940),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _KpiGrid(
                          items: [
                            _KpiData(
                              'Paiements',
                              '${payments.length}',
                              Icons.receipt_long_outlined,
                              AppColors.softIndigo,
                              'Toutes les opérations',
                            ),
                            _KpiData(
                              'Payés',
                              '$paid',
                              Icons.check_circle_outline,
                              AppColors.success,
                              'Terminés',
                            ),
                            _KpiData(
                              'En attente',
                              '$pending',
                              Icons.timelapse_outlined,
                              AppColors.warning,
                              'Action requise',
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        const SectionHeader(
                          title: 'Activité',
                          subtitle: 'Paiements LegalGo liés à votre compte',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (payments.isEmpty)
                          const AppCard(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl,
                              vertical: AppSpacing.xxxl,
                            ),
                            child: EmptyStateView(
                              icon: Icons.payments_outlined,
                              title: 'Aucun paiement',
                              message:
                                  'Les paiements liés à votre compte apparaîtront ici.',
                            ),
                          )
                        else
                          _PaymentList(payments: payments),
                      ],
                    ),
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

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.items});

  final List<_KpiData> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760
            ? 3
            : constraints.maxWidth >= 340
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: columns == 1 ? 2.75 : 1.02,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return KpiCard(
              title: item.title,
              value: item.value,
              icon: item.icon,
              accent: item.color,
              subtitle: item.caption,
            );
          },
        );
      },
    );
  }
}

class _PaymentList extends StatelessWidget {
  const _PaymentList({required this.payments});

  final List<Payment> payments;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 820;
        if (!twoColumns) {
          return Column(
            children: [
              for (final payment in payments) ...[
                _PaymentCard(payment: payment),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          );
        }
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final payment in payments)
              SizedBox(
                width: (constraints.maxWidth - AppSpacing.md) / 2,
                child: _PaymentCard(payment: payment),
              ),
          ],
        );
      },
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.softIndigo.withValues(alpha: .10),
              borderRadius: AppRadius.icon,
            ),
            child: const Icon(
              Icons.credit_card_rounded,
              color: AppColors.softIndigo,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        money(payment.amount),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    StatusBadge(value: payment.status, compact: true),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${payment.request?.reference ?? 'Aucune référence'} - ${compactDate(payment.paymentDate)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiData {
  const _KpiData(this.title, this.value, this.icon, this.color, this.caption);

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String caption;
}
