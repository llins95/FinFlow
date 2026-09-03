import 'package:flutter/material.dart';

import '../../../models/pix_key.dart';

class PixKeyDraft {
  const PixKeyDraft({
    required this.type,
    required this.value,
    required this.title,
  });

  final PixKeyType type;
  final String value;
  final String title;
}

class PixKeyDialog extends StatefulWidget {
  const PixKeyDialog({super.key, this.initialKey});

  final PixKey? initialKey;

  static Future<PixKeyDraft?> show(BuildContext context, {PixKey? initialKey}) {
    return showDialog<PixKeyDraft>(
      context: context,
      builder: (_) => PixKeyDialog(initialKey: initialKey),
    );
  }

  @override
  State<PixKeyDialog> createState() => _PixKeyDialogState();
}

class _PixKeyDialogState extends State<PixKeyDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _valueController;
  late PixKeyType _type;

  @override
  void initState() {
    super.initState();
    _type = widget.initialKey?.type ?? PixKeyType.cpf;
    _titleController = TextEditingController(
      text: widget.initialKey?.title ?? '',
    );
    _valueController = TextEditingController(
      text: widget.initialKey?.value ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialKey == null ? 'Adicionar chave Pix' : 'Editar chave Pix',
      ),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<PixKeyType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Tipo da chave'),
                items: PixKeyType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(_typeLabel(type)),
                      ),
                    )
                    .toList(),
                onChanged: (type) {
                  if (type != null) {
                    setState(() => _type = type);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _valueController,
                autofocus: widget.initialKey == null,
                decoration: InputDecoration(
                  labelText: 'Chave Pix',
                  hintText: _hintFor(_type),
                ),
                validator: (value) => _validateKey(_type, value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título (opcional)',
                  hintText: 'Ex.: Conta principal',
                ),
                maxLength: 60,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Salvar')),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.pop(
      context,
      PixKeyDraft(
        type: _type,
        value: _valueController.text.trim(),
        title: _titleController.text.trim(),
      ),
    );
  }

  static String? _validateKey(PixKeyType type, String? rawValue) {
    final value = rawValue?.trim() ?? '';
    if (value.isEmpty) {
      return 'Informe a chave Pix.';
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return switch (type) {
      PixKeyType.cpf when digits.length != 11 =>
        'Informe um CPF com 11 dígitos.',
      PixKeyType.cnpj when digits.length != 14 =>
        'Informe um CNPJ com 14 dígitos.',
      PixKeyType.phone when digits.length < 10 || digits.length > 13 =>
        'Informe o celular com DDD e, se necessário, código do país.',
      PixKeyType.email
          when !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value) =>
        'Informe um e-mail válido.',
      PixKeyType.random when value.length < 10 =>
        'Informe uma chave aleatória válida.',
      _ => null,
    };
  }

  static String _hintFor(PixKeyType type) => switch (type) {
    PixKeyType.cpf => '000.000.000-00',
    PixKeyType.cnpj => '00.000.000/0000-00',
    PixKeyType.phone => '+55 11 99999-9999',
    PixKeyType.email => 'nome@exemplo.com',
    PixKeyType.random => 'Chave EVP',
  };

  static String _typeLabel(PixKeyType type) => switch (type) {
    PixKeyType.cpf => 'CPF',
    PixKeyType.cnpj => 'CNPJ',
    PixKeyType.phone => 'Celular',
    PixKeyType.email => 'E-mail',
    PixKeyType.random => 'Chave aleatória',
  };
}
