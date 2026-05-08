class OrderSummary {
  OrderSummary({
    required this.id,
    required this.invoiceNumber,
    required this.grandTotal,
    required this.paymentMode,
    required this.status,
    required this.createdAt,
    this.customerName,
  });

  final String id;
  final String invoiceNumber;
  final double grandTotal;
  final String paymentMode;
  final String status;
  final DateTime createdAt;
  final String? customerName;

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    return OrderSummary(
      id: json['_id']?.toString() ?? '',
      invoiceNumber: json['invoiceNumber']?.toString() ?? '',
      grandTotal: (json['grandTotal'] as num? ?? 0).toDouble(),
      paymentMode: json['paymentMode']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      customerName: json['customerName']?.toString(),
    );
  }
}
