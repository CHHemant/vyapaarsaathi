// frontend/lib/models/credit_entry.dart

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
  final bool isPaid;
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
    this.isPaid = false,
    this.paidAt,
  });

  factory CreditEntry.fromJson(Map<String, dynamic> json) =>
      _$CreditEntryFromJson(json);

  Map<String, dynamic> toJson() => _$CreditEntryToJson(this);

  CreditEntry copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    double? amount,
    String? type,
    DateTime? date,
    String? notes,
    bool? isPaid,
    DateTime? paidAt,
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
      isPaid: isPaid ?? this.isPaid,
      paidAt: paidAt ?? this.paidAt,
    );
  }
}