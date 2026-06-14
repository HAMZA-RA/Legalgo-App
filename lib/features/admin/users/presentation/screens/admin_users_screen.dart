import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalgo_mobile/core/widgets/state_views.dart';
import 'package:legalgo_mobile/features/shared/presentation/providers/legalgo_providers.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _search = TextEditingController();
  String? _status;
  String? _profileType;
  int _page = 1;

  AdminUsersQuery get _query => AdminUsersQuery(search: _search.text, status: _status, profileType: _profileType, page: _page);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider(_query));
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              TextField(controller: _search, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Search users'), onSubmitted: (_) => setState(() => _page = 1)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: DropdownButtonFormField<String?>(value: _status, decoration: const InputDecoration(labelText: 'Status'), items: const [DropdownMenuItem(value: null, child: Text('All')), DropdownMenuItem(value: 'active', child: Text('Active')), DropdownMenuItem(value: 'inactive', child: Text('Inactive'))], onChanged: (value) => setState(() { _status = value; _page = 1; }))),
                const SizedBox(width: 10),
                Expanded(child: DropdownButtonFormField<String?>(value: _profileType, decoration: const InputDecoration(labelText: 'Profile'), items: const [DropdownMenuItem(value: null, child: Text('All')), DropdownMenuItem(value: 'individual', child: Text('Individual')), DropdownMenuItem(value: 'company', child: Text('Company'))], onChanged: (value) => setState(() { _profileType = value; _page = 1; }))),
              ]),
            ]),
          ),
          Expanded(
            child: usersAsync.when(
              loading: () => const LoadingView(message: 'Loading users'),
              error: (error, _) => ErrorStateView(message: error.toString(), onRetry: () => ref.invalidate(adminUsersProvider(_query))),
              data: (page) => RefreshIndicator(
                onRefresh: () async => ref.invalidate(adminUsersProvider(_query)),
                child: page.items.isEmpty
                    ? const EmptyStateView(icon: Icons.people_outline, title: 'No users', message: 'No users match the selected filters.')
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: page.items.length + 1,
                        itemBuilder: (context, index) {
                          if (index == page.items.length) {
                            return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Text('Page ${page.page} of ${page.totalPages}'),
                              Row(children: [
                                IconButton(onPressed: page.page <= 1 ? null : () => setState(() => _page--), icon: const Icon(Icons.chevron_left)),
                                IconButton(onPressed: page.page >= page.totalPages ? null : () => setState(() => _page++), icon: const Icon(Icons.chevron_right)),
                              ]),
                            ]);
                          }
                          final user = page.items[index];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.person_outline),
                              title: Text(user.displayName),
                              subtitle: Text('${user.email} • ${user.requestsCount ?? 0} request(s)'),
                              trailing: Text(user.status ? 'Active' : 'Inactive'),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
