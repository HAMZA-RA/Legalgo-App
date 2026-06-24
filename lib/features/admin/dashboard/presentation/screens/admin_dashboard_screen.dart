import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalgo_mobile/core/design_system/design_system.dart';
import 'package:legalgo_mobile/core/widgets/state_views.dart';
import 'package:legalgo_mobile/features/shared/presentation/providers/legalgo_providers.dart';
import 'package:legalgo_mobile/features/shared/presentation/widgets/portal_widgets.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  String _period = '30d';

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(adminDashboardProvider(_period));
    return Scaffold(
      backgroundColor: AppColors.pageBackground(context),
      appBar: const PremiumAppBar(title: 'Tableau de bord'),
      body: dashboardAsync.when(
        loading: () =>
            const LoadingView(message: 'Chargement des statistiques'),
        error: (error, _) => ErrorStateView(
          message: error.toString(),
          onRetry: () => ref.invalidate(adminDashboardProvider(_period)),
        ),
        data: (stats) => RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(adminDashboardProvider(_period)),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AdminHero(
                        period: _period,
                        onPeriodChanged: (value) =>
                            setState(() => _period = value),
                        users: stats.summary.users,
                        requests: stats.summary.requests,
                        revenue: money(stats.summary.paidRevenue),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _KpiGrid(
                        items: [
                          _KpiData(
                            'Utilisateurs',
                            '${stats.summary.users}',
                            Icons.people_outline,
                            AppColors.softIndigo,
                            'Comptes',
                          ),
                          _KpiData(
                            'Demandes',
                            '${stats.summary.requests}',
                            Icons.folder_copy_outlined,
                            AppColors.teal,
                            'Dossiers juridiques',
                          ),
                          _KpiData(
                            'Revenus',
                            money(stats.summary.paidRevenue),
                            Icons.euro_rounded,
                            AppColors.success,
                            'Revenus encaissés',
                          ),
                          _KpiData(
                            'Abonnements',
                            '${stats.summary.subscriptions}',
                            Icons.event_repeat_outlined,
                            AppColors.violet,
                            'Domiciliation',
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      const SectionHeader(
                        title: 'Alertes',
                        subtitle: 'Signaux de paiement et de traitement',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _KpiGrid(
                        items: [
                          _KpiData(
                            'Paiements en attente',
                            '${stats.alerts.pendingPayments}',
                            Icons.pending_actions_outlined,
                            AppColors.warning,
                            'En attente de règlement',
                          ),
                          _KpiData(
                            'Paiements échoués',
                            '${stats.alerts.failedPayments}',
                            Icons.error_outline,
                            AppColors.danger,
                            'À vérifier',
                          ),
                          _KpiData(
                            'Demandes non traitées',
                            '${stats.alerts.untreatedRequests}',
                            Icons.hourglass_empty_rounded,
                            AppColors.softIndigo,
                            'File opérationnelle',
                          ),
                          _KpiData(
                            'Expiration proche',
                            '${stats.alerts.expiringSubscriptions}',
                            Icons.warning_amber_rounded,
                            AppColors.warning,
                            'Abonnements',
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      _ResponsiveColumns(
                        left: _SubscriptionMetrics(
                          stats: stats.domiciliationStats,
                        ),
                        right: _ServicesDistribution(
                          services: stats.servicesDistribution.take(6).toList(),
                        ),
                      ),
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

class _AdminHero extends StatelessWidget {
  const _AdminHero({
    required this.period,
    required this.onPeriodChanged,
    required this.users,
    required this.requests,
    required this.revenue,
  });

  final String period;
  final ValueChanged<String> onPeriodChanged;
  final int users;
  final int requests;
  final String revenue;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      gradient: AppColors.heroGradient(context),
      padding: const EdgeInsets.all(AppSpacing.xl),
      shadows: AppShadows.elevated(context),
      child: Stack(
        children: [
          Positioned(
            right: -42,
            top: -48,
            child: _GlowCircle(
              color: AppColors.violet.withValues(alpha: .16),
              size: 150,
            ),
          ),
          Positioned(
            right: 44,
            bottom: -62,
            child: _GlowCircle(
              color: AppColors.teal.withValues(alpha: .14),
              size: 150,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .72),
                      borderRadius: AppRadius.icon,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .72),
                      ),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_outlined,
                      color: AppColors.softIndigo,
                    ),
                  ),
                  const Spacer(),
                  _PeriodMenu(value: period, onChanged: onPeriodChanged),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .68),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .76),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _HeroMetric(
                        label: 'Utilisateurs',
                        value: '$users',
                      ),
                    ),
                    const _HeroDivider(),
                    Expanded(
                      child: _HeroMetric(label: 'Demandes', value: '$requests'),
                    ),
                    const _HeroDivider(),
                    Expanded(
                      child: _HeroMetric(label: 'Revenus', value: revenue),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PeriodMenu extends StatelessWidget {
  const _PeriodMenu({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .72),
        borderRadius: AppRadius.chip,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          borderRadius: AppRadius.card,
          items: const [
            DropdownMenuItem(value: '7d', child: Text('7d')),
            DropdownMenuItem(value: '30d', child: Text('30d')),
            DropdownMenuItem(value: '3m', child: Text('3m')),
            DropdownMenuItem(value: '12m', child: Text('12m')),
          ],
          onChanged: (next) => onChanged(next ?? '30d'),
        ),
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: AppColors.navy,
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
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 36,
    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    color: AppColors.subtleBorder(context),
  );
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
            : constraints.maxWidth >= 420
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
            childAspectRatio: columns == 1 ? 2.8 : 1.05,
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

class _ResponsiveColumns extends StatelessWidget {
  const _ResponsiveColumns({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 820) {
          return Column(
            children: [
              left,
              const SizedBox(height: AppSpacing.md),
              right,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class _SubscriptionMetrics extends StatelessWidget {
  const _SubscriptionMetrics({required this.stats});

  final dynamic stats;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Indicateurs d’abonnement',
            subtitle: 'État des domiciliations',
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(
            label: 'Actifs',
            value: '${stats.active}',
            color: AppColors.success,
          ),
          _InfoRow(
            label: 'Expirés',
            value: '${stats.expired}',
            color: AppColors.danger,
          ),
          _InfoRow(
            label: 'À renouveler bientôt',
            value: '${stats.renewingSoon}',
            color: AppColors.warning,
          ),
          _InfoRow(
            label: 'Montant généré',
            value: money(stats.generatedAmount.toString()),
            color: AppColors.softIndigo,
          ),
        ],
      ),
    );
  }
}

class _ServicesDistribution extends StatelessWidget {
  const _ServicesDistribution({required this.services});

  final List<dynamic> services;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Répartition des services',
            subtitle: 'Principales catégories de demandes',
          ),
          const SizedBox(height: AppSpacing.md),
          if (services.isEmpty)
            Text(
              'Aucune donnée de répartition disponible.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            )
          else
            for (final service in services) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      service.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '${service.count}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              LinearProgressIndicator(
                value: (service.percentage / 100).clamp(0, 1).toDouble(),
                color: AppColors.softIndigo,
                backgroundColor: AppColors.softIndigo.withValues(alpha: .10),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.subtleSurface(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
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
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
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

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

class _KpiData {
  const _KpiData(this.title, this.value, this.icon, this.color, this.caption);

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String caption;
}
