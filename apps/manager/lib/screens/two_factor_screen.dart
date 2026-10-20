import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../api/api_client.dart';
import '../data/app_store.dart';
import '../l10n/app_localizations.dart';
import 'auth_screen.dart';

/// Enrolls TOTP two-factor authentication. Shown automatically to roles that require it
/// ([required] = true: no way back except signing out), or from Settings.
class TwoFactorSetupScreen extends StatefulWidget {
  const TwoFactorSetupScreen({super.key, required this.required});

  final bool required;

  @override
  State<TwoFactorSetupScreen> createState() => _TwoFactorSetupScreenState();
}

class _TwoFactorSetupScreenState extends State<TwoFactorSetupScreen> {
  final password = TextEditingController();
  final code = TextEditingController();
  String? totpUri;
  List<String> backupCodes = const [];
  bool busy = false;
  bool finished = false;
  String? message;

  @override
  void dispose() {
    password.dispose();
    code.dispose();
    super.dispose();
  }

  String get _secret => Uri.parse(totpUri!).queryParameters['secret'] ?? '';

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await action();
    } on ApiException catch (e) {
      if (mounted) setState(() => message = e.isOffline ? AppLocalizations.of(context).offline : e.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _start() => _run(() async {
        final res =
            await AppStore.api.post('/api/auth/two-factor/enable', {'password': password.text}) as Map<String, dynamic>;
        password.clear();
        setState(() {
          totpUri = res['totpURI'] as String;
          backupCodes = List<String>.from(res['backupCodes'] as List);
        });
      });

  Future<void> _verify() => _run(() async {
        try {
          await AppStore.api.post('/api/auth/two-factor/verify-totp', {'code': code.text.trim()});
        } on ApiException {
          if (mounted) setState(() => message = AppLocalizations.of(context).wrongCode);
          return;
        }
        await AppStore.loadMe();
        setState(() => finished = true);
      });

  Future<void> _done() async {
    if (widget.required) {
      await enterApp(context);
    } else if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.setup2faTitle),
        automaticallyImplyLeading: !widget.required,
        actions: [
          if (widget.required) TextButton(onPressed: () => signOutAndReturnToLogin(context), child: Text(l.signOut)),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (widget.required) ...[
                Text(l.setup2faRequired, style: t.bodyMedium),
                const SizedBox(height: 16),
              ],
              if (finished) ...[
                Text(l.backupCodesTitle, style: t.titleMedium),
                const SizedBox(height: 6),
                Text(l.backupCodesHelp, style: t.bodySmall?.copyWith(color: muted)),
                const SizedBox(height: 12),
                SelectableText(backupCodes.join('\n'),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 16, height: 1.6)),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: backupCodes.join('\n')));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.copied)));
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: Text(l.copy),
                ),
                const SizedBox(height: 12),
                FilledButton(onPressed: _done, child: Text(l.done)),
              ] else if (totpUri == null) ...[
                Text(l.setup2faStep1, style: t.titleSmall),
                const SizedBox(height: 10),
                TextField(
                  controller: password,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => busy ? null : _start(),
                  decoration: InputDecoration(labelText: l.password),
                ),
                const SizedBox(height: 12),
                FilledButton(onPressed: busy ? null : _start, child: Text(l.continueLabel)),
              ] else ...[
                Text(l.setup2faStep2, style: t.titleSmall),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(12),
                    child: QrImageView(data: totpUri!, size: 200, backgroundColor: Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(_secret, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'monospace')),
                const SizedBox(height: 16),
                Text(l.setup2faStep3, style: t.titleSmall),
                const SizedBox(height: 10),
                TextField(
                  controller: code,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  onSubmitted: (_) => busy ? null : _verify(),
                  decoration: InputDecoration(labelText: l.twoFactorCode),
                ),
                const SizedBox(height: 12),
                FilledButton(onPressed: busy ? null : _verify, child: Text(l.verify)),
              ],
              if (message != null)
                Padding(padding: const EdgeInsets.only(top: 12), child: Text(message!, style: t.bodySmall)),
            ],
          ),
        ),
      ),
    );
  }
}
