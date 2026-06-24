import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalgo_mobile/core/design_system/design_system.dart';
import 'package:legalgo_mobile/core/widgets/state_views.dart';
import 'package:legalgo_mobile/features/shared/data/legalgo_repository.dart';
import 'package:legalgo_mobile/features/shared/domain/legalgo_models.dart';
import 'package:legalgo_mobile/features/shared/presentation/providers/legalgo_providers.dart';
import 'package:legalgo_mobile/features/shared/presentation/widgets/portal_widgets.dart';

class AdminSubscriptionsScreen extends ConsumerStatefulWidget {
  const AdminSubscriptionsScreen({super.key});

  @override
  ConsumerState<AdminSubscriptionsScreen> createState() =>
      _AdminSubscriptionsScreenState();
}

class _AdminSubscriptionsScreenState
    extends ConsumerState<AdminSubscriptionsScreen> {
  String? _reminderLoadingId;

  AdminSubscriptionsQuery get _query => AdminSubscriptionsQuery();

  @override
  Widget build(BuildContext context) {
    final subscriptionsAsync = ref.watch(adminSubscriptionsProvider(_query));
    return Scaffold(
      backgroundColor: AppColors.pageBackground(context),
      appBar: const PremiumAppBar(title: 'Abonnements'),
      body: subscriptionsAsync.when(
        loading: () => const LoadingView(message: 'Chargement des abonnements'),
        error: (error, _) => ErrorStateView(
          message: error.toString(),
          onRetry: () => ref.invalidate(adminSubscriptionsProvider(_query)),
        ),
        data: (subscriptions) => RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(adminSubscriptionsProvider(_query)),
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
                      if (subscriptions.isEmpty)
                        const AppCard(
                          child: EmptyStateView(
                            icon: Icons.event_repeat_outlined,
                            title: 'Aucun abonnement',
                            message: 'Aucun abonnement disponible.',
                          ),
                        )
                      else
                        for (final subscription in subscriptions) ...[
                          _SubscriptionCard(
                            subscription: subscription,
                            reminderLoading:
                                _reminderLoadingId == subscription.id,
                            onSendReminder: _canSendReminder(subscription)
                                ? () => _sendReminder(subscription)
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.sm),
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

  bool _canSendReminder(DomiciliationSubscription subscription) {
    return const {
      'overdue',
      'past_due',
      'expired',
    }.contains(subscription.status);
  }

  Future<void> _sendReminder(DomiciliationSubscription subscription) async {
    final email = subscription.user?.email ?? 'ce client';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Envoyer un rappel ?'),
        content: Text('Un rappel d’échéance sera envoyé à $email.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _reminderLoadingId = subscription.id);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(legalGoRepositoryProvider)
          .sendSubscriptionReminder(subscription.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Rappel envoyé au client.')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Impossible d’envoyer le rappel. ${backendResponseBody(error)}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _reminderLoadingId = null);
    }
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.subscription,
    required this.reminderLoading,
    required this.onSendReminder,
  });

  final DomiciliationSubscription subscription;
  final bool reminderLoading;
  final VoidCallback? onSendReminder;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(top: AppSpacing.sm),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.softIndigo.withValues(alpha: .10),
              borderRadius: AppRadius.icon,
            ),
            child: const Icon(
              Icons.event_repeat_outlined,
              color: AppColors.softIndigo,
            ),
          ),
          title: Text(
            subscription.user?.email ?? subscription.formula,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          subtitle: Text(
            '${subscription.plan?.title ?? subscription.formula} - ${money(subscription.displayAmount)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: StatusBadge(value: subscription.status, compact: true),
          children: [
            _InfoRow(
              label: 'Demande',
              value: subscription.request?.reference ?? '-',
            ),
            _InfoRow(label: 'Renouvellement', value: subscription.renewalDate),
            _InfoRow(label: 'Expiration', value: subscription.expiration),
            if (subscription.payments.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Paiements',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              for (final payment in subscription.payments)
                _PaymentRow(
                  amount: payment.amount,
                  paidAt: payment.paidAt,
                  status: payment.status,
                ),
            ],
            if (onSendReminder != null) ...[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: reminderLoading ? null : onSendReminder,
                  icon: reminderLoading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.mark_email_unread_outlined),
                  label: const Text('Envoyer un rappel'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.amount,
    required this.paidAt,
    required this.status,
  });

  final String amount;
  final DateTime? paidAt;
  final String status;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: AppSpacing.xs),
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      color: AppColors.subtleSurface(context),
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            '${money(amount)} - ${compactDate(paidAt)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        StatusBadge(value: status, compact: true),
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: AppSpacing.xs),
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      color: AppColors.subtleSurface(context),
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    child: Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
