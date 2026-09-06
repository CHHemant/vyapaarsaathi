// frontend/lib/models/invoice.dart

/// GST slabs the invoice screen's dropdown offers. Kept as an enum with
/// a `percent` getter rather than a raw double field so invalid rates
/// (e.g. 17%) are unrepresentable.
enum GstRate {
  zero(0),
  five(5),
  twelve(12),
  eighteen(18),
  twentyEight(28);

  final int percent;
  const GstRate(this.percent);

  static GstRate fromPercent(int percent) {
    return GstRate.values.firstWhere(
      (r) => r.percent == percent,
      orElse: () => GstRate.zero,
    );
  }
}

/// A single line item on a GST invoice. Quantity is a double (not int) to
/// support items sold by weight — "5 kg rice" from the voice-parsed flow.
class InvoiceItem {
  final String id;
  final String name;
  final double quantity;
  final double unitPrice;
  final GstRate gstRate;

  const InvoiceItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.gstRate,
  });

  double get lineSubtotal => quantity * unitPrice;
  double get lineGst => lineSubtotal * gstRate.percent / 100;
  double get lineTotal => lineSubtotal + lineGst;

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['id'] as String,
      name: json['name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unitPrice: (json['unit_price'] as num).toDouble(),
      gstRate: GstRate.fromPercent((json['gst_rate'] as num).toInt()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'quantity': quantity,
        'unit_price': unitPrice,
        'gst_rate': gstRate.percent,
      };
}

/// A GST-ready invoice, built client-side from [InvoiceItem]s and sent to
/// `POST /gst/invoice`, which returns [pdfPath] once generated.
class Invoice {
  final String? customerId;
  final String? customerName;
  final List<InvoiceItem> items;

  /// Set only after the backend responds with a generated PDF — null
  /// while the invoice is still being composed on-screen.
  final String? pdfPath;

  const Invoice({
    required this.items,
    this.customerId,
    this.customerName,
    this.pdfPath,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.lineSubtotal);
  double get gstTotal => items.fold(0, (sum, item) => sum + item.lineGst);
  double get grandTotal => subtotal + gstTotal;

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      customerId: json['customer_id'] as String?,
      customerName: json['customer_name'] as String?,
      items: (json['items'] as List<dynamic>)
          .map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      pdfPath: json['pdf_path'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'customer_id': customerId,
        'customer_name': customerName,
        'items': items.map((i) => i.toJson()).toList(),
        if (pdfPath != null) 'pdf_path': pdfPath,
      };

  Invoice copyWith({List<InvoiceItem>? items, String? pdfPath}) => Invoice(
        customerId: customerId,
        customerName: customerName,
        items: items ?? this.items,
        pdfPath: pdfPath ?? this.pdfPath,
      );
}
