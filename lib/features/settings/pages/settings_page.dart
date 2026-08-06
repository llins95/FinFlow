import 'dart:async';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../controllers/app_update_controller.dart';
import '../../../controllers/financial_month_controller.dart';
import '../../../controllers/theme_controller.dart';
import '../../../models/app_update.dart';
import '../../../services/sync_status_controller.dart';
import '../../purchase/pages/notification_import_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.controller,
    required this.appUpdateController,
    required this.themeController,
    this.supabaseClient,
  });

  final FinancialMonthController controller;
  final AppUpdateController appUpdateController;
  final ThemeController themeController;
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
                  leading: const Icon(FluentIcons.person_24_regular),
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
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Compras pela Carteira do Google'),
                  subtitle: const Text(
                    'No Android, detecta compras para você revisar antes '
                    'de salvar.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    final importedIds = controller.purchaseRecords
                        .map((record) => record.entry.sourceReference)
                        .whereType<String>()
                        .toSet();
                    unawaited(
                      Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (context) => NotificationImportPage(
                            ignoredCandidateIds: importedIds,
                          ),
                        ),
                      ),
                    );
                  },
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
          const SizedBox(height: 16),
          _ThemeModeCard(controller: themeController),
          const SizedBox(height: 16),
          _AppUpdateCard(controller: appUpdateController),
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

class _ThemeModeCard extends StatelessWidget {
  const _ThemeModeCard({required this.controller});

  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(FluentIcons.dark_theme_24_regular),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aparência',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        const Text('Escolha o tema Fluent usado no FinFlow.'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SegmentedButton<ThemeMode>(
                key: const ValueKey('theme-mode-selector'),
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('Sistema'),
                  ),
                  ButtonSegment(value: ThemeMode.light, label: Text('Claro')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Escuro')),
                ],
                selected: {controller.mode},
                onSelectionChanged: (selection) {
                  unawaited(controller.setMode(selection.single));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppUpdateCard extends StatelessWidget {
  const _AppUpdateCard({required this.controller});

  final AppUpdateController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final installed = controller.installedVersion;
        final available = controller.availableUpdate;

        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.system_update_alt),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Atualização do aplicativo',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(_statusText(controller)),
                        ],
                      ),
                    ),
                    if (controller.isBusy)
                      const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                if (installed != null || available != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    [
                      if (installed != null) 'Instalada: ${installed.name}',
                      if (available != null)
                        'Disponível: ${available.versionName}',
                    ].join('  •  '),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (controller.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    controller.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (available != null)
                  FilledButton.icon(
                    onPressed: controller.isBusy
                        ? null
                        : () => unawaited(controller.downloadAndInstall()),
                    icon: const Icon(Icons.download),
                    label: Text(
                      controller.status ==
                              AppUpdateStatus.waitingForInstallPermission
                          ? 'Autorizar instalação'
                          : 'Baixar e instalar',
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: controller.isBusy
                        ? null
                        : () => unawaited(controller.checkForUpdates()),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Verificar atualizações'),
                  ),
                const SizedBox(height: 8),
                const Text(
                  'O Android sempre pedirá sua confirmação antes de '
                  'instalar. O APK é validado por SHA-256.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _statusText(AppUpdateController controller) {
    return switch (controller.status) {
      AppUpdateStatus.idle => 'Verifique se existe uma nova versão.',
      AppUpdateStatus.unsupported =>
        'Atualização dentro do app disponível apenas no Android.',
      AppUpdateStatus.checking => 'Verificando no GitHub...',
      AppUpdateStatus.upToDate => 'Você já está na versão mais recente.',
      AppUpdateStatus.available => 'Uma nova versão está disponível.',
      AppUpdateStatus.waitingForInstallPermission =>
        'Permita que o FinFlow instale apps e volte para continuar.',
      AppUpdateStatus.downloading => 'Baixando e validando o APK...',
      AppUpdateStatus.openingInstaller =>
        'Confirme a atualização na tela do Android.',
      AppUpdateStatus.error => 'Não foi possível atualizar agora.',
    };
  }
}

class _SyncStatusTile extends StatelessWidget {
  const _SyncStatusTile({required this.status, required this.onSync});

  final SyncStatusController status;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[];

    if (status.pendingCount > 0) {
      final count = status.pendingCount;
      subtitleParts.add(
        count == 1 ? '1 alteração pendente' : '$count alterações pendentes',
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
