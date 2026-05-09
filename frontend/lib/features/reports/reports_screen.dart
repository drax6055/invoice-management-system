import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_client.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../models/report.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({required this.apiClient, super.key});

  final ApiClient apiClient;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late Future<_ReportsData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ReportsData> _load() async {
    final sales = await widget.apiClient.get('/reports/sales/daily');
    final payments = await widget.apiClient.get('/reports/payment-modes');
    final products = await widget.apiClient.get('/reports/products');
    final lowStock = await widget.apiClient.get('/reports/low-stock');
    return _ReportsData(
      sales: DailySalesReport.fromJson(sales['data'] as Map<String, dynamic>),
      paymentModes: (payments['data'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      products: (products['data'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      lowStock: (lowStock['data'] as List?)?.cast<Map<String, dynamic>>() ?? [],
    );
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(symbol: 'Rs ');

    return FutureBuilder<_ReportsData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const AppEmptyState(
            icon: Icons.cloud_off,
            title: 'Reports unavailable',
            message: 'Start the backend and refresh this view.',
          );
        }
        final data = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _future = _load();
            });
            await _future;
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(child: Text('Reports', style: Theme.of(context).textTheme.headlineSmall)),
                  IconButton.filledTonal(
                    tooltip: 'Refresh',
                    onPressed: () {
                      setState(() {
                        _future = _load();
                      });
                    },
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Today', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      _ReportRow(label: 'Revenue', value: money.format(data.sales.totalRevenue)),
                      _ReportRow(label: 'Orders', value: data.sales.totalOrders.toString()),
                      _ReportRow(label: 'Tax', value: money.format(data.sales.totalTax)),
                      _ReportRow(label: 'Discounts', value: money.format(data.sales.totalDiscount)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _ReportList(
                title: 'Payment modes',
                rows: data.paymentModes,
                labelBuilder: (row) => row['_id']?.toString().toUpperCase() ?? 'UNKNOWN',
                valueBuilder: (row) => money.format((row['totalRevenue'] as num? ?? 0).toDouble()),
              ),
              _ReportList(
                title: 'Top products',
                rows: data.products.take(5).toList(),
                labelBuilder: (row) => row['productName']?.toString() ?? 'Product',
                valueBuilder: (row) => '${row['unitsSold'] ?? 0} sold',
              ),
              _ReportList(
                title: 'Low stock',
                rows: data.lowStock.take(5).toList(),
                labelBuilder: (row) => row['name']?.toString() ?? 'Product',
                valueBuilder: (row) => '${row['qty'] ?? 0} left',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _ReportList extends StatelessWidget {
  const _ReportList({
    required this.title,
    required this.rows,
    required this.labelBuilder,
    required this.valueBuilder,
  });

  final String title;
  final List<Map<String, dynamic>> rows;
  final String Function(Map<String, dynamic>) labelBuilder;
  final String Function(Map<String, dynamic>) valueBuilder;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (rows.isEmpty)
              Text('No data yet', style: Theme.of(context).textTheme.labelMedium)
            else
              ...rows.map(
                (row) => _ReportRow(label: labelBuilder(row), value: valueBuilder(row)),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReportsData {
  _ReportsData({
    required this.sales,
    required this.paymentModes,
    required this.products,
    required this.lowStock,
  });

  final DailySalesReport sales;
  final List<Map<String, dynamic>> paymentModes;
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> lowStock;
}
