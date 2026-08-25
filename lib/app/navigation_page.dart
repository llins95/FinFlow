import 'dart:async';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/app_update_controller.dart';
import '../controllers/financial_month_controller.dart';
import '../controllers/theme_controller.dart';
import '../features/cards/pages/cards_page.dart';
import '../features/dashboard/pages/home_page.dart';
import '../features/history/pages/history_page.dart';
import '../features/pix/pages/pix_keys_page.dart';
import '../features/purchase/pages/purchase_page.dart';
import '../features/settings/pages/settings_page.dart';
import '../services/app_update_service.dart';
import '../services/billing_notification_scheduler.dart';

class NavigationPage extends StatefulWidget {
  const NavigationPage({
    super.key,
    required this.controller,
    required this.themeController,
    this.supabaseClient,
    this.appUpdateController,
    this.onSignInAnotherAccount,
    this.onCreateAccount,
  });

  final FinancialMonthController controller;
  final ThemeController themeController;
  final SupabaseClient? supabaseClient;
  final AppUpdateController? appUpdateController;
  final Future<void> Function()? onSignInAnotherAccount;
  final Future<void> Function()? onCreateAccount;

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage>
    with WidgetsBindingObserver {
  int currentIndex = 0;
  final Set<int> _visitedPages = <int>{0};
  late final AppUpdateController _appUpdateController;
  late final bool _ownsAppUpdateController;
  late final BillingNotificationScheduler _billingNotificationScheduler;
  Timer? _billingReminderTimer;
  bool _updatePromptShown = false;

  static const items = [
    _NavigationItem(
      label: 'Início',
      icon: FluentIcons.home_24_regular,
      selectedIcon: FluentIcons.home_24_filled,
    ),
    _NavigationItem(
      label: 'Cartões',
      icon: FluentIcons.wallet_credit_card_24_regular,
      selectedIcon: FluentIcons.wallet_credit_card_24_filled,
    ),
    _NavigationItem(
      label: 'Compra',
      icon: FluentIcons.add_circle_24_regular,
      selectedIcon: FluentIcons.add_circle_24_filled,
    ),
    _NavigationItem(
      label: 'Histórico',
      icon: FluentIcons.receipt_24_regular,
      selectedIcon: FluentIcons.receipt_24_filled,
    ),
    _NavigationItem(
      label: 'Chaves Pix',
      icon: FluentIcons.qr_code_24_regular,
      selectedIcon: FluentIcons.qr_code_24_filled,
    ),
    _NavigationItem(
      label: 'Mais',
      icon: FluentIcons.settings_24_regular,
      selectedIcon: FluentIcons.settings_24_filled,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _ownsAppUpdateController = widget.appUpdateController == null;
    _appUpdateController =
        widget.appUpdateController ?? AppUpdateController(AppUpdateService());
    _billingNotificationScheduler = BillingNotificationScheduler();
    widget.controller.addListener(_queueBillingReminderSync);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_checkForUpdatesAtStartup());
      unawaited(_syncBillingReminders());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_appUpdateController.handleAppResumed());
      unawaited(_syncBillingReminders());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_queueBillingReminderSync);
    _billingReminderTimer?.cancel();
    if (_ownsAppUpdateController) {
      _appUpdateController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = List<Widget>.generate(
      items.length,
      (index) => _visitedPages.contains(index)
          ? _buildPage(index)
          : const SizedBox.shrink(),
    );
    final page = IndexedStack(index: currentIndex, children: pages);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          final extended = constraints.maxWidth >= 1180;
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  extended: extended,
                  labelType: extended ? null : NavigationRailLabelType.all,
                  selectedIndex: currentIndex,
                  onDestinationSelected: _selectPage,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/branding/finflow-icon-256.png',
                        key: const ValueKey('desktop-finflow-icon'),
                        width: 44,
                        height: 44,
                        filterQuality: FilterQuality.high,
                        semanticLabel: 'FinFlow',
                      ),
                    ),
                  ),
                  destinations: items
                      .map(
                        (item) => NavigationRailDestination(
                          icon: Icon(item.icon),
                          selectedIcon: Icon(item.selectedIcon),
                          label: Text(item.label),
                        ),
                      )
                      .toList(),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: page),
              ],
            ),
          );
        }

        return Scaffold(
          body: page,
          bottomNavigationBar: NavigationBar(
            selectedIndex: currentIndex,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: _selectPage,
            destinations: items
                .map(
                  (item) => NavigationDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: item.label,
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildPage(int index) {
    return switch (index) {
      0 => HomePage(controller: widget.controller),
      1 => CardsPage(controller: widget.controller),
      2 => PurchasePage(controller: widget.controller),
      3 => HistoryPage(
        controller: widget.controller,
        onOpenMonth: (month) async {
          final opened = await widget.controller.goToMonth(
            month.year,
            month.month,
          );
          if (opened && mounted) {
            _selectPage(0);
          }
        },
      ),
      4 => PixKeysPage(controller: widget.controller),
      5 => SettingsPage(
        controller: widget.controller,
        themeController: widget.themeController,
        appUpdateController: _appUpdateController,
        supabaseClient: widget.supabaseClient,
        onSignInAnotherAccount: widget.onSignInAnotherAccount,
        onCreateAccount: widget.onCreateAccount,
      ),
      _ => const SizedBox.shrink(),
    };
  }

  Future<void> _checkForUpdatesAtStartup() async {
    final hasUpdate = await _appUpdateController.checkForUpdates();
    if (!hasUpdate || !mounted || _updatePromptShown) {
      return;
    }
    _updatePromptShown = true;

    final update = _appUpdateController.availableUpdate!;
    final shouldInstall = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.system_update_alt),
        title: const Text('Atualização disponível'),
        content: Text(
          'A versão ${update.versionName} do FinFlow está disponível. '
          'Deseja baixar e instalar agora?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Depois'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.download),
            label: const Text('Baixar e instalar'),
          ),
        ],
      ),
    );

    if (shouldInstall == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparando a atualização...')),
      );
      await _appUpdateController.downloadAndInstall();
    }
  }

  void _queueBillingReminderSync() {
    _billingReminderTimer?.cancel();
    _billingReminderTimer = Timer(
      const Duration(milliseconds: 500),
      () => unawaited(_syncBillingReminders()),
    );
  }

  Future<void> _syncBillingReminders() async {
    if (!widget.controller.isInitialized) {
      return;
    }
    final now = DateTime.now();
    final actualMonth =
        widget.controller.financialMonthForDate(now) ??
        widget.controller.currentMonth;
    await _billingNotificationScheduler.sync(
      currentMonth: actualMonth,
      now: now,
    );
  }

  void _selectPage(int index) {
    setState(() {
      currentIndex = index;
      _visitedPages.add(index);
    });
  }
}

class _NavigationItem {
  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
