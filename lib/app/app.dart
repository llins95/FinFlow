import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/app_update_controller.dart';
import '../controllers/financial_month_controller.dart';
import '../features/auth/pages/auth_page.dart';
import '../models/purchase.dart';
import '../services/supabase_financial_month_store.dart';
import '../shared/financial_month_repository.dart';
import 'app_theme.dart';
import 'navigation_page.dart';

class FinFlowApp extends StatefulWidget {
  const FinFlowApp({
    super.key,
    this.financialMonthController,
    this.supabaseClient,
    this.legacyPurchases = const [],
    this.onLegacyPurchasesImported,
    this.appUpdateController,
  });

  final FinancialMonthController? financialMonthController;
  final SupabaseClient? supabaseClient;
  final List<Purchase> legacyPurchases;
  final Future<void> Function()? onLegacyPurchasesImported;
  final AppUpdateController? appUpdateController;

  @override
  State<FinFlowApp> createState() => _FinFlowAppState();
}

class _FinFlowAppState extends State<FinFlowApp> {
  FinancialMonthController? _controller;
  StreamSubscription<AuthState>? _authSubscription;

  bool _isStarting = true;
  bool _sessionHandled = false;
  String? _activeUserId;
  String? _startupError;
  int _sessionGeneration = 0;
  bool _legacyImportCompleted = false;

  bool get _usesInjectedController =>
      widget.financialMonthController != null;

  @override
  void initState() {
    super.initState();

    if (_usesInjectedController) {
      _controller = widget.financialMonthController;
      unawaited(_initializeInjectedController());
      return;
    }

    final client = widget.supabaseClient;
    if (client == null) {
      _isStarting = false;
      return;
    }

    _authSubscription = client.auth.onAuthStateChange.listen(
      (authState) => unawaited(_handleSession(authState.session)),
    );
    unawaited(_handleSession(client.auth.currentSession));
  }

  Future<void> _initializeInjectedController() async {
    try {
      await _controller!.initialize();
      await _importLegacyPurchases(_controller!);
    } catch (error) {
      _startupError = error.toString();
    }

    if (mounted) {
      setState(() {
        _isStarting = false;
      });
    }
  }

  Future<void> _handleSession(Session? session) async {
    final userId = session?.user.id;

    if (_sessionHandled &&
        userId == _activeUserId &&
        (_controller != null || _isStarting)) {
      return;
    }

    _sessionHandled = true;
    _activeUserId = userId;
    final generation = ++_sessionGeneration;

    final oldController = _controller;
    _controller = null;
    oldController?.dispose();

    if (mounted) {
      setState(() {
        _isStarting = session != null;
        _startupError = null;
      });
    }

    if (session == null) {
      return;
    }

    final client = widget.supabaseClient!;
    final controller = FinancialMonthController(
      SupabaseFinancialMonthStore(
        client: client,
        localStore: HiveFinancialMonthStore(),
      ),
    );

    try {
      await controller.initialize();
      await _importLegacyPurchases(controller);

      if (!mounted || generation != _sessionGeneration) {
        controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _isStarting = false;
      });
    } catch (error) {
      controller.dispose();

      if (!mounted || generation != _sessionGeneration) {
        return;
      }

      setState(() {
        _startupError = error.toString();
        _isStarting = false;
      });
    }
  }

  Future<void> _importLegacyPurchases(
    FinancialMonthController controller,
  ) async {
    if (_legacyImportCompleted || widget.legacyPurchases.isEmpty) {
      return;
    }

    final processed = await controller.importLegacyPurchases(
      widget.legacyPurchases,
    );
    if (processed != widget.legacyPurchases.length) {
      return;
    }

    await widget.onLegacyPurchasesImported?.call();
    _legacyImportCompleted = true;
  }

  @override
  void dispose() {
    unawaited(_authSubscription?.cancel());
    if (!_usesInjectedController) {
      _controller?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (_startupError != null) {
      return _StartupErrorPage(
        message: _startupError!,
        onRetry: widget.supabaseClient == null
            ? null
            : () => unawaited(
                _handleSession(widget.supabaseClient!.auth.currentSession),
              ),
      );
    }

    if (_isStarting) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_usesInjectedController) {
      return NavigationPage(
        controller: _controller!,
        appUpdateController: widget.appUpdateController,
      );
    }

    final client = widget.supabaseClient;
    if (client == null) {
      return const _SupabaseConfigurationPage();
    }

    final controller = _controller;
    if (controller == null) {
      return AuthPage(client: client);
    }

    return NavigationPage(
      controller: controller,
      supabaseClient: client,
      appUpdateController: widget.appUpdateController,
    );
  }
}

class _SupabaseConfigurationPage extends StatelessWidget {
  const _SupabaseConfigurationPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurar FinFlow')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 56),
                    const SizedBox(height: 16),
                    Text(
                      'Supabase não configurado',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Execute o aplicativo informando SUPABASE_URL e '
                      'SUPABASE_PUBLISHABLE_KEY com --dart-define. '
                      'As instruções estão no README.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StartupErrorPage extends StatelessWidget {
  const _StartupErrorPage({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FinFlow')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 56),
                    const SizedBox(height: 16),
                    Text(
                      'Não foi possível iniciar',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(message, textAlign: TextAlign.center),
                    if (onRetry != null) ...[
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar novamente'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
