import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalgo_mobile/core/widgets/state_views.dart';
import 'package:legalgo_mobile/features/shared/data/legalgo_repository.dart';
import 'package:legalgo_mobile/features/shared/domain/legalgo_models.dart';
import 'package:legalgo_mobile/features/shared/presentation/providers/legalgo_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _firstname = TextEditingController();
  final _lastname = TextEditingController();
  final _companyName = TextEditingController();
  final _legalForm = TextEditingController();
  final _siren = TextEditingController();
  final _vatNumber = TextEditingController();
  final _address = TextEditingController();
  String _profileType = 'individual';
  bool _seeded = false;
  bool _saving = false;
  String? _success;
  String? _errorBody;

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
    _firstname.dispose();
    _lastname.dispose();
    _companyName.dispose();
    _legalForm.dispose();
    _siren.dispose();
    _vatNumber.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        loading: () => const LoadingView(message: 'Loading profile'),
        error: (error, _) => ErrorStateView(message: error.toString(), onRetry: () => ref.invalidate(profileProvider)),
        data: (user) {
          _seed(user);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (_success != null) ...[
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: ListTile(
                    leading: const Icon(Icons.check_circle_outline),
                    title: Text(_success!),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (_errorBody != null) ...[
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Backend response body', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        SelectableText(_errorBody!),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    CircleAvatar(radius: 28, child: Text(user.email.isEmpty ? 'L' : user.email.characters.first.toUpperCase())),
                    const SizedBox(height: 14),
                    Text(user.displayName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    Text(user.email),
                    const SizedBox(height: 8),
                    Text('Role: ${user.role}'),
                    Text('Status: ${user.status ? 'Active' : 'Inactive'}'),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 12),
              TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone')),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'individual', label: Text('Individual'), icon: Icon(Icons.person_outline)),
                  ButtonSegment(value: 'company', label: Text('Company'), icon: Icon(Icons.business_outlined)),
                ],
                selected: {_profileType},
                onSelectionChanged: (value) => setState(() => _profileType = value.first),
              ),
              const SizedBox(height: 16),
              if (_profileType == 'individual') ...[
                TextField(controller: _firstname, decoration: const InputDecoration(labelText: 'First name')),
                const SizedBox(height: 12),
                TextField(controller: _lastname, decoration: const InputDecoration(labelText: 'Last name')),
              ] else ...[
                TextField(controller: _companyName, decoration: const InputDecoration(labelText: 'Company name')),
                const SizedBox(height: 12),
                TextField(controller: _legalForm, decoration: const InputDecoration(labelText: 'Legal form')),
                const SizedBox(height: 12),
                TextField(controller: _siren, decoration: const InputDecoration(labelText: 'SIREN')),
                const SizedBox(height: 12),
                TextField(controller: _vatNumber, decoration: const InputDecoration(labelText: 'VAT number')),
                const SizedBox(height: 12),
                TextField(controller: _address, decoration: const InputDecoration(labelText: 'Address')),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
                label: const Text('Save profile'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _seed(LegalGoUser user) {
    if (_seeded) return;
    _email.text = user.email;
    _phone.text = user.phone ?? '';
    final currentProfile = user.profiles.cast<UserProfile?>().firstWhere(
          (profile) => profile?.profileType == 'company' && profile?.companyProfile != null,
          orElse: () => user.profiles.cast<UserProfile?>().firstWhere(
                (profile) => profile?.profileType == 'individual' && profile?.individualProfile != null,
                orElse: () => user.profiles.isEmpty ? null : user.profiles.first,
              ),
        );
    _profileType = currentProfile?.companyProfile != null ? 'company' : 'individual';
    final individual = currentProfile?.individualProfile;
    final company = currentProfile?.companyProfile;
    _firstname.text = individual?.firstname ?? '';
    _lastname.text = individual?.lastname ?? '';
    _companyName.text = company?.companyName ?? '';
    _legalForm.text = company?.legalForm ?? '';
    _siren.text = company?.siren ?? '';
    _vatNumber.text = company?.vatNumber ?? '';
    _address.text = company?.address ?? '';
    _seeded = true;
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _success = null;
      _errorBody = null;
    });
    try {
      final repo = ref.read(legalGoRepositoryProvider);
      await repo.updateMe(
        email: _email.text.trim(),
        phone: _blankToNull(_phone.text),
      );
      await repo.updateProfile(
        _profileType == 'individual'
            ? {
                'profileType': 'individual',
                'civility': 'Monsieur',
                if (_blankToNull(_firstname.text) != null) 'firstname': _blankToNull(_firstname.text),
                if (_blankToNull(_lastname.text) != null) 'lastname': _blankToNull(_lastname.text),
              }
            : {
                'profileType': 'company',
                if (_blankToNull(_companyName.text) != null) 'companyName': _blankToNull(_companyName.text),
                if (_blankToNull(_legalForm.text) != null) 'legalForm': _blankToNull(_legalForm.text),
                if (_blankToNull(_siren.text) != null) 'siren': _blankToNull(_siren.text),
                if (_blankToNull(_vatNumber.text) != null) 'vatNumber': _blankToNull(_vatNumber.text),
                if (_blankToNull(_address.text) != null) 'address': _blankToNull(_address.text),
              },
      );
      _seeded = false;
      ref.invalidate(profileProvider);
      setState(() => _success = 'Your profile has been updated.');
    } catch (error) {
      setState(() => _errorBody = backendResponseBody(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
