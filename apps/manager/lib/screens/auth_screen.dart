import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/app_info.dart';
import '../core/theme.dart';
import '../security/app_lock_service.dart';
import 'main_shell.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool signUp = false;

  Future<void> _submit() async {
    final allowed = await AppLockService.authenticate();

    if (!mounted || !allowed) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = theme.textTheme;
    final muted = theme.colorScheme.onSurfaceVariant;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.75),
            radius: 1.1,
            colors: isDark
                ? const [Color(0xFF1B1F27), TbnColors.darkBackground]
                : const [Color(0xFFFFFFFF), TbnColors.creamBackground],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 24,
                      ),
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          builder: (context, v, child) => Opacity(
                            opacity: v,
                            child: Transform.translate(
                              offset: Offset(0, (1 - v) * 12),
                              child: child,
                            ),
                          ),
                          child: Column(
                            children: [
                              const TbnLogoMark(size: 150),
                              const SizedBox(height: 18),
                              Text(
                                'TBN MANAGER',
                                textAlign: TextAlign.center,
                                style: t.headlineSmall?.copyWith(
                                  letterSpacing: 4,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'TOURING  ·  MERCH  ·  FINANCE',
                                textAlign: TextAlign.center,
                                style: t.labelSmall?.copyWith(
                                  letterSpacing: 2.2,
                                  color: muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        Row(
                          children: [
                            _TabLabel(
                              label: 'Log in',
                              selected: !signUp,
                              onTap: () => setState(() => signUp = false),
                            ),
                            const SizedBox(width: 24),
                            _TabLabel(
                              label: 'Sign up',
                              selected: signUp,
                              onTap: () => setState(() => signUp = true),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const TextField(
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: [AutofillHints.email],
                          decoration: InputDecoration(
                            labelText: 'Email',
                          ),
                        ),
                        const SizedBox(height: 12),
                        const TextField(
                          obscureText: true,
                          autofillHints: [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: 'Password',
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _submit,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            child: Text(
                              signUp ? 'Create account' : 'Log in',
                              key: ValueKey<bool>(signUp),
                            ),
                          ),
                        ),
                        if (!signUp)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                foregroundColor: muted,
                              ),
                              child: const Text('Reset password'),
                            ),
                          ),
                        const SizedBox(height: 20),
                        Text(
                          kIsWeb
                              ? 'Η πρόσβαση προστατεύεται από Cloudflare '
                                  'Access. Μην καταχωρείς πραγματικά '
                                  'προσωπικά στοιχεία μελών μέχρι να '
                                  'ενεργοποιηθεί το backend.'
                              : 'Τα ευαίσθητα στοιχεία μελών '
                                  'αποθηκεύονται στο iOS Keychain. Η '
                                  'είσοδος απαιτεί Face ID, Touch ID ή '
                                  'κωδικό συσκευής.',
                          textAlign: TextAlign.center,
                          style: t.bodySmall?.copyWith(
                            fontSize: 11,
                            height: 1.5,
                            color: muted.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  appVersionLabel,
                  style: t.labelSmall?.copyWith(
                    letterSpacing: 1,
                    color: muted.withValues(alpha: 0.6),
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

class _TabLabel extends StatelessWidget {
  const _TabLabel({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: selected
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: selected ? 28 : 0,
              decoration: BoxDecoration(
                color: TbnColors.accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The band logo. [size] is the logo height; width follows the image ratio.
class TbnLogoMark extends StatelessWidget {
  const TbnLogoMark({
    super.key,
    this.size = 40,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/tbn_logo.png',
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: 'The Bonnie Nettles',
    );
  }
}
