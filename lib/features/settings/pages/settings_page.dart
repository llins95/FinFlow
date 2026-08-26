import 'dart:async';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../controllers/app_update_controller.dart';
import '../../../controllers/financial_month_controller.dart';
import '../../../controllers/theme_controller.dart';
import '../../../models/app_update.dart';
import '../../../services/notification_purchase_import_service.dart';
import '../../../services/sync_status_controller.dart';
import '../../../shared/purchase_repository.dart';
import '../../../shared/utility_expenses_repository.dart';
import '../../pix/widgets/pix_qr_code_dialog.dart';
import '../../purchase/pages/notification_import_page.dart';
import 'account_settings_page.dart';
import 'utility_expenses_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.controller,
    required this.appUpdateController,
    required this.themeController,
    this.supabaseClient,
    this.onSignInAnotherAccount,
    this.onCreateAccount,
  });

  final FinancialMonthController controller;
  final AppUpdateController appUpdateController;
  final ThemeController themeController;
  final SupabaseClient? supabaseClient;
  final Future<void> Function()? onSignInAnotherAccount;
  final Future<void> Function()? onCreateAccount;

  @override
  Widget build(BuildContext context) {
    final user = supabaseClient?.auth.currentUser;
    final syncStatus = controller.syncStatus;
    final supportsWalletImport =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

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
                  key: const ValueKey('settings-account'),
                  leading: const Icon(FluentIcons.person_24_regular),
                  title: const Text('Conta pessoal'),
                  subtitle: Text(
                    user?.email ?? 'Dados armazenados neste aparelho',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => unawaited(
                    Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (context) => AccountSettingsPage(
                          supabaseClient: supabaseClient,
                          onSignInAnotherAccount: onSignInAnotherAccount,
                          onCreateAccount: onCreateAccount,
                        ),
                      ),
                    ),
                  ),
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
                  subtitle: Text(
                    supportsWalletImport
                        ? 'Detecta compras para você revisar antes de salvar.'
                        : 'Disponível somente no Android. No Windows, '
                              'registre a compra manualmente.',
                  ),
                  trailing: supportsWalletImport
                      ? const Icon(Icons.chevron_right)
                      : null,
                  onTap: supportsWalletImport
                      ? () {
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
                        }
                      : null,
                ),
                const Divider(height: 1),
                ListTile(
                  key: const ValueKey('settings-utility-expenses'),
                  leading: const Icon(Icons.water_drop_outlined),
                  title: const Text('Despesas Água/Luz'),
                  subtitle: const Text(
                    'Controle mensal separado. Não altera nenhum total financeiro.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    final scope = user?.id ?? 'local';
                    unawaited(
                      Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (context) => UtilityExpensesPage(
                            storageScope: scope,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _PixQrCodeCard(controller: controller),
          const SizedBox(height: 16),
          _ThemeModeCard(controller: themeController),
          const SizedBox(height: 16),
          _AppUpdateCard(controller: appUpdateController),
          const SizedBox(height: 24),
          _DeleteAllDataCard(
            controller: controller,
            onDelete: () => _deleteAllData(context),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllData(BuildContext context) async {
    final acknowledged = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          FluentIcons.warning_24_regular,
          color: Theme.of(dialogContext).colorScheme.error,
        ),
        title: const Text('Apagar todos os dados do FinFlow?'),
        content: const Text(
          'Receitas, despesas, cartões, faturas, compras, histórico, '
          'chaves Pix, QR Code e o controle de Água/Luz serão apagados. '
          'Quando a sincronização estiver ativa, a exclusão dos dados '
          'financeiros também será aplicada à sua conta e aos outros '
          'dispositivos. O tema e os arquivos necessários ao funcionamento '
          'do aplicativo serão preservados.\n\n'
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    if (acknowledged != true || !context.mounted) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _DeleteConfirmationDialog(),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    try {
      final utilityScope = supabaseClient?.auth.currentUser?.id ?? 'local';
      await controller.deleteAllData();
      await PurchaseRepository.clear();
      await UtilityExpensesRepository(scope: utilityScope).clearScope();
      await const NotificationPurchaseImportService().clearPending();
      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Todos os dados do FinFlow foram apagados.'),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível concluir a exclusão. Confira a conexão '
              'e tente novamente; os dados locais não foram apagados.',
            ),
          ),
        );
      }
    }
  }
}

