// frontend/lib/models/customer.dart

/// A customer known to the kirana store, used for invoice autocomplete
/// and transaction history lookups. Only a hashed phone number is stored
/// on-device (the backend owns the hash), never the raw number, so the
/// local Hive cache never holds a customer's plaintext phone.
class Customer {
  final String id;
  final String name;
  final String phoneHash;
  final bool isVerified;

  const Customer({
    required this.id,
    required this.name,
    required this.phoneHash,
    this.isVerified = false,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneHash: json['phone_hash'] as String,
      isVerified: json['is_verified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone_hash': phoneHash,
        'is_verified': isVerified,
      };
}
