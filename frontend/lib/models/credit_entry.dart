import 'package:json_annotation/json_annotation.dart';

part 'credit_entry.g.dart';

@JsonSerializable()
class CreditEntry {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final double amount;
  final String type; // 'given' or 'taken'
  final DateTime date;
  final String? notes;

  /// Total amount already paid against this Khata entry.
  final double paidAmount;

  /// True when the complete amount has been settled.
  final bool isPaid;

  /// Time of the most recent payment.
  final DateTime? paidAt;

  CreditEntry({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.amount,
    required this.type,
    required this.date,
    this.notes,
    this.paidAmount = 0,
    this.isPaid = false,
    this.paidAt,
  });

  factory CreditEntry.fromJson(Map<String, dynamic> json) =>
      _$CreditEntryFromJson(json);

  Map<String, dynamic> toJson() => _$CreditEntryToJson(this);

  /// Amount still outstanding.
  double get remainingAmount {
    final remaining = amount - paidAmount;

    if (remaining <= 0) {
      return 0;
    }

    return remaining;
  }

  /// True when some amount has been paid but the entry is not fully settled.
  bool get isPartiallyPaid {
    return paidAmount > 0 && remainingAmount > 0;
  }

  /// True when there is still money outstanding.
  bool get hasOutstanding {
    return remainingAmount > 0;
  }

  CreditEntry copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    double? amount,
    String? type,
    DateTime? date,
    String? notes,
    double? paidAmount,
    bool? isPaid,
    DateTime? paidAt,

    /// Allows paidAt to explicitly become null.
    bool clearPaidAt = false,
  }) {
    return CreditEntry(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      paidAmount: paidAmount ?? this.paidAmount,
      isPaid: isPaid ?? this.isPaid,
      paidAt: clearPaidAt ? null : (paidAt ?? this.paidAt),
    );
  }
}