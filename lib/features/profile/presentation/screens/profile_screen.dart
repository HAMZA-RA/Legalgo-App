import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalgo_mobile/core/design_system/design_system.dart';
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
      backgroundColor: AppColors.pageBackground(context),
      appBar: const PremiumAppBar(title: 'Profil'),
      body: profileAsync.when(
        loading: () => const LoadingView(message: 'Chargement du profil'),
        error: (error, _) => ErrorStateView(
          message: error.toString(),
          onRetry: () => ref.invalidate(profileProvider),
        ),
        data: (user) {
          _seed(user);
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
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_success != null) ...[
                        _NoticeCard(
                          message: _success!,
                          icon: Icons.check_circle_outline,
                          color: AppColors.success,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      if (_errorBody != null) ...[
                        _ErrorCard(message: _errorBody!),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      _ProfileHero(user: user),
                      const SizedBox(height: AppSpacing.xxl),
                      const SectionHeader(
                        title: 'Compte',
                        subtitle: 'Informations principales de contact',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppCard(
                        child: Column(
                          children: [
                            TextField(
                              controller: _email,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.mail_outline_rounded),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextField(
                              controller: _phone,
                              decoration: const InputDecoration(
                                labelText: 'Téléphone',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      const SectionHeader(
                        title: 'Type de profil',
                        subtitle:
                            'Informations utilisées dans votre espace LegalGo',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(
                                    value: 'individual',
                                    label: Text('Particulier'),
                                    icon: Icon(Icons.person_outline),
                                  ),
                                  ButtonSegment(
                                    value: 'company',
                                    label: Text('Entreprise'),
                                    icon: Icon(Icons.business_outlined),
                                  ),
                                ],
                                selected: {_profileType},
                                onSelectionChanged: (value) =>
                                    setState(() => _profileType = value.first),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: _profileType == 'individual'
                                  ? _IndividualFields(
                                      key: const ValueKey('individual'),
                                      firstname: _firstname,
                                      lastname: _lastname,
                                    )
                                  : _CompanyFields(
                                      key: const ValueKey('company'),
                                      companyName: _companyName,
                                      legalForm: _legalForm,
                                      siren: _siren,
                                      vatNumber: _vatNumber,
                                      address: _address,
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: const Text('Enregistrer le profil'),
                        ),
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
  }

  void _seed(LegalGoUser user) {
    if (_seeded) return;
    _email.text = user.email;
    _phone.text = user.phone ?? '';
    final currentProfile = user.profiles.cast<UserProfile?>().firstWhere(
      (profile) =>
          profile?.profileType == 'company' && profile?.companyProfile != null,
      orElse: () => user.profiles.cast<UserProfile?>().firstWhere(
        (profile) =>
            profile?.profileType == 'individual' &&
            profile?.individualProfile != null,
        orElse: () => user.profiles.isEmpty ? null : user.profiles.first,
      ),
    );
    _profileType = currentProfile?.companyProfile != null
        ? 'company'
        : 'individual';
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
                if (_blankToNull(_firstname.text) != null)
                  'firstname': _blankToNull(_firstname.text),
                if (_blankToNull(_lastname.text) != null)
                  'lastname': _blankToNull(_lastname.text),
              }
            : {
                'profileType': 'company',
                if (_blankToNull(_companyName.text) != null)
                  'companyName': _blankToNull(_companyName.text),
                if (_blankToNull(_legalForm.text) != null)
                  'legalForm': _blankToNull(_legalForm.text),
                if (_blankToNull(_siren.text) != null)
                  'siren': _blankToNull(_siren.text),
                if (_blankToNull(_vatNumber.text) != null)
                  'vatNumber': _blankToNull(_vatNumber.text),
                if (_blankToNull(_address.text) != null)
                  'address': _blankToNull(_address.text),
              },
      );
      _seeded = false;
      ref.invalidate(profileProvider);
      setState(() => _success = 'Votre profil a été mis à jour.');
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

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.user});

  final LegalGoUser user;

  @override
  Widget build(BuildContext context) {
    final initial = user.email.isEmpty
        ? 'L'
        : user.email.characters.first.toUpperCase();
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AppCard(
      gradient: dark
          ? AppColors.heroGradient(context)
          : AppColors.primaryGradient,
      borderColor: Colors.white.withValues(alpha: dark ? .08 : .22),
      padding: const EdgeInsets.all(AppSpacing.lg),
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
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .16),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .20),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          user.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: .82),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  StatusBadge(value: user.role),
                  StatusBadge(value: user.status ? 'active' : 'inactive'),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                width: double.infinity,
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
                    const Icon(
                      Icons.verified_user_outlined,
                      color: AppColors.softIndigo,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Gardez votre profil LegalGo à jour pour le suivi de vos documents et de vos demandes.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
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

class _IndividualFields extends StatelessWidget {
  const _IndividualFields({
    super.key,
    required this.firstname,
    required this.lastname,
  });

  final TextEditingController firstname;
  final TextEditingController lastname;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: firstname,
          decoration: const InputDecoration(
            labelText: 'Prénom',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: lastname,
          decoration: const InputDecoration(
            labelText: 'Nom',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
        ),
      ],
    );
  }
}

class _CompanyFields extends StatelessWidget {
  const _CompanyFields({
    super.key,
    required this.companyName,
    required this.legalForm,
    required this.siren,
    required this.vatNumber,
    required this.address,
  });

  final TextEditingController companyName;
  final TextEditingController legalForm;
  final TextEditingController siren;
  final TextEditingController vatNumber;
  final TextEditingController address;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: companyName,
          decoration: const InputDecoration(
            labelText: 'Raison sociale',
            prefixIcon: Icon(Icons.business_outlined),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: legalForm,
          decoration: const InputDecoration(
            labelText: 'Forme juridique',
            prefixIcon: Icon(Icons.account_balance_outlined),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: siren,
          decoration: const InputDecoration(
            labelText: 'SIREN',
            prefixIcon: Icon(Icons.numbers_outlined),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: vatNumber,
          decoration: const InputDecoration(
            labelText: 'Numéro de TVA',
            prefixIcon: Icon(Icons.receipt_long_outlined),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: address,
          decoration: const InputDecoration(
            labelText: 'Adresse',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
        ),
      ],
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.message,
    required this.icon,
    required this.color,
  });

  final String message;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: color.withValues(alpha: .10),
      borderColor: color.withValues(alpha: .18),
      shadows: AppShadows.none,
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.danger.withValues(alpha: .10),
      borderColor: AppColors.danger.withValues(alpha: .18),
      shadows: AppShadows.none,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.danger),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Réponse du serveur',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SelectableText(message),
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
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
