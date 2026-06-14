import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalgo_mobile/core/widgets/state_views.dart';
import 'package:legalgo_mobile/features/shared/presentation/providers/legalgo_providers.dart';
import 'package:legalgo_mobile/features/shared/presentation/widgets/portal_widgets.dart';

class AdminPacksScreen extends ConsumerWidget {
  const AdminPacksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(adminLegalServicesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Packs')),
      body: servicesAsync.when(
        loading: () => const LoadingView(message: 'Loading packs'),
        error: (error, _) => ErrorStateView(
          message: error.toString(),
          onRetry: () => ref.invalidate(adminLegalServicesProvider),
        ),
        data: (services) {
          final packedServices = services.where((service) => service.packs.isNotEmpty).toList();
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminLegalServicesProvider),
            child: packedServices.isEmpty
                ? const EmptyStateView(
                    icon: Icons.inventory_2_outlined,
                    title: 'No packs',
                    message: 'No nested packs were returned by admin legal services.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: packedServices.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final service = packedServices[index];
                      return Card(
                        child: ExpansionTile(
                          leading: const Icon(Icons.inventory_2_outlined),
                          title: Text(service.title),
                          subtitle: Text(service.category?.title ?? 'No category'),
                          children: [
                            for (final pack in service.packs)
                              ListTile(
                                title: Text(pack.title),
                                subtitle: Text('${pack.description ?? 'No description'}\n${pack.delayDays} day(s)'),
                                isThreeLine: true,
                                trailing: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      money(pack.price),
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                                    ),
                                    Text(pack.active ? 'Active' : 'Inactive'),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}

