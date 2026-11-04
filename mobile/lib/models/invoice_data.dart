class InvoiceData {
  final String date;
  final String price;
  final String purpose;

  InvoiceData({
    required this.date,
    required this.price,
    required this.purpose,
  });

  factory InvoiceData.fromJson(Map<String, dynamic> json) {
    return InvoiceData(
      date: json['date'] as String? ?? '',
      price: json['price'] as String? ?? '',
      purpose: json['purpose'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'price': price,
      'purpose': purpose,
    };
  }

  @override
  String toString() {
    return 'InvoiceData(date: $date, price: $price, purpose: $purpose)';
  }
}
