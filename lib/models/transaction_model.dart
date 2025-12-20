class TransactionModel {
  final String id;
  final String userId;
  final double amount;
  final String type;
  final String? description; // Tambahkan ini
  final String? status; // Tambahkan ini
  final String? orderId; // Tambahkan ini
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    this.description,
    this.status,
    this.orderId,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      userId: json['user_id'],
      amount: (json['amount'] as num).toDouble(),
      type: json['type'],
      description: json['description'],
      status: json['status'],
      orderId: json['order_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
