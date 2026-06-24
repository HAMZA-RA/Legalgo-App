import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalgo_mobile/core/design_system/design_system.dart';
import 'package:legalgo_mobile/core/widgets/state_views.dart';
import 'package:legalgo_mobile/features/shared/domain/legalgo_models.dart';
import 'package:legalgo_mobile/features/shared/presentation/providers/legalgo_providers.dart';
import 'package:legalgo_mobile/features/shared/presentation/widgets/portal_widgets.dart';

class AdminPaymentsScreen extends ConsumerStatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  ConsumerState<AdminPaymentsScreen> createState() =>
      _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends ConsumerState<AdminPaymentsScreen> {
  int _page = 1;

  AdminPaymentsQuery get _query => AdminPaymentsQuery(page: _page);

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(adminPaymentsProvider(_query));
    return Scaffold(
      backgroundColor: AppColors.pageBackground(context),
      appBar: const PremiumAppBar(title: 'Paiements'),
      body: paymentsAsync.when(
        loading: () => const LoadingView(message: 'Chargement des paiements'),
        error: (error, _) => ErrorStateView(
          message: error.toString(),
          onRetry: () => ref.invalidate(adminPaymentsProvider(_query)),
        ),
        data: (page) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminPaymentsProvider(_query)),
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
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Column(
                    children: [
                      if (page.items.isEmpty)
                        const AppCard(
                          child: EmptyStateView(
                            icon: Icons.payments_outlined,
                            title: 'Aucun paiement',
                            message: 'Aucun paiement disponible.',
                          ),
                        )
                      else ...[
                        for (final payment in page.items) ...[
                          _PaymentCard(payment: payment),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        _Pagination(
                          page: page.page,
                          totalPages: page.totalPages,
                          onPrevious: page.page <= 1
                              ? null
                              : () => setState(() => _page--),
                          onNext: page.page >= page.totalPages
                              ? null
                              : () => setState(() => _page++),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
                  payment.request?.reference ?? 'Aucune référence',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  payment.stripeSessionId ?? 'Aucune session Stripe',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.page,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) => AppCard(
    shadows: AppShadows.none,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Page $page sur $totalPages',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        Row(
          children: [
            IconButton(
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    ),
  );
}
