import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:legalgo_mobile/core/design_system/design_system.dart';
import 'package:legalgo_mobile/core/widgets/state_views.dart';
import 'package:legalgo_mobile/features/shared/domain/legalgo_models.dart';
import 'package:legalgo_mobile/features/shared/presentation/providers/legalgo_providers.dart';
import 'package:legalgo_mobile/features/shared/presentation/widgets/portal_widgets.dart';

class ClientDashboardScreen extends ConsumerWidget {
  const ClientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(clientRequestsProvider);
    return Scaffold(
      backgroundColor: AppColors.pageBackground(context),
      appBar: const PremiumAppBar(title: 'Tableau de bord'),
      body: requestsAsync.when(
        loading: () =>
            const LoadingView(message: 'Chargement du tableau de bord'),
        error: (error, _) => ErrorStateView(
          message: error.toString(),
          onRetry: () => ref.invalidate(clientRequestsProvider),
        ),
        data: (requests) {
          final inProgress = requests
              .where(
                (item) => !{
                  'completed',
                  'rejected',
                  'cancelled',
                }.contains(item.status),
              )
              .length;
          final completed = requests
              .where((item) => item.status == 'completed')
              .length;
          final pending = requests
              .where(
                (item) =>
                    item.status == 'pending' || item.paymentStatus == 'pending',
              )
              .length;
          final recent = requests.take(5).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(clientRequestsProvider),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return ListView(
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DashboardHero(
                              total: requests.length,
                              inProgress: inProgress,
                              completed: completed,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _KpiGrid(
                              items: [
                                _KpiData(
                                  title: 'Demandes',
                                  value: '${requests.length}',
                                  icon: Icons.folder_copy_outlined,
                                  accent: AppColors.softIndigo,
                                ),
                                _KpiData(
                                  title: 'En cours',
                                  value: '$inProgress',
                                  icon: Icons.hourglass_top_rounded,
                                  accent: AppColors.violet,
                                ),
                                _KpiData(
                                  title: 'Terminées',
                                  value: '$completed',
                                  icon: Icons.check_circle_outline_rounded,
                                  accent: AppColors.success,
                                ),
                                _KpiData(
                                  title: 'À traiter',
                                  value: '$pending',
                                  icon: Icons.priority_high_rounded,
                                  accent: AppColors.warning,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            SectionHeader(
                              title: 'Demandes récentes',
                              subtitle:
                                  'Latest activity from your LegalGo workspace',
                              actionLabel: recent.isEmpty ? null : 'View all',
                              onAction: recent.isEmpty
                                  ? null
                                  : () => context.go('/client/requests'),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            if (recent.isEmpty)
                              const _EmptyRequestsCard()
                            else
                              _RecentRequestsList(requests: recent),
                            const SizedBox(height: AppSpacing.lg),
                            _RecentActivityCard(
                              total: requests.length,
                              inProgress: inProgress,
                              completed: completed,
                              pending: pending,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.total,
    required this.inProgress,
    required this.completed,
  });

  final int total;
  final int inProgress;
  final int completed;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AppCard(
      gradient: AppColors.heroGradient(context),
      borderColor: Colors.white.withValues(alpha: dark ? .08 : .65),
      shadows: AppShadows.elevated(context),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Stack(
        children: [
          Positioned(
            right: -36,
            top: -46,
            child: _GlowCircle(
              color: AppColors.violet.withValues(alpha: .18),
              size: 142,
            ),
          ),
          Positioned(
            right: 46,
            bottom: -58,
            child: _GlowCircle(
              color: AppColors.teal.withValues(alpha: .16),
              size: 156,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroMetrics(
                total: total,
                inProgress: inProgress,
                completed: completed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetrics extends StatelessWidget {
  const _HeroMetrics({
    required this.total,
    required this.inProgress,
    required this.completed,
  });

  final int total;
  final int inProgress;
  final int completed;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: dark ? .08 : .68),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: Colors.white.withValues(alpha: dark ? .08 : .76),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _HeroMetric(label: 'Total', value: '$total'),
          ),
          const _HeroDivider(),
          Expanded(
            child: _HeroMetric(label: 'Actives', value: '$inProgress'),
          ),
          const _HeroDivider(),
          Expanded(
            child: _HeroMetric(label: 'Terminées', value: '$completed'),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : AppColors.navy,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _HeroDivider extends StatelessWidget {
  const _HeroDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      color: AppColors.subtleBorder(context),
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
        final columns = constraints.maxWidth >= 860
            ? 4
            : constraints.maxWidth >= 520
            ? 2
            : 2;
        final spacing = constraints.maxWidth >= 520
            ? AppSpacing.md
            : AppSpacing.sm;
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: cardWidth,
                height: constraints.maxWidth >= 520 ? 158 : 138,
                child: KpiCard(
                  title: item.title,
                  value: item.value,
                  icon: item.icon,
                  accent: item.accent,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _KpiData {
  const _KpiData({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accent;
}

class _RecentRequestsList extends StatelessWidget {
  const _RecentRequestsList({required this.requests});

  final List<LegalRequest> requests;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 820;
        if (!twoColumns) {
          return Column(
            children: [
              for (final request in requests) ...[
                _RecentRequestCard(request: request),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          );
        }
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final request in requests)
              SizedBox(
                width: (constraints.maxWidth - AppSpacing.md) / 2,
                child: _RecentRequestCard(request: request),
              ),
          ],
        );
      },
    );
  }
}

class _RecentRequestCard extends StatelessWidget {
  const _RecentRequestCard({required this.request});

  final LegalRequest request;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.go('/client/requests/${request.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.softIndigo.withValues(alpha: .10),
                  borderRadius: AppRadius.icon,
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: AppColors.softIndigo,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.reference,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      request.service?.title ?? 'Service indisponible',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusBadge(value: request.status, compact: true),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  request.pack?.title ?? 'Aucun pack',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                money(request.totalPrice),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({
    required this.total,
    required this.inProgress,
    required this.completed,
    required this.pending,
  });

  final int total;
  final int inProgress;
  final int completed;
  final int pending;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Activité récente',
            subtitle: 'Vue synthétique de votre espace',
          ),
          const SizedBox(height: AppSpacing.sm),
          _ActivityRow(
            label: 'Dossiers actifs',
            value: '$inProgress',
            color: AppColors.softIndigo,
          ),
          _ActivityRow(
            label: 'Dossiers terminés',
            value: '$completed',
            color: AppColors.success,
          ),
          _ActivityRow(
            label: 'Éléments en attente',
            value: '$pending',
            color: AppColors.warning,
          ),
          _ActivityRow(
            label: 'Total des dossiers',
            value: '$total',
            color: AppColors.teal,
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _EmptyRequestsCard extends StatelessWidget {
  const _EmptyRequestsCard();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxxl,
      ),
      child: EmptyStateView(
        icon: Icons.folder_open_outlined,
        title: 'Aucune demande',
        message: 'Vos demandes LegalGo apparaîtront ici.',
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
