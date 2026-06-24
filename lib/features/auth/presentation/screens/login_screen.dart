import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalgo_mobile/core/design_system/design_system.dart';
import 'package:legalgo_mobile/features/auth/presentation/providers/auth_providers.dart';

const _loginPrimary = Color(0xFF5B5CF6);
const _loginViolet = Color(0xFF7C5CFA);
const _loginCta = Color(0xFF18385B);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _forgotLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.pageBackground(context),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final mobile = constraints.maxWidth < 600;
            final form = _LoginForm(
              formKey: _formKey,
              emailController: _emailController,
              passwordController: _passwordController,
              obscurePassword: _obscurePassword,
              forgotLoading: _forgotLoading,
              authLoading: authState.isLoading,
              errorMessage: authState.errorMessage,
              compactMobile: mobile,
              onTogglePassword: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              onForgotPassword: _forgotPassword,
              onSubmit: _submit,
            );

            if (!mobile) {
              return _DesktopLoginLayout(form: form);
            }
            return _MobileLoginLayout(form: form);
          },
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await ref
          .read(authControllerProvider.notifier)
          .login(
            email: _emailController.text,
            password: _passwordController.text,
          );
    } catch (_) {
      // Le contrôleur conserve le message d’erreur affiché.
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    if (email.isEmpty || !email.contains('@')) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Saisissez d’abord votre adresse email.')),
      );
      return;
    }
    setState(() => _forgotLoading = true);
    try {
      await ref.read(authControllerProvider.notifier).forgotPassword(email);
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Un email de réinitialisation a été envoyé si le compte existe.',
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Impossible d’envoyer l’email : $error')),
      );
    } finally {
      if (mounted) setState(() => _forgotLoading = false);
    }
  }
}

class _MobileLoginLayout extends StatelessWidget {
  const _MobileLoginLayout({required this.form});

  final Widget form;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.lg,
            AppSpacing.screenHorizontal,
            AppSpacing.screenBottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _MobileLegalGoBrand(),
                    const SizedBox(height: AppSpacing.xxl),
                    form,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MobileLegalGoBrand extends StatelessWidget {
  const _MobileLegalGoBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_loginPrimary, _loginViolet],
            ),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: const Icon(
            Icons.balance_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'LegalGo',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _DesktopLoginLayout extends StatelessWidget {
  const _DesktopLoginLayout({required this.form});

  final Widget form;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1060),
          child: AppCard(
            padding: EdgeInsets.zero,
            shadows: AppShadows.elevated(context),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Expanded(flex: 11, child: _LoginHero(compact: false)),
                  Expanded(
                    flex: 9,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxl,
                        vertical: AppSpacing.xxxl,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 410),
                          child: form,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginHero extends StatelessWidget {
  const _LoginHero({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _LegalGoBrand(),
        SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xxxl),
        Text(
          'Votre espace LegalGo',
          style:
              (compact
                      ? Theme.of(context).textTheme.headlineSmall
                      : Theme.of(context).textTheme.displaySmall)
                  ?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    letterSpacing: 0,
                  ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Accédez en toute sécurité à vos demandes, documents et paiements.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: .82),
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xxxl),
        const Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            _TrustChip(icon: Icons.shield_outlined, label: 'Accès sécurisé'),
            _TrustChip(icon: Icons.sync_rounded, label: 'Espace en temps réel'),
          ],
        ),
      ],
    );

    return Container(
      width: double.infinity,
      constraints: compact ? null : const BoxConstraints(minHeight: 520),
      padding: EdgeInsets.fromLTRB(
        compact ? AppSpacing.screenHorizontal : AppSpacing.xxxl,
        compact ? AppSpacing.lg : AppSpacing.xxxl,
        compact ? AppSpacing.screenHorizontal : AppSpacing.xxxl,
        compact ? 52 : AppSpacing.xxxl,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_loginPrimary, _loginViolet],
        ),
        borderRadius: compact
            ? const BorderRadius.vertical(bottom: Radius.circular(32))
            : const BorderRadius.horizontal(left: Radius.circular(24)),
      ),
      child: compact ? content : Center(child: content),
    );
  }
}

class _LegalGoBrand extends StatelessWidget {
  const _LegalGoBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .12),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.balance_rounded,
            color: _loginPrimary,
            size: 28,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'LegalGo',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _TrustChip extends StatelessWidget {
  const _TrustChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        borderRadius: AppRadius.chip,
        border: Border.all(color: Colors.white.withValues(alpha: .18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.forgotLoading,
    required this.authLoading,
    required this.onTogglePassword,
    required this.onForgotPassword,
    required this.onSubmit,
    this.compactMobile = false,
    this.errorMessage,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool forgotLoading;
  final bool authLoading;
  final String? errorMessage;
  final VoidCallback onTogglePassword;
  final VoidCallback onForgotPassword;
  final VoidCallback onSubmit;
  final bool compactMobile;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AutofillGroup(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              compactMobile ? 'Connexion' : 'Bienvenue',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              compactMobile
                  ? 'Accédez à votre espace LegalGo'
                  : 'Connectez-vous à votre espace sécurisé.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: compactMobile ? AppSpacing.lg : AppSpacing.xl),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty || !email.contains('@')) {
                  return 'Saisissez une adresse email valide';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: passwordController,
              obscureText: obscurePassword,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => authLoading ? null : onSubmit(),
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: obscurePassword
                      ? 'Afficher le mot de passe'
                      : 'Masquer le mot de passe',
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: onTogglePassword,
                ),
              ),
              validator: (value) {
                if ((value ?? '').length < 8) {
                  return 'Le mot de passe doit contenir au moins 8 caractères';
                }
                return null;
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: forgotLoading || authLoading
                    ? null
                    : onForgotPassword,
                child: forgotLoading
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Mot de passe oublié ?'),
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: AppSpacing.xs),
              _AuthError(message: errorMessage!),
            ],
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _loginCta,
                  foregroundColor: Colors.white,
                ),
                onPressed: authLoading ? null : onSubmit,
                icon: authLoading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.login_rounded),
                label: const Text('Connexion'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthError extends StatelessWidget {
  const _AuthError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppCard(
      color: colorScheme.error.withValues(alpha: .10),
      borderColor: colorScheme.error.withValues(alpha: .18),
      shadows: AppShadows.none,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
