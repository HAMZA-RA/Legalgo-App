import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:legalgo_mobile/core/design_system/design_system.dart';
import 'package:legalgo_mobile/core/widgets/state_views.dart';
import 'package:legalgo_mobile/features/shared/domain/legalgo_models.dart';
import 'package:legalgo_mobile/features/shared/presentation/providers/legalgo_providers.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key, required this.admin});

  final bool admin;

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String? _updatingId;
  bool _markingAll = false;

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider(widget.admin));

    return Scaffold(
      backgroundColor: AppColors.pageBackground(context),
      appBar: const PremiumAppBar(title: 'Notifications'),
      body: notificationsAsync.when(
        loading: () =>
            const LoadingView(message: 'Chargement des notifications'),
        error: (error, _) => ErrorStateView(
          message: error.toString(),
          onRetry: () => ref.invalidate(notificationsProvider(widget.admin)),
        ),
        data: (notifications) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(notificationsProvider(widget.admin));
            await ref.read(notificationsProvider(widget.admin).future);
          },
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
                      _NotificationsHeader(
                        unreadCount: notifications
                            .where((item) => !item.isRead)
                            .length,
                        markingAll: _markingAll,
                        onMarkAll: notifications.any((item) => !item.isRead)
                            ? _markAllRead
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (notifications.isEmpty)
                        const AppCard(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.xxxl,
                          ),
                          child: EmptyStateView(
                            icon: Icons.notifications_none_rounded,
                            title: 'Aucune notification',
                            message:
                                'Les actualités LegalGo apparaîtront ici lors d’une nouvelle activité.',
                          ),
                        )
                      else
                        for (final notification in notifications) ...[
                          _NotificationCard(
                            notification: notification,
                            loading: _updatingId == notification.id,
                            onTap: () => _openNotification(notification),
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

  Future<void> _openNotification(LegalGoNotification notification) async {
    if (!notification.isRead) {
      setState(() => _updatingId = notification.id);
      try {
        await ref
            .read(legalGoRepositoryProvider)
            .markNotificationRead(
              notificationId: notification.id,
              admin: widget.admin,
            );
        ref.invalidate(notificationsProvider(widget.admin));
      } finally {
        if (mounted) setState(() => _updatingId = null);
      }
    }

    if (!mounted || notification.requestId == null) return;
    context.go(
      widget.admin
          ? '/admin/requests/${notification.requestId}'
          : '/client/requests/${notification.requestId}',
    );
  }

  Future<void> _markAllRead() async {
    setState(() => _markingAll = true);
    try {
      await ref
          .read(legalGoRepositoryProvider)
          .markAllNotificationsRead(admin: widget.admin);
      ref.invalidate(notificationsProvider(widget.admin));
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }
}

class _NotificationsHeader extends StatelessWidget {
  const _NotificationsHeader({
    required this.unreadCount,
    required this.markingAll,
    required this.onMarkAll,
  });

  final int unreadCount;
  final bool markingAll;
  final VoidCallback? onMarkAll;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      gradient: AppColors.heroGradient(context),
      shadows: AppShadows.elevated(context),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.softIndigo.withValues(alpha: .12),
              borderRadius: AppRadius.icon,
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: AppColors.softIndigo,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$unreadCount non lue(s)',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Actualités des demandes, documents, paiements et abonnements.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            tooltip: 'Tout marquer comme lu',
            onPressed: markingAll ? null : onMarkAll,
            icon: markingAll
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.done_all_rounded),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.loading,
    required this.onTap,
  });

  final LegalGoNotification notification;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      onTap: loading ? null : onTap,
      color: notification.isRead
          ? AppColors.cardSurface(context)
          : scheme.primary.withValues(alpha: .06),
      borderColor: notification.isRead
          ? AppColors.subtleBorder(context)
          : scheme.primary.withValues(alpha: .22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _notificationColor(
                notification.type,
              ).withValues(alpha: .12),
              borderRadius: AppRadius.icon,
            ),
            child: Icon(
              _notificationIcon(notification.type),
              color: _notificationColor(notification.type),
              size: 21,
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
                        notification.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: notification.isRead
                              ? FontWeight.w800
                              : FontWeight.w900,
                        ),
                      ),
                    ),
                    if (!notification.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  notification.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _dateLabel(notification.createdAt),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (loading) ...[
            const SizedBox(width: AppSpacing.sm),
            const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ] else if (notification.requestId != null) ...[
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
          ],
        ],
      ),
    );
  }
}

IconData _notificationIcon(String type) {
  final value = type.toLowerCase();
  if (value.contains('payment')) return Icons.credit_card_rounded;
  if (value.contains('document')) return Icons.description_rounded;
  if (value.contains('subscription')) return Icons.event_repeat_rounded;
  return Icons.folder_copy_rounded;
}

Color _notificationColor(String type) {
  final value = type.toLowerCase();
  if (value.contains('payment')) return AppColors.teal;
  if (value.contains('document')) return AppColors.violet;
  if (value.contains('subscription')) return AppColors.warning;
  return AppColors.softIndigo;
}

String _dateLabel(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}-$month-$day $hour:$minute';
}
