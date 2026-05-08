import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../invoices/invoices_screen.dart';
import '../pos/pos_screen.dart';
import '../products/products_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';
import 'dashboard_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    required this.apiClient,
    required this.onSignedOut,
    super.key,
  });

  final ApiClient apiClient;
  final VoidCallback onSignedOut;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(apiClient: widget.apiClient),
      PosScreen(apiClient: widget.apiClient),
      ProductsScreen(apiClient: widget.apiClient),
      InvoicesScreen(apiClient: widget.apiClient),
      ReportsScreen(apiClient: widget.apiClient),
      SettingsScreen(apiClient: widget.apiClient, onSignedOut: widget.onSignedOut),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.point_of_sale_outlined), selectedIcon: Icon(Icons.point_of_sale), label: 'POS'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Products'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Invoices'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Reports'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
