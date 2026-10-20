import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/app_store.dart';
import '../l10n/app_localizations.dart';
import '../core/roles.dart';

/// Admin page: invite people by email, set their roles, deactivate them.
/// Only users invited here can sign in.
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

const _allRoles = ['admin', 'manager', 'member', 'accountant', 'merchManager', 'merchStaff', 'socialManager'];

class _UsersScreenState extends State<UsersScreen> {
  List<Map<String, dynamic>> users = const [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final json = await AppStore.api.get('/api/v1/users') as Map<String, dynamic>;
      users = (json['items'] as List).cast<Map<String, dynamic>>();
    } catch (e) {
      AppStore.reportError(e);
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _patch(String id, Map<String, dynamic> body) async {
    try {
      await AppStore.api.patch('/api/v1/users/$id', body);
      await _load();
    } catch (e) {
      AppStore.reportError(e);
    }
  }

  Future<void> _post(String path, String doneMessage) async {
    try {
      await AppStore.api.post(path);
      AppStore.messengerKey.currentState?.showSnackBar(SnackBar(content: Text(doneMessage)));
    } catch (e) {
      AppStore.reportError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.users),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: () => _edit(null),
              icon: const Icon(Icons.person_add_alt_rounded, size: 20),
              label: Text(l.inviteUser),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
            ),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                for (final u in users)
                  Card(
                    child: ListTile(
                      onTap: () => _edit(u),
                      title: Text(u['name'] as String),
                      subtitle: Text(
                        '${u['email']}\n${(u['roles'] as List).map((r) => roleLabel(r as String)).join(', ')}',
                        style: t.bodySmall,
                      ),
                      isThreeLine: true,
                      trailing: Wrap(
                        spacing: 6,
                        children: [
                          if (u['active'] != true) StatusPill(label: l.inactive, color: TbnColors.danger),
                          if (u['active'] == true && u['emailVerified'] != true)
                            StatusPill(label: l.pendingInvite, color: TbnColors.warning),
                          if (u['twoFactorEnabled'] == true)
                            const Icon(Icons.verified_user_outlined, size: 18, color: TbnColors.success),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  void _edit(Map<String, dynamic>? user) {
    final l = AppLocalizations.of(context);
    final isNew = user == null;
    final name = TextEditingController(text: user?['name'] as String? ?? '');
    final email = TextEditingController(text: user?['email'] as String? ?? '');
    final roles = <String>{
      ...((user?['roles'] as List?)?.cast<String>() ?? const ['member'])
    };
    final isSelf = user?['id'] == AppStore.me.value?.id;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(sheetContext).viewInsets.bottom + 24),
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(isNew ? l.inviteUser : user['name'] as String, style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(controller: name, decoration: InputDecoration(labelText: l.name)),
              const SizedBox(height: 10),
              TextField(
                controller: email,
                enabled: isNew,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: l.email),
              ),
              const SizedBox(height: 12),
              Text(l.roles, style: Theme.of(sheetContext).textTheme.titleSmall),
              Wrap(
                spacing: 8,
                children: [
                  for (final r in _allRoles)
                    FilterChip(
                      label: Text(roleLabel(r)),
                      selected: roles.contains(r),
                      onSelected:
                          isSelf && r == 'admin' ? null : (v) => setSheet(() => v ? roles.add(r) : roles.remove(r)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  if (name.text.trim().isEmpty || roles.isEmpty) return;
                  Navigator.pop(sheetContext);
                  if (isNew) {
                    try {
                      await AppStore.api.post('/api/v1/users', {
                        'name': name.text.trim(),
                        'email': email.text.trim(),
                        'roles': roles.toList(),
                      });
                      AppStore.messengerKey.currentState
                          ?.showSnackBar(SnackBar(content: Text(l.inviteSent(email.text.trim()))));
                      await _load();
                    } catch (e) {
                      AppStore.reportError(e);
                    }
                  } else {
                    await _patch(user['id'] as String, {'name': name.text.trim(), 'roles': roles.toList()});
                  }
                },
                child: Text(isNew ? l.sendInvite : l.save),
              ),
              if (!isNew) ...[
                if (user['emailVerified'] != true && user['active'] == true)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _post('/api/v1/users/${user['id']}/resend-invite', l.inviteSent(user['email'] as String));
                    },
                    child: Text(l.resendInvite),
                  ),
                if (!isSelf) ...[
                  TextButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _post('/api/v1/users/${user['id']}/revoke-sessions', l.done);
                    },
                    child: Text(l.signOutEverywhere),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _patch(user['id'] as String, {'active': user['active'] != true});
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: user['active'] == true ? TbnColors.danger : TbnColors.success,
                    ),
                    child: Text(user['active'] == true ? l.deactivate : l.activate),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
