import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mais')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: const [
                ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('Conta pessoal'),
                  subtitle: Text('Uso individual de Murilo'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.cloud_off_outlined),
                  title: Text('Dados locais'),
                  subtitle: Text(
                    'A sincronização com Supabase será a próxima etapa.',
                  ),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.security_outlined),
                  title: Text('Segurança'),
                  subtitle: Text(
                    'O FinFlow não armazena número completo nem CVV de cartão.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
