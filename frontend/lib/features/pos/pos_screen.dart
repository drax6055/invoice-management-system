import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../models/product.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({required this.apiClient, super.key});

  final ApiClient apiClient;

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _search = TextEditingController();
  final List<_CartItem> _cart = [];
  String _paymentMode = 'cash';
  bool _checkingOut = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _addProductToCart(Product product) {
    setState(() {
      final matches = _cart.where((item) => item.product.id == product.id);
      final existing = matches.isEmpty ? null : matches.first;
      if (existing == null) {
        _cart.add(_CartItem(product: product));
      } else {
        existing.qty += 1;
      }
      _search.clear();
    });
  }

  Future<void> _addByCodeOrName() async {
    final value = _search.text.trim();
    if (value.isEmpty) return;

    try {
      final barcodeResponse = await widget.apiClient.get('/products/barcode/$value');
      _addProductToCart(Product.fromJson(barcodeResponse['data'] as Map<String, dynamic>));
      return;
    } on ApiException {
      // Fall through to product-name search.
    }

    final products = await _searchProducts(value);
    if (!mounted) return;

    if (products.isEmpty) {
      _showMessage('No product found');
    } else if (products.length == 1) {
      _addProductToCart(products.first);
    } else {
      final selected = await showModalBottomSheet<Product>(
        context: context,
        builder: (_) => _ProductPicker(products: products),
      );
      if (selected != null) _addProductToCart(selected);
    }
  }

  Future<List<Product>> _searchProducts(String value) async {
    final response = await widget.apiClient.get('/products', query: {
      'search': value,
      'limit': '20',
    });
    final items = (response['data']['items'] as List?) ?? [];
    return items.map((item) => Product.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> _openScanner() async {
    final code = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _BarcodeScannerDialog(),
    );
    if (code == null || code.isEmpty) return;

    try {
      final response = await widget.apiClient.get('/products/barcode/$code');
      _addProductToCart(Product.fromJson(response['data'] as Map<String, dynamic>));
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Could not scan product');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty) return;
    setState(() => _checkingOut = true);
    try {
      final response = await widget.apiClient.post('/orders/checkout', {
        'paymentMode': _paymentMode,
        'discountTotal': 0,
        'cartItems': _cart
            .map((item) => {
                  'productId': item.product.id,
                  'qty': item.qty,
                  'discount': 0,
                })
            .toList(),
      });
      if (!mounted) return;
      setState(() => _cart.clear());
      final invoice = response['data']['invoice'] as Map<String, dynamic>;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invoice ${invoice['invoiceNumber']} created')),
      );
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Checkout failed');
    } finally {
      if (mounted) setState(() => _checkingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(symbol: 'Rs ');
    final total = _cart.fold<double>(0, (sum, item) => sum + item.lineTotal);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openScanner,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
            child: Row(
              children: [
                Expanded(child: Text('POS Billing', style: Theme.of(context).textTheme.headlineSmall)),
                IconButton.filledTonal(
                  tooltip: 'Clear cart',
                  onPressed: _cart.isEmpty ? null : () => setState(() => _cart.clear()),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Search product name or enter barcode',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Add item',
                  onPressed: _addByCodeOrName,
                  icon: const Icon(Icons.add_shopping_cart),
                ),
              ),
              onSubmitted: (_) => _addByCodeOrName(),
            ),
          ),
          Expanded(
            child: _cart.isEmpty
                ? const AppEmptyState(
                    icon: Icons.point_of_sale,
                    title: 'Cart is empty',
                    message: 'Search by name, enter barcode, or scan with the camera.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cart.length,
                    itemBuilder: (context, index) {
                      final item = _cart[index];
                      return Card(
                        child: ListTile(
                          title: Text(item.product.name),
                          subtitle: Text('${money.format(item.product.price)} x ${item.qty}'),
                          leading: IconButton(
                            tooltip: 'Decrease',
                            onPressed: () => setState(() {
                              item.qty -= 1;
                              if (item.qty <= 0) _cart.removeAt(index);
                            }),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          trailing: SizedBox(
                            width: 132,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Flexible(child: Text(money.format(item.lineTotal), overflow: TextOverflow.ellipsis)),
                                IconButton(
                                  tooltip: 'Increase',
                                  onPressed: () => setState(() => item.qty += 1),
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'cash', icon: Icon(Icons.payments), label: Text('Cash')),
                      ButtonSegment(value: 'card', icon: Icon(Icons.credit_card), label: Text('Card')),
                      ButtonSegment(value: 'upi', icon: Icon(Icons.phone_android), label: Text('UPI')),
                      ButtonSegment(value: 'credit', icon: Icon(Icons.account_balance_wallet), label: Text('Credit')),
                    ],
                    selected: {_paymentMode},
                    onSelectionChanged: (value) => setState(() => _paymentMode = value.first),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: Text('Total', style: Theme.of(context).textTheme.titleLarge)),
                    Text(money.format(total), style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _cart.isEmpty || _checkingOut ? null : _checkout,
                  icon: _checkingOut
                      ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.receipt_long),
                  label: const Text('Checkout'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductPicker extends StatelessWidget {
  const _ProductPicker({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(symbol: 'Rs ');

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        children: [
          Text('Select product', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...products.map(
            (product) => Card(
              child: ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text(product.name),
                subtitle: Text('${product.qty} ${product.unit} available'),
                trailing: Text(money.format(product.price)),
                onTap: () => Navigator.pop(context, product),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarcodeScannerDialog extends StatefulWidget {
  const _BarcodeScannerDialog();

  @override
  State<_BarcodeScannerDialog> createState() => _BarcodeScannerDialogState();
}

class _BarcodeScannerDialogState extends State<_BarcodeScannerDialog> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (_handled) return;
              final code = capture.barcodes
                  .map((barcode) => barcode.rawValue)
                  .whereType<String>()
                  .where((value) => value.isNotEmpty)
                  .firstOrNull;
              if (code == null) return;
              _handled = true;
              Navigator.pop(context, code);
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton.filled(
                    tooltip: 'Close scanner',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Scan barcode or QR code',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}

class _CartItem {
  _CartItem({required this.product});

  final Product product;
  int qty = 1;

  double get lineTotal => product.price * qty;
}
