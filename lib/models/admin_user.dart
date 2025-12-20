// lib/models/admin_user.dart

import 'app_user.dart';

class AdminUser extends AppUser {
  // Menggunakan required super.field (Named Arguments)
  AdminUser({required super.id, required super.email});

  @override
  String get role => 'admin';

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(id: json['id'] as String, email: json['email'] as String);
  }
}
