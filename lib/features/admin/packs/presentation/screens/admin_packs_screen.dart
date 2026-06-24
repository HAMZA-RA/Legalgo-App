import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalgo_mobile/core/design_system/design_system.dart';
import 'package:legalgo_mobile/core/widgets/state_views.dart';
import 'package:legalgo_mobile/features/shared/domain/legalgo_models.dart';
import 'package:legalgo_mobile/features/shared/presentation/providers/legalgo_providers.dart';
import 'package:legalgo_mobile/features/shared/presentation/widgets/portal_widgets.dart';

class AdminPacksScreen extends ConsumerWidget {
  const AdminPacksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(adminLegalServicesProvider);
    return Scaffold(
      backgroundColor: AppColors.pageBackground(context),
      appBar: const PremiumAppBar(title: 'Packs'),
      body: servicesAsync.when(
        loading: () => const LoadingView(message: 'Chargement des packs'),
        error: (error, _) => ErrorStateView(
          message: error.toString(),
          onRetry: () => ref.invalidate(adminLegalServicesProvider),
        ),
        data: (services) {
          final packedServices = services
              .where((service) => service.packs.isNotEmpty)
              .toList();
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminLegalServicesProvider),
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
                        if (packedServices.isEmpty)
                          const AppCard(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl,
                              vertical: AppSpacing.xxxl,
                            ),
                            child: EmptyStateView(
                              icon: Icons.inventory_2_outlined,
                              title: 'Aucun pack',
                              message:
                                  'Aucun pack n’a été retourné par les services juridiques.',
                            ),
                          )
                        else
                          for (final service in packedServices) ...[
                            _ServicePacksCard(service: service),
                            const SizedBox(height: AppSpacing.sm),
                          ],
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

class _ServicePacksCard extends StatelessWidget {
  const _ServicePacksCard({required this.service});

  final LegalServiceSummary service;

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
              Icons.inventory_2_outlined,
              color: AppColors.softIndigo,
            ),
          ),
          title: Text(
            service.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          subtitle: Text(
            '${service.category?.title ?? 'Sans catégorie'} - ${service.packs.length} pack(s)',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          children: [for (final pack in service.packs) _PackRow(pack: pack)],
        ),
      ),
    );
  }
}

class _PackRow extends StatelessWidget {
  const _PackRow({required this.pack});

  final PackSummary pack;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pack.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  pack.description ?? 'Aucune description',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${pack.delayDays} jour(s)',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                money(pack.price),
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.xs),
              StatusBadge(
                value: pack.active ? 'active' : 'inactive',
                compact: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
