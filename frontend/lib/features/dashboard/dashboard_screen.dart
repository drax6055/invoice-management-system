import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_client.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_section.dart';
import '../../models/order.dart';
import '../../models/report.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({required this.apiClient, super.key});

  final ApiClient apiClient;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<_DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DashboardData> _load() async {
    final sales = await widget.apiClient.get('/reports/sales/daily');
    final orders = await widget.apiClient.get('/orders', query: {'limit': '5'});
    final lowStock = await widget.apiClient.get('/stock/low');

    return _DashboardData(
      report: DailySalesReport.fromJson(sales['data'] as Map<String, dynamic>),
      recentOrders: ((orders['data']['items'] as List?) ?? [])
          .map((item) => OrderSummary.fromJson(item as Map<String, dynamic>))
          .toList(),
      lowStockCount: ((lowStock['data'] as List?) ?? []).length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _future = _load();
        });
        await _future;
      },
      child: FutureBuilder<_DashboardData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ListView(
              children: const [
                SizedBox(height: 120),
                AppEmptyState(
                  icon: Icons.cloud_off,
                  title: 'Dashboard unavailable',
                  message: 'Start the backend and pull to retry.',
                ),
              ],
            );
          }

          final data = snapshot.data!;
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                child: Text('Dashboard', style: Theme.of(context).textTheme.headlineSmall),
              ),
              _MetricGrid(data: data),
              AppSection(
                title: 'Recent orders',
                child: data.recentOrders.isEmpty
                    ? const AppEmptyState(
                        icon: Icons.receipt_long,
                        title: 'No orders yet',
                        message: 'Completed checkouts will appear here.',
                      )
                    : Column(
                        children: data.recentOrders.map((order) => _OrderTile(order: order)).toList(),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.data});

  final _DashboardData data;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 0);
    final cards = [
      _MetricCard(label: 'Revenue', value: money.format(data.report.totalRevenue), icon: Icons.currency_rupee),
      _MetricCard(label: 'Orders', value: data.report.totalOrders.toString(), icon: Icons.shopping_bag_outlined),
      _MetricCard(label: 'Avg order', value: money.format(data.report.avgOrderValue), icon: Icons.trending_up),
      _MetricCard(label: 'Low stock', value: data.lowStockCount.toString(), icon: Icons.warning_amber),
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: MediaQuery.of(context).size.width > 680 ? 4 : 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.55,
        children: cards,
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const Spacer(),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(symbol: 'Rs ');
    return Card(
      child: ListTile(
        leading: const Icon(Icons.receipt_long),
        title: Text(order.invoiceNumber),
        subtitle: Text(order.customerName?.isNotEmpty == true ? order.customerName! : order.paymentMode.toUpperCase()),
        trailing: Text(money.format(order.grandTotal), style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}

class _DashboardData {
  _DashboardData({
    required this.report,
    required this.recentOrders,
    required this.lowStockCount,
  });

  final DailySalesReport report;
  final List<OrderSummary> recentOrders;
  final int lowStockCount;
}
