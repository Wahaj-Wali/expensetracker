class ReceiptData {
  final String merchantName;
  final String date;
  final double subtotal;
  final double taxAmount;
  final double taxRate;
  final double total;
  final List<String> items;

  ReceiptData({
    required this.merchantName,
    required this.date,
    required this.subtotal,
    required this.taxAmount,
    required this.taxRate,
    required this.total,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'merchantName': merchantName,
      'date': date,
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'taxRate': taxRate,
      'total': total,
      'items': items,
    };
  }

  factory ReceiptData.fromJson(Map<String, dynamic> json) {
    return ReceiptData(
      merchantName: json['merchantName'] ?? '',
      date: json['date'] ?? '',
      subtotal: (json['subtotal'] ?? 0.0).toDouble(),
      taxAmount: (json['taxAmount'] ?? 0.0).toDouble(),
      taxRate: (json['taxRate'] ?? 0.0).toDouble(),
      total: (json['total'] ?? 0.0).toDouble(),
      items: List<String>.from(json['items'] ?? []),
    );
  }
}
