import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../core/app_info.dart';
import '../core/theme.dart';
import '../data/app_store.dart';
import '../l10n/app_localizations.dart';
import 'main_shell.dart';
import 'two_factor_screen.dart';

/// After a successful sign-in (or on start with a valid session): enforce 2FA enrollment for roles
/// that need it, load the data, open the app.
Future<void> enterApp(BuildContext context) async {
  final navigator = Navigator.of(context);
  final me = await AppStore.loadMe();
  if (me == null) {
    navigator.pushAndRemoveUntil(MaterialPageRoute<void>(builder: (_) => const AuthScreen()), (_) => false);
    return;
  }
  if (me.needsTwoFactorSetup) {
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const TwoFactorSetupScreen(required: true)),
      (_) => false,
    );
    return;
  }
  await AppStore.loadAll();
  navigator.pushAndRemoveUntil(MaterialPageRoute<void>(builder: (_) => const MainShell()), (_) => false);
}

Future<void> signOutAndReturnToLogin(BuildContext context) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  await AppStore.signOut();
  navigator.pushAndRemoveUntil(MaterialPageRoute<void>(builder: (_) => const AuthScreen()), (_) => false);
}

/// First screen: restores an existing session, otherwise shows the sign-in form.
class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  String? error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() => error = null);
    try {
      final me = await AppStore.loadMe();
      if (!mounted) return;
      if (me == null) return _toLogin();
      await enterApp(context);
    } on ApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    }
  }

  void _toLogin() {
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => const AuthScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TbnLogoMark(size: 110),
            const SizedBox(height: 24),
            if (error == null)
              const CircularProgressIndicator()
            else ...[
              Text(l.offline),
              const SizedBox(height: 12),
              FilledButton(onPressed: _start, child: Text(l.retry)),
            ],
          ],
        ),
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  final code = TextEditingController();
  bool needCode = false;
  bool backupCode = false;
  bool trustDevice = false;
  bool busy = false;
  String? message;

  @override
  void dispose() {
    for (final c in [email, password, code]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await action();
    } on ApiException catch (e) {
      if (mounted) setState(() => message = _messageFor(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String _messageFor(ApiException e) {
    final l = AppLocalizations.of(context);
    if (e.isOffline) return l.offline;
    if (e.status == 429) return l.tooManyAttempts;
    if (needCode) return l.wrongCode;
    if (e.status == 401 || e.status == 400) return l.invalidCredentials;
    return e.message;
  }

  Future<void> _signIn() => _run(() async {
        final res = await AppStore.api.post('/api/auth/sign-in/email', {
          'email': email.text.trim(),
          'password': password.text,
        }) as Map<String, dynamic>?;
        password.clear();
        if (res?['twoFactorRedirect'] == true) {
          setState(() => needCode = true);
          return;
        }
        if (mounted) await enterApp(context);
      });

  Future<void> _verify() => _run(() async {
        final path = backupCode ? '/api/auth/two-factor/verify-backup-code' : '/api/auth/two-factor/verify-totp';
        await AppStore.api.post(path, {'code': code.text.trim(), 'trustDevice': trustDevice});
        if (mounted) await enterApp(context);
      });

  Future<void> _forgot() => _run(() async {
        final l = AppLocalizations.of(context);
        if (email.text.trim().isEmpty) {
          setState(() => message = l.enterEmailFirst);
          return;
        }
        await AppStore.api.post('/api/auth/request-password-reset', {'email': email.text.trim()});
        setState(() => message = l.resetSent);
      });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = theme.textTheme;
    final l = AppLocalizations.of(context);
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
                    child: AutofillGroup(
                      child: ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                        children: [
                          const TbnLogoMark(size: 150),
                          const SizedBox(height: 18),
                          Text(
                            'TBN MANAGER',
                            textAlign: TextAlign.center,
                            style: t.headlineSmall?.copyWith(letterSpacing: 4, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l.appTagline,
                            textAlign: TextAlign.center,
                            style: t.labelSmall?.copyWith(letterSpacing: 2.2, color: muted),
                          ),
                          const SizedBox(height: 40),
                          if (!needCode) ...[
                            TextField(
                              controller: email,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email, AutofillHints.username],
                              decoration: InputDecoration(labelText: l.email),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: password,
                              obscureText: true,
                              autofillHints: const [AutofillHints.password],
                              onSubmitted: (_) => busy ? null : _signIn(),
                              decoration: InputDecoration(labelText: l.password),
                            ),
                            const SizedBox(height: 20),
                            FilledButton(
                              onPressed: busy ? null : _signIn,
                              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                              child: busy
                                  ? const SizedBox.square(
                                      dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                  : Text(l.signIn),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: TextButton(
                                onPressed: busy ? null : _forgot,
                                style: TextButton.styleFrom(foregroundColor: muted),
                                child: Text(l.forgotPassword),
                              ),
                            ),
                          ] else ...[
                            Text(l.twoFactorCodeTitle, style: t.titleMedium),
                            const SizedBox(height: 6),
                            Text(l.twoFactorCodeHelp, style: t.bodySmall?.copyWith(color: muted)),
                            const SizedBox(height: 16),
                            TextField(
                              controller: code,
                              autofocus: true,
                              keyboardType: backupCode ? TextInputType.text : TextInputType.number,
                              autofillHints: const [AutofillHints.oneTimeCode],
                              onSubmitted: (_) => busy ? null : _verify(),
                              decoration: InputDecoration(labelText: backupCode ? l.backupCode : l.twoFactorCode),
                            ),
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              value: trustDevice,
                              onChanged: (v) => setState(() => trustDevice = v ?? false),
                              title: Text(l.trustDevice, style: t.bodySmall),
                            ),
                            FilledButton(
                              onPressed: busy ? null : _verify,
                              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                              child: Text(l.verify),
                            ),
                            TextButton(
                              onPressed: () => setState(() => backupCode = !backupCode),
                              style: TextButton.styleFrom(foregroundColor: muted),
                              child: Text(backupCode ? l.twoFactorCode : l.useBackupCode),
                            ),
                          ],
                          if (message != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(message!, textAlign: TextAlign.center, style: t.bodySmall),
                            ),
                          const SizedBox(height: 20),
                          Text(
                            l.inviteOnly,
                            textAlign: TextAlign.center,
                            style:
                                t.bodySmall?.copyWith(fontSize: 11, height: 1.5, color: muted.withValues(alpha: 0.8)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  appVersionLabel,
                  style: t.labelSmall?.copyWith(letterSpacing: 1, color: muted.withValues(alpha: 0.6)),
                ),
              ),
            ],
          ),
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
