import 'package:flutter/material.dart';

import '../controllers/financial_month_controller.dart';
import '../features/calendar/pages/calendar_page.dart';
import '../features/cards/pages/cards_page.dart';
import '../features/dashboard/pages/home_page.dart';
import '../features/history/pages/history_page.dart';
import '../features/purchase/pages/purchase_page.dart';
import '../features/settings/pages/settings_page.dart';

class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key, required this.controller});

  final FinancialMonthController controller;

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  int currentIndex = 0;

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
  Widget build(BuildContext context) {
    final pages = [
      HomePage(controller: widget.controller),
      CardsPage(controller: widget.controller),
      const PurchasePage(),
      const HistoryPage(),
      const CalendarPage(),
      const SettingsPage(),
    ];
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

  void _selectPage(int index) {
    setState(() {
      currentIndex = index;
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
