import 'dart:async';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../controllers/financial_month_controller.dart';
import '../../../models/pix_key.dart';
import '../widgets/pix_qr_code_dialog.dart';

const String _legacyQuickPixKeyTitle = '__finflow_quick_pix_key__';

class PixKeysPage extends StatelessWidget {
  const PixKeysPage({super.key, required this.controller});

  final FinancialMonthController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chaves Pix')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => PixQrCodeDialog.show(
          context,
          controller: controller,
        ),
        icon: const Icon(FluentIcons.add_24_regular),
        label: const Text('Adicionar Pix'),
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final bankKeys = controller.pixKeys
              .where((key) => key.qrCodeBytes != null)
              .toList(growable: false);
          final legacyBytes = controller.pixQrCodeBytes;
          final legacyQuickKey = _findLegacyQuickKey(controller.pixKeys);
          final hasAnyPix = bankKeys.isNotEmpty || legacyBytes != null;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            children: [
              if (!hasAnyPix)
                const Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(FluentIcons.qr_code_24_regular, size: 34),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Nenhum Pix cadastrado'),
                              SizedBox(height: 4),
                              Text(
                                'Use “Adicionar Pix” para cadastrar banco, QR Code e chave Pix juntos.',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (legacyBytes != null)
                _PixBankCard(
                  title:
                      controller.pixSettings.qrCodeTitle?.trim().isNotEmpty ==
                          true
                      ? controller.pixSettings.qrCodeTitle!.trim()
                      : 'QR Code Pix',
                  pixValue: legacyQuickKey?.value ?? '',
                  qrBytes: legacyBytes,
                  onCopy: legacyQuickKey == null
                      ? null
                      : () => _copyPixKey(context, legacyQuickKey.value),
                  onEdit: () => PixQrCodeDialog.show(
                    context,
                    controller: controller,
                    legacyTitle: controller.pixSettings.qrCodeTitle,
                    legacyBytes: legacyBytes,
                    legacyQuickKey: legacyQuickKey,
                  ),
                  onQrTap: () => _showQrCodeFullScreen(
                    context,
                    title:
                        controller.pixSettings.qrCodeTitle ?? 'QR Code Pix',
                    qrBytes: legacyBytes,
                  ),
                ),
              ...bankKeys.map((key) {
                final bytes = key.qrCodeBytes!;
                return _PixBankCard(
                  key: ValueKey(key.id),
                  title: key.title.trim().isEmpty ? 'Pix' : key.title.trim(),
                  pixValue: key.value,
                  qrBytes: bytes,
                  onCopy: () => _copyPixKey(context, key.value),
                  onEdit: () => PixQrCodeDialog.show(
                    context,
                    controller: controller,
                    initialKey: key,
                  ),
                  onQrTap: () => _showQrCodeFullScreen(
                    context,
                    title: key.title.trim().isEmpty ? 'QR Code Pix' : key.title,
                    qrBytes: bytes,
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  PixKey? _findLegacyQuickKey(Iterable<PixKey> keys) {
    for (final key in keys) {
      if (key.title == _legacyQuickPixKeyTitle) {
        return key;
      }
    }
    return null;
  }

  void _copyPixKey(BuildContext context, String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return;
    }
    unawaited(Clipboard.setData(ClipboardData(text: normalized)));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chave Pix copiada.')),
    );
  }

  Future<void> _showQrCodeFullScreen(
    BuildContext context, {
    required String title,
    required Uint8List qrBytes,
  }) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (fullScreenContext) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: Text(title),
          ),
          body: SafeArea(
            child: Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 5,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Image.memory(
                    qrBytes,
                    fit: BoxFit.contain,
                    semanticLabel: 'QR Code Pix ampliado de $title',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PixBankCard extends StatelessWidget {
  const _PixBankCard({
    super.key,
    required this.title,
    required this.pixValue,
    required this.qrBytes,
    required this.onCopy,
    required this.onEdit,
    required this.onQrTap,
  });

  final String title;
  final String pixValue;
  final Uint8List qrBytes;
  final VoidCallback? onCopy;
  final VoidCallback onEdit;
  final VoidCallback onQrTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasKey = pixValue.trim().isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Tooltip(
              message: 'Toque para ampliar',
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onQrTap,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    qrBytes,
                    width: 116,
                    height: 116,
                    fit: BoxFit.cover,
                    semanticLabel: 'QR Code Pix de $title. Toque para ampliar.',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          hasKey
                              ? pixValue
                              : 'Adicione a chave Pix em “Alterar”.',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            color: hasKey
                                ? null
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonalIcon(
                        onPressed: onCopy,
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        icon: const Icon(
                          FluentIcons.copy_20_regular,
                          size: 18,
                        ),
                        label: const Text('Copiar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.tune),
                    label: const Text('Alterar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
