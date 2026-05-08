class Product {
  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.qty,
    this.sku,
    this.barcode,
    this.unit = 'pcs',
    this.lowStockThreshold = 0,
  });

  final String id;
  final String name;
  final String? sku;
  final String? barcode;
  final double price;
  final int qty;
  final String unit;
  final int lowStockThreshold;

  bool get isLowStock => qty <= lowStockThreshold;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      sku: json['sku']?.toString(),
      barcode: json['barcode']?.toString(),
      price: (json['price'] as num? ?? 0).toDouble(),
      qty: (json['qty'] as num? ?? 0).toInt(),
      unit: json['unit']?.toString() ?? 'pcs',
      lowStockThreshold: (json['lowStockThreshold'] as num? ?? 0).toInt(),
    );
  }
}
