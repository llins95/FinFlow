import 'dart:async';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({
    super.key,
    this.supabaseClient,
    this.onSignInAnotherAccount,
    this.onCreateAccount,
  });

  final SupabaseClient? supabaseClient;
  final Future<void> Function()? onSignInAnotherAccount;
  final Future<void> Function()? onCreateAccount;

  @override
  Widget build(BuildContext context) {
    final email = supabaseClient?.auth.currentUser?.email;

    return Scaffold(
      appBar: AppBar(title: const Text('Conta pessoal')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    child: const Icon(FluentIcons.person_24_regular, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Conta atual',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(email ?? 'Dados armazenados neste aparelho'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (supabaseClient != null) ...[
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    key: const ValueKey('account-sign-in-another'),
                    leading: const Icon(Icons.login),
                    title: const Text('Entrar em outra conta'),
                    subtitle: const Text(
                      'Troque de usuário sem misturar os dados financeiros.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: onSignInAnotherAccount == null
                        ? null
                        : () => unawaited(
                            _confirmAccountAction(
                              context,
                              createAccount: false,
                            ),
                          ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    key: const ValueKey('account-create-new'),
                    leading: const Icon(Icons.person_add_alt_1_outlined),
                    title: const Text('Criar nova conta'),
                    subtitle: const Text(
                      'Crie uma conta separada para outra pessoa usar o '
                      'FinFlow.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: onCreateAccount == null
                        ? null
                        : () => unawaited(
                            _confirmAccountAction(
                              context,
                              createAccount: true,
                            ),
                          ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    key: const ValueKey('account-sign-out'),
                    leading: const Icon(Icons.logout),
                    title: const Text('Sair da conta'),
                    subtitle: const Text(
                      'Encerre o acesso desta conta neste aparelho.',
                    ),
                    onTap: () => unawaited(_confirmSignOut(context)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: Icon(Icons.security_outlined),
              title: Text('Segurança'),
              subtitle: Text(
                'Cada conta acessa somente os próprios dados. '
                'O FinFlow não armazena número completo nem CVV.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAccountAction(
    BuildContext context, {
    required bool createAccount,
  }) async {
    final action = createAccount ? onCreateAccount : onSignInAnotherAccount;
    if (action == null) {
      return;
    }

    final currentEmail = supabaseClient?.auth.currentUser?.email;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          createAccount ? Icons.person_add_alt_1_outlined : Icons.login,
        ),
        title: Text(
          createAccount ? 'Criar nova conta?' : 'Entrar em outra conta?',
        ),
        content: Text(
          currentEmail == null
              ? 'O FinFlow abrirá a tela de autenticação. Cada conta mantém '
                    'os próprios dados separados.'
              : 'Você sairá de $currentEmail. Os dados dessa conta '
                    'continuarão salvos e não serão misturados com os dados '
                    'da outra conta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await action();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              createAccount
                  ? 'Não foi possível criar outra conta agora. Verifique a '
                        'conexão e tente novamente.'
                  : 'Não foi possível trocar de conta agora. Verifique a '
                        'conexão e tente novamente.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text(
          'Os dados já salvos continuam neste aparelho e serão '
          'sincronizados no próximo login.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      await supabaseClient?.auth.signOut();
    }
  }
}
