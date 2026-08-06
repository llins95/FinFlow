import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/app_update_controller.dart';
import '../controllers/financial_month_controller.dart';
import '../features/calendar/pages/calendar_page.dart';
import '../features/cards/pages/cards_page.dart';
import '../features/dashboard/pages/home_page.dart';
import '../features/history/pages/history_page.dart';
import '../features/purchase/pages/purchase_page.dart';
import '../features/settings/pages/settings_page.dart';
import '../services/app_update_service.dart';

class NavigationPage extends StatefulWidget {
  const NavigationPage({
    super.key,
    required this.controller,
    this.supabaseClient,
    this.appUpdateController,
  });

  final FinancialMonthController controller;
  final SupabaseClient? supabaseClient;
  final AppUpdateController? appUpdateController;

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage>
    with WidgetsBindingObserver {
  int currentIndex = 0;
  final Set<int> _visitedPages = <int>{0};
  late final AppUpdateController _appUpdateController;
  late final bool _ownsAppUpdateController;
  bool _updatePromptShown = false;

  static const items = [
    _NavigationItem(
      label: 'Início',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    _NavigationItem(
      label: 'Cartões',
      icon: Icons.credit_card_outlined,
      selectedIcon: Icons.credit_card,
    ),
    _NavigationItem(
      label: 'Compra',
      icon: Icons.add_circle_outline,
      selectedIcon: Icons.add_circle,
    ),
    _NavigationItem(
      label: 'Histórico',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
    ),
    _NavigationItem(
      label: 'Parcelas',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
    ),
    _NavigationItem(
      label: 'Mais',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _ownsAppUpdateController = widget.appUpdateController == null;
    _appUpdateController =
        widget.appUpdateController ?? AppUpdateController(AppUpdateService());
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_checkForUpdatesAtStartup());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_appUpdateController.handleAppResumed());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
                    child: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      child: const Icon(Icons.account_balance_wallet),
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
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
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
      4 => CalendarPage(controller: widget.controller),
      5 => SettingsPage(
          controller: widget.controller,
          appUpdateController: _appUpdateController,
          supabaseClient: widget.supabaseClient,
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
