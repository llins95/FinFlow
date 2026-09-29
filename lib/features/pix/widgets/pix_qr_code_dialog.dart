import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../controllers/financial_month_controller.dart';
import '../../../models/pix_key.dart';
import '../../../services/pix_qr_code_service.dart';

const String _legacyQuickPixKeyTitle = '__finflow_quick_pix_key__';

class PixQrCodeDialog extends StatefulWidget {
  const PixQrCodeDialog({
    super.key,
    required this.controller,
    this.initialKey,
    this.legacyTitle,
    this.legacyBytes,
    this.legacyQuickKey,
    this.service = const PixQrCodeService(),
  });

  final FinancialMonthController controller;
  final PixKey? initialKey;
  final String? legacyTitle;
  final Uint8List? legacyBytes;
  final PixKey? legacyQuickKey;
  final PixQrCodeService service;

  static Future<void> show(
    BuildContext context, {
    required FinancialMonthController controller,
    PixKey? initialKey,
    String? legacyTitle,
    Uint8List? legacyBytes,
    PixKey? legacyQuickKey,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => PixQrCodeDialog(
        controller: controller,
        initialKey: initialKey,
        legacyTitle: legacyTitle,
        legacyBytes: legacyBytes,
        legacyQuickKey: legacyQuickKey,
      ),
    );
  }

  @override
  State<PixQrCodeDialog> createState() => _PixQrCodeDialogState();
}

class _PixQrCodeDialogState extends State<PixQrCodeDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _keyController;
  Uint8List? _bytes;
  String? _error;
  bool _isBusy = false;

  bool get _isLegacy => widget.initialKey == null && widget.legacyBytes != null;
  bool get _isEditing => widget.initialKey != null || _isLegacy;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initialKey?.title ?? widget.legacyTitle ?? '',
    );
    _keyController = TextEditingController(
      text: widget.initialKey?.value ?? widget.legacyQuickKey?.value ?? '',
    );
    _bytes = widget.initialKey?.qrCodeBytes ?? widget.legacyBytes;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'QR Code Pix personalizado' : 'Adicionar Pix'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Cadastre o banco, a imagem do QR Code e a mesma chave Pix por escrito. '
                'O PNG deve ter exatamente 1000 × 1000 px.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título / Banco',
                  hintText: 'Ex.: PicPay, Nubank ou Caixa',
                ),
                maxLength: 80,
              ),
              if (_bytes != null) ...[
                const SizedBox(height: 8),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _bytes!,
                      width: 220,
                      height: 220,
                      fit: BoxFit.cover,
                      semanticLabel: 'Prévia do QR Code Pix',
                    ),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _isBusy ? null : _pickImage,
                icon: const Icon(Icons.image_outlined),
                label: Text(
                  _bytes == null ? 'Selecionar PNG' : 'Substituir PNG',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _keyController,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Chave Pix',
                  hintText: 'CPF, celular, e-mail ou chave aleatória',
                  prefixIcon: Icon(Icons.key_outlined),
                ),
                onSubmitted: (_) => _save(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (_isEditing)
          TextButton(
            onPressed: _isBusy ? null : _remove,
            child: const Text('Remover'),
          ),
        TextButton(
          onPressed: _isBusy ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isBusy || _bytes == null ? null : _save,
          child: _isBusy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      final bytes = await widget.service.pickAndValidate();
      if (bytes != null && mounted) {
        setState(() => _bytes = bytes);
      }
    } on PixQrCodeValidationException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível selecionar a imagem.');
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final value = _keyController.text.trim();
    final bytes = _bytes;

    if (title.isEmpty) {
      setState(() => _error = 'Informe o nome do banco.');
      return;
    }
    if (bytes == null) {
      setState(() => _error = 'Selecione o PNG do QR Code.');
      return;
    }
    if (value.isEmpty) {
      setState(() => _error = 'Informe a chave Pix por escrito.');
      return;
    }

    setState(() {
      _isBusy = true;
      _error = null;
    });

    try {
      final encodedQr = base64Encode(bytes);
      final initial = widget.initialKey;

      if (initial != null) {
        await widget.controller.updatePixKey(
          initial.copyWith(
            value: value,
            title: title,
            qrCodePngBase64: encodedQr,
          ),
        );
      } else if (_isLegacy && widget.legacyQuickKey != null) {
        final quickKey = widget.legacyQuickKey!;
        await widget.controller.updatePixKey(
          quickKey.copyWith(
            value: value,
            title: title,
            qrCodePngBase64: encodedQr,
          ),
        );
        await widget.controller.removePixQrCode();
      } else {
        PixKey? existing;
        for (final key in widget.controller.pixKeys) {
          if (key.value.toLowerCase() == value.toLowerCase()) {
            existing = key;
            break;
          }
        }

        if (existing != null) {
          await widget.controller.updatePixKey(
            existing.copyWith(
              title: title,
              qrCodePngBase64: encodedQr,
            ),
          );
        } else {
          await widget.controller.addPixKey(
            type: PixKeyType.random,
            value: value,
            title: title,
          );
          final created = widget.controller.pixKeys.firstWhere(
            (key) => key.value.toLowerCase() == value.toLowerCase(),
          );
          await widget.controller.updatePixKey(
            created.copyWith(qrCodePngBase64: encodedQr),
          );
        }

        if (_isLegacy) {
          await widget.controller.removePixQrCode();
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } on ArgumentError catch (error) {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _error = error.message.toString();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _error = 'Não foi possível salvar este Pix.';
        });
      }
    }
  }

  Future<void> _remove() async {
    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      final initial = widget.initialKey;
      if (initial != null) {
        await widget.controller.removePixKey(initial.id);
      } else if (_isLegacy) {
        await widget.controller.removePixQrCode();
        final quickKey = widget.legacyQuickKey;
        if (quickKey != null && quickKey.title == _legacyQuickPixKeyTitle) {
          await widget.controller.removePixKey(quickKey.id);
        }
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _error = 'Não foi possível remover este Pix.';
        });
      }
    }
  }
}
