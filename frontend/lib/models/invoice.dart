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
      (rate) => rate.percent == percent,
      orElse: () => GstRate.zero,
    );
  }
}

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
      id: json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? 'Item',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      gstRate: GstRate.fromPercent(
        (json['gst_rate'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit_price': unitPrice,
      'gst_rate': gstRate.percent,
    };
  }
}

class Invoice {
  final String? storageId;
  final String? invoiceNumber;
  final String? customerId;
  final String? customerName;
  final List<InvoiceItem> items;
  final String? pdfPath;
  final bool isPaid;
  final DateTime? paidAt;
  final String? paymentSlipPath;
  final DateTime? createdAt;

  const Invoice({
    required this.items,
    this.storageId,
    this.invoiceNumber,
    this.customerId,
    this.customerName,
    this.pdfPath,
    this.isPaid = false,
    this.paidAt,
    this.paymentSlipPath,
    this.createdAt,
  });

  double get subtotal {
    return items.fold(
      0,
      (sum, item) => sum + item.lineSubtotal,
    );
  }

  double get gstTotal {
    return items.fold(
      0,
      (sum, item) => sum + item.lineGst,
    );
  }

  double get grandTotal => subtotal + gstTotal;

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];

    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map(
              (item) => InvoiceItem.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList()
        : <InvoiceItem>[];

    DateTime? createdAt;

    final rawCreatedAt = json['created_at'];

    if (rawCreatedAt is String && rawCreatedAt.isNotEmpty) {
      createdAt = DateTime.tryParse(rawCreatedAt);
    }

    DateTime? paidAt;

    final rawPaidAt = json['paid_at'];

    if (rawPaidAt is String && rawPaidAt.isNotEmpty) {
      paidAt = DateTime.tryParse(rawPaidAt);
    }

    return Invoice(
      storageId: json['storage_id'] as String?,
      invoiceNumber: json['invoice_number'] as String?,
      customerId: json['customer_id'] as String?,
      customerName: json['customer_name'] as String?,
      items: List<InvoiceItem>.unmodifiable(items),
      pdfPath: json['pdf_path'] as String?,
      isPaid: json['is_paid'] as bool? ?? false,
      paidAt: paidAt,
      paymentSlipPath: json['payment_slip_path'] as String?,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'storage_id': storageId,
      'invoice_number': invoiceNumber,
      'customer_id': customerId,
      'customer_name': customerName,
      'items': items.map((item) => item.toJson()).toList(),
      if (pdfPath != null) 'pdf_path': pdfPath,
      'is_paid': isPaid,
      if (paidAt != null) 'paid_at': paidAt!.toIso8601String(),
      if (paymentSlipPath != null) 'payment_slip_path': paymentSlipPath,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  Invoice copyWith({
    String? storageId,
    String? invoiceNumber,
    String? customerId,
    String? customerName,
    List<InvoiceItem>? items,
    String? pdfPath,
    bool? isPaid,
    DateTime? paidAt,
    String? paymentSlipPath,
    DateTime? createdAt,
  }) {
    return Invoice(
      storageId: storageId ?? this.storageId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      pdfPath: pdfPath ?? this.pdfPath,
      isPaid: isPaid ?? this.isPaid,
      paidAt: paidAt ?? this.paidAt,
      paymentSlipPath: paymentSlipPath ?? this.paymentSlipPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
