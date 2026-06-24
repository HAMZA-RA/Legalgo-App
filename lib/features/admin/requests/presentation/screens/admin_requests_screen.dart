import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:legalgo_mobile/core/design_system/design_system.dart';
import 'package:legalgo_mobile/core/widgets/state_views.dart';
import 'package:legalgo_mobile/features/shared/domain/legalgo_models.dart';
import 'package:legalgo_mobile/features/shared/presentation/providers/legalgo_providers.dart';

class AdminRequestsScreen extends ConsumerStatefulWidget {
  const AdminRequestsScreen({super.key});

  @override
  ConsumerState<AdminRequestsScreen> createState() =>
      _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends ConsumerState<AdminRequestsScreen> {
  int _page = 1;

  AdminRequestsQuery get _query => AdminRequestsQuery(page: _page);

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(adminRequestsProvider(_query));
    return Scaffold(
      backgroundColor: AppColors.pageBackground(context),
      appBar: const PremiumAppBar(title: 'Demandes'),
      body: requestsAsync.when(
        loading: () => const LoadingView(message: 'Chargement des demandes'),
        error: (error, _) => ErrorStateView(
          message: error.toString(),
          onRetry: () => ref.invalidate(adminRequestsProvider(_query)),
        ),
        data: (page) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminRequestsProvider(_query)),
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
                            icon: Icons.folder_copy_outlined,
                            title: 'Aucune demande',
                            message: 'Aucune demande disponible.',
                          ),
                        )
                      else ...[
                        for (final request in page.items) ...[
                          _AdminRequestCard(request: request),
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

class _AdminRequestCard extends StatelessWidget {
  const _AdminRequestCard({required this.request});

  final LegalRequest request;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.softIndigo.withValues(alpha: .10),
                  borderRadius: AppRadius.icon,
                ),
                child: const Icon(
                  Icons.folder_copy_outlined,
                  color: AppColors.softIndigo,
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
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      request.user?.email ??
                          request.customerEmail ??
                          'Aucun client',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => context.go('/admin/requests/${request.id}'),
                icon: const Icon(Icons.open_in_new_rounded),
                color: AppColors.softIndigo,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              StatusBadge(value: request.status),
              StatusBadge(value: request.paymentStatus),
            ],
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
