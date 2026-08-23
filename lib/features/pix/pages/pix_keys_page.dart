import 'dart:async';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../controllers/financial_month_controller.dart';
import '../../../models/pix_key.dart';
import '../widgets/pix_key_dialog.dart';
import '../widgets/pix_qr_code_dialog.dart';

class PixKeysPage extends StatelessWidget {
  const PixKeysPage({super.key, required this.controller});

  final FinancialMonthController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chaves Pix')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addKey(context),
        icon: const Icon(FluentIcons.add_24_regular),
        label: const Text('Adicionar chave'),
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final qrBytes = controller.pixQrCodeBytes;
          final keys = controller.pixKeys;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            children: [
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (qrBytes == null)
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            FluentIcons.qr_code_24_regular,
                            size: 42,
                          ),
                        )
                      else
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            qrBytes,
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                            semanticLabel: 'QR Code Pix personalizado',
                          ),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller.pixSettings.qrCodeTitle ??
                                  'QR Code Pix personalizado',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              qrBytes == null
                                  ? 'Cadastre uma imagem PNG 1000 × 1000 px em Configurações.'
                                  : 'Imagem sincronizada com sua conta FinFlow.',
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: () => PixQrCodeDialog.show(
                                context,
                                controller: controller,
                              ),
                              icon: const Icon(Icons.tune),
                              label: Text(
                                qrBytes == null ? 'Cadastrar' : 'Alterar',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Chaves cadastradas',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (keys.isEmpty)
                const Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: Icon(FluentIcons.key_24_regular),
                    title: Text('Nenhuma chave Pix cadastrada'),
                    subtitle: Text('Use “Adicionar chave” para começar.'),
                  ),
                )
              else
                ...keys.map(
                  (key) => _PixKeyCard(
                    key: ValueKey(key.id),
                    pixKey: key,
                    onEdit: () => _editKey(context, key),
                    onDelete: () => _deleteKey(context, key),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addKey(BuildContext context) async {
    final draft = await PixKeyDialog.show(context);
    if (draft == null) {
      return;
    }
    try {
      await controller.addPixKey(
        type: draft.type,
        value: draft.value,
        title: draft.title,
      );
    } catch (error) {
      if (context.mounted) {
        _showError(context, error);
      }
    }
  }

  Future<void> _editKey(BuildContext context, PixKey key) async {
    final draft = await PixKeyDialog.show(context, initialKey: key);
    if (draft == null) {
      return;
    }
    try {
      await controller.updatePixKey(
        key.copyWith(type: draft.type, value: draft.value, title: draft.title),
      );
    } catch (error) {
      if (context.mounted) {
        _showError(context, error);
      }
    }
  }

  Future<void> _deleteKey(BuildContext context, PixKey key) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir chave Pix?'),
        content: Text(
          'A chave “${key.title.isEmpty ? key.value : key.title}” será removida.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.removePixKey(key.id);
    }
  }

  void _showError(BuildContext context, Object error) {
    final message = error is ArgumentError
        ? error.message.toString()
        : 'Não foi possível salvar a chave Pix.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PixKeyCard extends StatelessWidget {
  const _PixKeyCard({
    super.key,
    required this.pixKey,
    required this.onEdit,
    required this.onDelete,
  });

  final PixKey pixKey;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(FluentIcons.key_24_regular),
        title: Text(pixKey.title.isEmpty ? pixKey.typeLabel : pixKey.title),
        subtitle: Text('${pixKey.typeLabel} • ${pixKey.value}'),
        onTap: onEdit,
        trailing: Wrap(
          spacing: 0,
          children: [
            IconButton(
              tooltip: 'Copiar chave',
              onPressed: () {
                unawaited(Clipboard.setData(ClipboardData(text: pixKey.value)));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chave Pix copiada.')),
                );
              },
              icon: const Icon(FluentIcons.copy_24_regular),
            ),
            IconButton(
              tooltip: 'Editar chave',
              onPressed: onEdit,
              icon: const Icon(FluentIcons.edit_24_regular),
            ),
            IconButton(
              tooltip: 'Excluir chave',
              onPressed: onDelete,
              icon: const Icon(FluentIcons.delete_24_regular),
            ),
          ],
        ),
      ),
    );
  }
}
