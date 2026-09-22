// frontend/lib/models/transaction.dart

/// Category of a captured transaction.
enum TransactionCategory {
  groceries,
  vegetables,
  auto,
  sales,
  expense,
  other;

  /// Emoji shown for the transaction category.
  String get emoji => switch (this) {
        TransactionCategory.groceries => '🛒',
        TransactionCategory.vegetables => '🥬',
        TransactionCategory.auto => '🚖',
        TransactionCategory.sales => '💰',
        TransactionCategory.expense => '💸',
        TransactionCategory.other => '📦',
      };

  static TransactionCategory fromBackendString(String value) {
    return TransactionCategory.values.firstWhere(
      (category) => category.name == value.toLowerCase(),
      orElse: () => TransactionCategory.other,
    );
  }
}

/// A single captured transaction.
class Transaction {
  final String id;
  final double amount;
  final TransactionCategory category;
  final DateTime timestamp;
  final String? customerName;
  final String? customerId;
  final int confidence;
  final bool isSynced;

  const Transaction({
    required this.id,
    required this.amount,
    required this.category,
    required this.timestamp,
    required this.confidence,
    this.customerName,
    this.customerId,
    this.isSynced = false,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: TransactionCategory.fromBackendString(
        json['category'] as String? ?? 'other',
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      confidence: (json['confidence'] as num?)?.toInt() ?? 0,
      customerName: json['customer_name'] as String?,
      customerId: json['customer_id'] as String?,
      isSynced: json['is_synced'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'category': category.name,
      'timestamp': timestamp.toIso8601String(),
      'confidence': confidence,
      'customer_name': customerName,
      'customer_id': customerId,
      'is_synced': isSynced,
    };
  }

  Transaction copyWith({
    bool? isSynced,
  }) {
    return Transaction(
      id: id,
      amount: amount,
      category: category,
      timestamp: timestamp,
      confidence: confidence,
      customerName: customerName,
      customerId: customerId,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}

/// Response from POST /transactions/capture.
sealed class TransactionCaptureResponse {
  const TransactionCaptureResponse();

  factory TransactionCaptureResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final confidence = (json['confidence'] as num?)?.toInt() ?? 0;

    final transaction = Transaction.fromJson(
      json['transaction'] as Map<String, dynamic>,
    );

    return confidence < 70
        ? LowConfidenceCapture(
            transaction: transaction,
            confidence: confidence,
          )
        : ConfirmedCapture(
            transaction: transaction,
            confidence: confidence,
          );
  }
}

class ConfirmedCapture extends TransactionCaptureResponse {
  final Transaction transaction;
  final int confidence;

  const ConfirmedCapture({
    required this.transaction,
    required this.confidence,
  });
}

class LowConfidenceCapture extends TransactionCaptureResponse {
  final Transaction transaction;
  final int confidence;

  const LowConfidenceCapture({
    required this.transaction,
    required this.confidence,
  });
}
