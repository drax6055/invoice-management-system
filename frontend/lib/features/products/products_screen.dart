import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/api/api_client.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../models/product.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({required this.apiClient, super.key});

  final ApiClient apiClient;

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late Future<List<Product>> _future;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<List<Product>> _load() async {
    final response = await widget.apiClient.get(
      '/products',
      query: {
        'limit': '100',
        if (_search.text.trim().isNotEmpty) 'search': _search.text.trim(),
      },
    );
    final items = (response['data']['items'] as List?) ?? [];
    return items.map((item) => Product.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> _openEditor([Product? product]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ProductEditor(apiClient: widget.apiClient, product: product),
    );
    if (saved == true) setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
          child: Row(
            children: [
              Expanded(child: Text('Products', style: Theme.of(context).textTheme.headlineSmall)),
              IconButton.filled(
                tooltip: 'Add product',
                onPressed: () => _openEditor(),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _search,
            decoration: InputDecoration(
              hintText: 'Search name, SKU, barcode',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                tooltip: 'Search',
                onPressed: () => setState(() => _future = _load()),
                icon: const Icon(Icons.arrow_forward),
              ),
            ),
            onSubmitted: (_) => setState(() => _future = _load()),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Product>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const AppEmptyState(
                  icon: Icons.cloud_off,
                  title: 'Products unavailable',
                  message: 'Check the backend connection and try again.',
                );
              }
              final products = snapshot.data ?? [];
              if (products.isEmpty) {
                return const AppEmptyState(
                  icon: Icons.inventory_2,
                  title: 'No products',
                  message: 'Add your first item to start billing.',
                );
              }
              return RefreshIndicator(
                onRefresh: () async => setState(() => _future = _load()),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  itemBuilder: (context, index) => _ProductTile(
                    product: products[index],
                    onTap: () => _openEditor(products[index]),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(symbol: 'Rs ');
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(product.isLowStock ? Icons.warning_amber : Icons.inventory_2_outlined),
        title: Text(product.name),
        subtitle: Text('${product.qty} ${product.unit}  ${product.sku ?? product.barcode ?? ''}'),
        trailing: Text(money.format(product.price), style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}

class _ProductEditor extends StatefulWidget {
  const _ProductEditor({required this.apiClient, this.product});

  final ApiClient apiClient;
  final Product? product;

  @override
  State<_ProductEditor> createState() => _ProductEditorState();
}

class _ProductEditorState extends State<_ProductEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _sku;
  late final TextEditingController _barcode;
  late final TextEditingController _price;
  late final TextEditingController _cost;
  late final TextEditingController _qty;
  late final TextEditingController _threshold;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _name = TextEditingController(text: product?.name ?? '');
    _sku = TextEditingController(text: product?.sku ?? '');
    _barcode = TextEditingController(text: product?.barcode ?? '');
    _price = TextEditingController(text: product?.price.toString() ?? '');
    _cost = TextEditingController(text: '0');
    _qty = TextEditingController(text: product?.qty.toString() ?? '0');
    _threshold = TextEditingController(text: product?.lowStockThreshold.toString() ?? '0');
  }

  @override
  void dispose() {
    _name.dispose();
    _sku.dispose();
    _barcode.dispose();
    _price.dispose();
    _cost.dispose();
    _qty.dispose();
    _threshold.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final body = {
      'name': _name.text.trim(),
      'sku': _sku.text.trim(),
      'barcode': _barcode.text.trim(),
      'price': double.parse(_price.text),
      'costPrice': double.tryParse(_cost.text) ?? 0,
      'qty': int.tryParse(_qty.text) ?? 0,
      'lowStockThreshold': int.tryParse(_threshold.text) ?? 0,
      'unit': 'pcs',
    };

    try {
      if (widget.product == null) {
        await widget.apiClient.post('/products', body);
      } else {
        await widget.apiClient.patch('/products/${widget.product!.id}', body);
      }
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _scanBarcode() async {
    final code = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _ProductBarcodeScannerDialog(),
    );
    if (code == null || code.isEmpty) return;
    setState(() => _barcode.text = code);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.product == null ? 'Add product' : 'Edit product', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Name'), validator: _required),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _sku, decoration: const InputDecoration(labelText: 'SKU'))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _barcode,
                      decoration: InputDecoration(
                        labelText: 'Barcode',
                        suffixIcon: IconButton(
                          tooltip: 'Scan barcode',
                          onPressed: _scanBarcode,
                          icon: const Icon(Icons.qr_code_scanner),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _price,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Price'),
                      validator: _required,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _cost,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Cost'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _qty, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Qty'))),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(controller: _threshold, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Low stock'))),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
                label: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Required' : null;
}

class _ProductBarcodeScannerDialog extends StatefulWidget {
  const _ProductBarcodeScannerDialog();

  @override
  State<_ProductBarcodeScannerDialog> createState() => _ProductBarcodeScannerDialogState();
}

class _ProductBarcodeScannerDialogState extends State<_ProductBarcodeScannerDialog> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (_handled) return;
              for (final barcode in capture.barcodes) {
                final value = barcode.rawValue;
                if (value == null || value.isEmpty) continue;
                _handled = true;
                Navigator.pop(context, value);
                return;
              }
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
                      'Scan product barcode or QR code',
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
