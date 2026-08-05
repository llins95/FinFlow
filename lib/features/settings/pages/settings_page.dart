import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../controllers/financial_month_controller.dart';
import '../../../services/sync_status_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.controller,
    this.supabaseClient,
  });

  final FinancialMonthController controller;
  final SupabaseClient? supabaseClient;

  @override
  Widget build(BuildContext context) {
    final user = supabaseClient?.auth.currentUser;
    final syncStatus = controller.syncStatus;

    return Scaffold(
      appBar: AppBar(title: const Text('Mais')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Conta pessoal'),
                  subtitle: Text(user?.email ?? 'Uso individual de Murilo'),
                ),
                const Divider(height: 1),
                if (syncStatus == null)
                  const ListTile(
                    leading: Icon(Icons.cloud_off_outlined),
                    title: Text('Dados locais'),
                    subtitle: Text('Sincronização desativada neste modo.'),
                  )
                else
                  AnimatedBuilder(
                    animation: syncStatus,
                    builder: (context, _) => _SyncStatusTile(
                      status: syncStatus,
                      onSync: () => unawaited(controller.syncNow()),
                    ),
                  ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.security_outlined),
                  title: Text('Segurança'),
                  subtitle: Text(
                    'Cada conta acessa somente os próprios dados. '
                    'O FinFlow não armazena número completo nem CVV.',
                  ),
                ),
              ],
            ),
          ),
          if (supabaseClient != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _confirmSignOut(context),
              icon: const Icon(Icons.logout),
              label: const Text('Sair da conta'),
            ),
          ],
        ],
      ),
    );
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

class _SyncStatusTile extends StatelessWidget {
  const _SyncStatusTile({
    required this.status,
    required this.onSync,
  });

  final SyncStatusController status;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[];

    if (status.pendingCount > 0) {
      final count = status.pendingCount;
      subtitleParts.add(
        count == 1
            ? '1 alteração pendente'
            : '$count alterações pendentes',
      );
    }

    final lastSyncedAt = status.lastSyncedAt;
    if (lastSyncedAt != null) {
      final localTime = lastSyncedAt.toLocal();
      final time =
          '${localTime.hour.toString().padLeft(2, '0')}:'
          '${localTime.minute.toString().padLeft(2, '0')}';
      subtitleParts.add('Última sincronização: $time');
    }

    if (status.lastError != null && status.pendingCount > 0) {
      subtitleParts.add('Será tentado novamente automaticamente.');
    }

    return ListTile(
      leading: Icon(_iconFor(status.phase)),
      title: Text(status.label),
      subtitle: subtitleParts.isEmpty
          ? const Text('Android e Windows usam os mesmos dados.')
          : Text(subtitleParts.join('\n')),
      trailing: status.phase == SyncPhase.syncing
          ? const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : IconButton(
              tooltip: 'Sincronizar agora',
              onPressed: onSync,
              icon: const Icon(Icons.sync),
            ),
      isThreeLine: subtitleParts.length > 1,
    );
  }

  IconData _iconFor(SyncPhase phase) {
    return switch (phase) {
      SyncPhase.localOnly => Icons.cloud_off_outlined,
      SyncPhase.synced => Icons.cloud_done_outlined,
      SyncPhase.syncing => Icons.cloud_sync_outlined,
      SyncPhase.pending => Icons.cloud_upload_outlined,
      SyncPhase.error => Icons.cloud_off_outlined,
    };
  }
}
