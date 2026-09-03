import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/notification_purchase_candidate.dart';
import '../../../services/notification_purchase_import_service.dart';

class NotificationImportPage extends StatefulWidget {
  const NotificationImportPage({
    super.key,
    this.ignoredCandidateIds = const <String>{},
    this.service = const NotificationPurchaseImportService(),
  });

  final Set<String> ignoredCandidateIds;
  final NotificationPurchaseImportService service;

  @override
  State<NotificationImportPage> createState() => _NotificationImportPageState();
}

class _NotificationImportPageState extends State<NotificationImportPage>
    with WidgetsBindingObserver {
  final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');

  bool _isLoading = true;
  bool _isSupported = false;
  bool _hasAccess = false;
  String? _error;
  List<NotificationPurchaseCandidate> _candidates = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final supported = await widget.service.isSupported();
      final hasAccess =
          supported && await widget.service.isAccessGranted();
      final pending = hasAccess
          ? await widget.service.loadPending()
          : const <NotificationPurchaseCandidate>[];

      if (!mounted) {
        return;
      }

      setState(() {
        _isSupported = supported;
        _hasAccess = hasAccess;
        _candidates = pending
            .where(
              (candidate) =>
                  !widget.ignoredCandidateIds.contains(candidate.id),
            )
            .toList(growable: false);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openSettings() async {
    final opened = await widget.service.openAccessSettings();
    if (!opened && mounted) {
      _showMessage('Não foi possível abrir as configurações do Android.');
    }
  }

  Future<void> _discard(NotificationPurchaseCandidate candidate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Descartar sugestão?'),
        content: Text(
          'A notificação de “${candidate.description}” será removida '
          'somente deste aparelho.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final removed = await widget.service.dismiss(candidate.id);
    if (!mounted) {
      return;
    }
    if (!removed) {
      _showMessage('Não foi possível descartar esta sugestão.');
      return;
    }
    await _load();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compras detectadas'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : () => unawaited(_load()),
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _MessagePanel(
        icon: Icons.error_outline,
        title: 'Não foi possível ler as notificações',
        message: _error!,
        actionLabel: 'Tentar novamente',
        onAction: () => unawaited(_load()),
      );
    }

    if (!_isSupported) {
      return const _MessagePanel(
        icon: Icons.phone_android_outlined,
        title: 'Disponível somente no Android',
        message:
            'No Windows, registre a compra manualmente. As compras '
            'confirmadas no Android continuarão sincronizando normalmente.',
      );
    }

    if (!_hasAccess) {
      return _MessagePanel(
        icon: Icons.notifications_off_outlined,
        title: 'Ative o acesso às notificações',
        message:
            'O Android abrirá uma tela do sistema. Autorize o FinFlow para '
            'detectar alertas de compra da Carteira do Google. Essa permissão '
            'pode ser retirada a qualquer momento.',
        actionLabel: 'Abrir configurações',
        onAction: () => unawaited(_openSettings()),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          const Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: Icon(Icons.privacy_tip_outlined),
              title: Text('Você confirma antes de salvar'),
              subtitle: Text(
                'O texto bruto fica somente neste aparelho. Apenas a compra '
                'revisada entra no FinFlow e na sincronização.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_candidates.isEmpty)
            const Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.notifications_none, size: 48),
                    SizedBox(height: 12),
                    Text(
                      'Nenhuma compra nova detectada',
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Após um pagamento pela Carteira do Google, volte aqui '
                      'e deslize a tela para atualizar.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Text(
              '${_candidates.length} '
              '${_candidates.length == 1 ? 'sugestão' : 'sugestões'}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final candidate in _candidates)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.wallet_outlined),
                  ),
                  title: Text(candidate.description),
                  subtitle: Text(_dateFormat.format(candidate.occurredAt)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _currency.format(candidate.amountInCents / 100),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        key: ValueKey(
                          'confirm-wallet-purchase-${candidate.id}',
                        ),
                        tooltip: 'Confirmar compra',
                        onPressed: () => Navigator.pop(context, candidate),
                        icon: const Icon(Icons.check_circle_outline),
                      ),
                      IconButton(
                        tooltip: 'Descartar',
                        onPressed: () => unawaited(_discard(candidate)),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                  onTap: () => Navigator.pop(context, candidate),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(message, textAlign: TextAlign.center),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: onAction,
                      icon: const Icon(Icons.settings_outlined),
                      label: Text(actionLabel!),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
