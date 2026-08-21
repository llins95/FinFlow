import 'package:flutter/material.dart';

import '../../../shared/finance_repository.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final current = FinanceRepository.settingsBox.get('theme', defaultValue: 'system') as String;
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Aparência', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'light', icon: Icon(Icons.light_mode), label: Text('Claro')),
            ButtonSegment(value: 'dark', icon: Icon(Icons.dark_mode), label: Text('Escuro')),
            ButtonSegment(value: 'system', icon: Icon(Icons.brightness_auto), label: Text('Sistema')),
          ],
          selected: {current},
          onSelectionChanged: (value) => FinanceRepository.settingsBox.put('theme', value.first),
        ),
        const SizedBox(height: 24),
        const ListTile(leading: Icon(Icons.cloud_off_outlined), title: Text('Sincronização'), subtitle: Text('Armazenamento local ativo. Supabase não está configurado neste projeto.')),
        ListTile(leading: const Icon(Icons.system_update), title: const Text('Verificar atualizações'), subtitle: const Text('Versão 1.0.0'), onTap: () => showDialog<void>(context: context, builder: (context) => AlertDialog(title: const Text('Atualizações'), content: const Text('Use a Microsoft Store no Windows ou a loja de aplicativos no Android para obter atualizações assinadas com segurança.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))]))),
        const AboutListTile(icon: Icon(Icons.info_outline), applicationName: 'FinFlow', applicationVersion: '1.0.0'),
      ]),
    );
  }
}
