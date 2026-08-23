import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../controllers/financial_month_controller.dart';
import '../../../services/pix_qr_code_service.dart';

class PixQrCodeDialog extends StatefulWidget {
  const PixQrCodeDialog({
    super.key,
    required this.controller,
    this.service = const PixQrCodeService(),
  });

  final FinancialMonthController controller;
  final PixQrCodeService service;

  static Future<void> show(
    BuildContext context, {
    required FinancialMonthController controller,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => PixQrCodeDialog(controller: controller),
    );
  }

  @override
  State<PixQrCodeDialog> createState() => _PixQrCodeDialogState();
}

class _PixQrCodeDialogState extends State<PixQrCodeDialog> {
  late final TextEditingController _titleController;
  Uint8List? _bytes;
  String? _error;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.controller.pixSettings.qrCodeTitle ?? '',
    );
    _bytes = widget.controller.pixQrCodeBytes;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('QR Code Pix personalizado'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Selecione um arquivo PNG com exatamente 1000 × 1000 px. '
                'A imagem será sincronizada com sua conta.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  hintText: 'Ex.: Pix da conta principal',
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
            ],
          ),
        ),
      ),
      actions: [
        if (widget.controller.pixQrCodeBytes != null)
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
    if (title.isEmpty) {
      setState(() => _error = 'Informe um título para o QR Code.');
      return;
    }
    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      await widget.controller.savePixQrCode(title: title, pngBytes: _bytes!);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _error = 'Não foi possível salvar o QR Code.';
        });
      }
    }
  }

  Future<void> _remove() async {
    setState(() => _isBusy = true);
    try {
      await widget.controller.removePixQrCode();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _error = 'Não foi possível remover o QR Code.';
        });
      }
    }
  }
}
