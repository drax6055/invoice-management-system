import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_client.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../models/order.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({required this.apiClient, super.key});

  final ApiClient apiClient;

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  late Future<List<OrderSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<OrderSummary>> _load() async {
    final response = await widget.apiClient.get('/orders', query: {'limit': '50'});
    final items = (response['data']['items'] as List?) ?? [];
    return items.map((item) => OrderSummary.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> _voidOrder(OrderSummary order) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _VoidReasonDialog(),
    );
    if (reason == null || reason.trim().isEmpty) return;
    await widget.apiClient.patch('/orders/${order.id}/void', {'reason': reason.trim()});
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(symbol: 'Rs ');
    final date = DateFormat('dd MMM, hh:mm a');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
          child: Row(
            children: [
              Expanded(child: Text('Invoices', style: Theme.of(context).textTheme.headlineSmall)),
              IconButton.filledTonal(
                tooltip: 'Refresh',
                onPressed: () => setState(() => _future = _load()),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<OrderSummary>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const AppEmptyState(
                  icon: Icons.cloud_off,
                  title: 'Invoices unavailable',
                  message: 'Check the backend connection and retry.',
                );
              }
              final orders = snapshot.data ?? [];
              if (orders.isEmpty) {
                return const AppEmptyState(
                  icon: Icons.receipt_long,
                  title: 'No invoices',
                  message: 'Checkout invoices will be listed here.',
                );
              }
              return RefreshIndicator(
                onRefresh: () async => setState(() => _future = _load()),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(order.status == 'void' ? Icons.block : Icons.receipt_long),
                        title: Text(order.invoiceNumber),
                        subtitle: Text('${date.format(order.createdAt)}  ${order.paymentMode.toUpperCase()}'),
                        trailing: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          children: [
                            Text(money.format(order.grandTotal), style: Theme.of(context).textTheme.titleMedium),
                            IconButton(
                              tooltip: 'Void invoice',
                              onPressed: order.status == 'void' ? null : () => _voidOrder(order),
                              icon: const Icon(Icons.undo),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _VoidReasonDialog extends StatefulWidget {
  const _VoidReasonDialog();

  @override
  State<_VoidReasonDialog> createState() => _VoidReasonDialogState();
}

class _VoidReasonDialogState extends State<_VoidReasonDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Void invoice'),
      content: TextField(
        controller: _reason,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Reason'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, _reason.text), child: const Text('Void')),
      ],
    );
  }
}
