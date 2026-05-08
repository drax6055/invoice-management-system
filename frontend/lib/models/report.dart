class DailySalesReport {
  DailySalesReport({
    required this.totalRevenue,
    required this.totalOrders,
    required this.totalTax,
    required this.totalDiscount,
    required this.avgOrderValue,
  });

  final double totalRevenue;
  final int totalOrders;
  final double totalTax;
  final double totalDiscount;
  final double avgOrderValue;

  factory DailySalesReport.fromJson(Map<String, dynamic> json) {
    return DailySalesReport(
      totalRevenue: (json['totalRevenue'] as num? ?? 0).toDouble(),
      totalOrders: (json['totalOrders'] as num? ?? 0).toInt(),
      totalTax: (json['totalTax'] as num? ?? 0).toDouble(),
      totalDiscount: (json['totalDiscount'] as num? ?? 0).toDouble(),
      avgOrderValue: (json['avgOrderValue'] as num? ?? 0).toDouble(),
    );
  }
}
