import 'app_user.dart';

class CustomerUser extends AppUser {
  double _balance;
  final String accountNumber;
  final String? pin;

  CustomerUser({
    required super.id,
    required super.email,
    required this.accountNumber,
    required double balance,
    this.pin,
  }) : _balance = balance;

  @override
  String get role => 'customer';

  double get balance => _balance;

  void updateBalance(double newBalance) {
    _balance = newBalance;
  }

  factory CustomerUser.fromJson(Map<String, dynamic> json) {
    return CustomerUser(
      id: json['id'] as String,
      email: json['email'] as String,
      accountNumber: json['account_number'] as String,
      balance: (json['balance'] as num).toDouble(),
      pin: json['pin'] as String?,
    );
  }
}
