import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_error.dart';
import 'auth_provider.dart';
import 'username_validator.dart';
import 'widgets/auth_page_layout.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _acceptedTerms = false;
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      showErrorSnackBar(context, 'Kullanım şartlarını kabul etmelisiniz');
      return;
    }
    if (!mounted) return;

    setState(() => _loading = true);
    final error = await ref
        .read(authStateProvider.notifier)
        .register(_username.text.trim(), _password.text);
    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      showErrorSnackBar(context, error);
      return;
    }
    final redirect = GoRouterState.of(context).uri.queryParameters['redirect'];
    if (redirect != null && redirect.isNotEmpty) {
      context.go(redirect);
    } else {
      context.go('/home');
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AuthPageLayout(
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Zaten hesabınız var mı?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          TextButton(
            onPressed: _loading ? null : () => context.go('/login'),
            child: const Text('Giriş yapın'),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Hesap oluşturun',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Talep göndermek ve sepetinizi kaydetmek için ücretsiz üye olun',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _username,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              autocorrect: false,
              decoration: _fieldDecoration(
                label: 'Kullanıcı adı',
                icon: Icons.person_outline_rounded,
              ),
              validator: validateUsername,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onFieldSubmitted: (_) => _submit(),
              decoration: _fieldDecoration(
                label: 'Şifre',
                icon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Şifreyi göster' : 'Şifreyi gizle',
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: validatePassword,
            ),
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _acceptedTerms
                      ? colorScheme.primary.withValues(alpha: 0.35)
                      : colorScheme.outlineVariant,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _acceptedTerms,
                      onChanged: _loading
                          ? null
                          : (value) =>
                              setState(() => _acceptedTerms = value ?? false),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text.rich(
                          TextSpan(
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Kullanım şartlarını ve ',
                              ),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.baseline,
                                baseline: TextBaseline.alphabetic,
                                child: GestureDetector(
                                  onTap: _loading
                                      ? null
                                      : () => context.push('/privacy'),
                                  child: Text(
                                    'gizlilik politikasını',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                              const TextSpan(text: ' kabul ediyorum.'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            AuthPrimaryButton(
              label: 'Kayıt Ol',
              loading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: _loading ? null : () => context.go('/home'),
                child: const Text('Önce ürünleri incele'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
