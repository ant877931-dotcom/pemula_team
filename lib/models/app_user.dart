import 'admin_user.dart';
import 'customer_user.dart';

abstract class AppUser {
  final String id;
  final String email;

  AppUser({required this.id, required this.email});

  String get role;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final bool isAdmin = json['role'] == 'admin';

    if (isAdmin) {
      return AdminUser.fromJson(json);
    } else {
      return CustomerUser.fromJson(json);
    }
  }
}
