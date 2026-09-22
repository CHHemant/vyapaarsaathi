// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credit_entry.dart';

// **************************************************************************

// JsonSerializableGenerator
// **************************************************************************

CreditEntry _$CreditEntryFromJson(Map<String, dynamic> json) => CreditEntry(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      customerName: json['customerName'] as String,
      customerPhone: json['customerPhone'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String?,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      isPaid: json['isPaid'] as bool? ?? false,
      paidAt: json['paidAt'] == null
          ? null
          : DateTime.parse(json['paidAt'] as String),
    );

Map<String, dynamic> _$CreditEntryToJson(CreditEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'customerId': instance.customerId,
      'customerName': instance.customerName,
      'customerPhone': instance.customerPhone,
      'amount': instance.amount,
      'type': instance.type,
      'date': instance.date.toIso8601String(),
      'notes': instance.notes,
      'paidAmount': instance.paidAmount,
      'isPaid': instance.isPaid,
      'paidAt': instance.paidAt?.toIso8601String(),
    };