class _PixQrCodeCard extends StatelessWidget {
  const _PixQrCodeCard({required this.controller});

  final FinancialMonthController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: const Icon(FluentIcons.qr_code_24_regular),
          title: const Text('QR Code Pix personalizado'),
          subtitle: Text(
            controller.pixQrCodeBytes == null
                ? 'Cadastre uma imagem PNG de 1000 × 1000 px.'
                : controller.pixSettings.qrCodeTitle ?? 'Imagem cadastrada',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => PixQrCodeDialog.show(context, controller: controller),
        ),
      ),
    );
  }
}

class _DeleteAllDataCard extends StatelessWidget {
  const _DeleteAllDataCard({required this.controller, required this.onDelete});

  final FinancialMonthController controller;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(FluentIcons.delete_24_regular, color: errorColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Apagar todos os dados',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Reinicie o FinFlow do zero. Duas confirmações serão exigidas.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: errorColor),
              onPressed: controller.isLoading ? null : onDelete,
              icon: const Icon(FluentIcons.delete_24_regular),
              label: const Text('Apagar meus dados do FinFlow'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteConfirmationDialog extends StatefulWidget {
  const _DeleteConfirmationDialog();

  @override
  State<_DeleteConfirmationDialog> createState() =>
      _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<_DeleteConfirmationDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _canDelete = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirmação final'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Digite APAGAR para confirmar a exclusão definitiva.'),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'Confirmação'),
              onChanged: (value) {
                setState(() => _canDelete = value.trim() == 'APAGAR');
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: _canDelete ? () => Navigator.pop(context, true) : null,
          child: const Text('Apagar definitivamente'),
        ),
      ],
    );
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
        final isWindows =
            !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

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
                          Text(_statusText(controller, isWindows: isWindows)),
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
                    key: ValueKey(
                      isWindows
                          ? 'windows-update-channel'
                          : 'android-update-channel',
                    ),
                    onPressed: controller.isBusy
                        ? null
                        : () => unawaited(controller.downloadAndInstall()),
                    icon: const Icon(Icons.download),
                    label: Text(
                      isWindows
                          ? 'Baixar, atualizar e reiniciar'
                          : controller.status ==
                                AppUpdateStatus.waitingForInstallPermission
                          ? 'Autorizar instalação'
                          : 'Baixar e instalar',
                    ),
                  )
                else
                  OutlinedButton.icon(
                    key: ValueKey(
                      isWindows
                          ? 'windows-update-channel'
                          : 'android-update-channel',
                    ),
                    onPressed: controller.isBusy
                        ? null
                        : () => unawaited(controller.checkForUpdates()),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Verificar atualizações'),
                  ),
                const SizedBox(height: 8),
                Text(
                  isWindows
                      ? 'O pacote .zip é validado e preparado antes de fechar. '
                            'Há backup e restauração automática se algo falhar.'
                      : 'O Android sempre pedirá sua confirmação antes de '
                            'instalar. O APK é validado por SHA-256.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _statusText(
    AppUpdateController controller, {
    required bool isWindows,
  }) {
    return switch (controller.status) {
      AppUpdateStatus.idle => 'Verifique se existe uma nova versão.',
      AppUpdateStatus.unsupported =>
        'Atualização dentro do app indisponível nesta plataforma.',
      AppUpdateStatus.checking => 'Verificando no GitHub...',
      AppUpdateStatus.upToDate => 'Você já está na versão mais recente.',
      AppUpdateStatus.available => 'Uma nova versão está disponível.',
      AppUpdateStatus.waitingForInstallPermission =>
        'Permita que o FinFlow instale apps e volte para continuar.',
      AppUpdateStatus.downloading =>
        isWindows
            ? 'Baixando e validando o pacote do Windows...'
            : 'Baixando e validando o APK...',
      AppUpdateStatus.openingInstaller =>
        isWindows
            ? 'Reiniciando o FinFlow para concluir a atualização...'
            : 'Confirme a atualização na tela do Android.',
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
