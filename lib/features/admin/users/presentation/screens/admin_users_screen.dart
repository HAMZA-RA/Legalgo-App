import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalgo_mobile/core/design_system/design_system.dart';
import 'package:legalgo_mobile/core/widgets/state_views.dart';
import 'package:legalgo_mobile/features/shared/domain/legalgo_models.dart';
import 'package:legalgo_mobile/features/shared/presentation/providers/legalgo_providers.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  int _page = 1;

  AdminUsersQuery get _query => AdminUsersQuery(page: _page);

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider(_query));
    return Scaffold(
      backgroundColor: AppColors.pageBackground(context),
      appBar: const PremiumAppBar(title: 'Utilisateurs'),
      body: usersAsync.when(
        loading: () =>
            const LoadingView(message: 'Chargement des utilisateurs'),
        error: (error, _) => ErrorStateView(
          message: error.toString(),
          onRetry: () => ref.invalidate(adminUsersProvider(_query)),
        ),
        data: (page) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminUsersProvider(_query)),
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
                            icon: Icons.people_outline,
                            title: 'Aucun utilisateur',
                            message: 'Aucun utilisateur disponible.',
                          ),
                        )
                      else ...[
                        for (final user in page.items) ...[
                          _UserCard(user: user),
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

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user});

  final LegalGoUser user;

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
              Icons.person_outline,
              color: AppColors.softIndigo,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${user.email} - ${user.requestsCount ?? 0} demande(s)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          StatusBadge(
            value: user.status ? 'active' : 'inactive',
            compact: true,
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
  Widget build(BuildContext context) {
    return AppCard(
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
}
