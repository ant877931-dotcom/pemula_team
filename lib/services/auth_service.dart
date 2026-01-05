import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';
import '../models/admin_user.dart';
import '../models/customer_user.dart';
import '../models/api_response.dart';
import '../config/supabase_config.dart';

class AuthService {
  final _supabase = SupabaseConfig().client;

  Future<ApiResponse<AppUser>> login(String email, String password) async {
    try {
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', response.user!.id)
          .single();

      if (profile['is_banned'] == true) {
        await _supabase.auth.signOut();
        return ApiResponse(
          success: false,
          message: "Akun Anda telah di-banned secara permanen. Hubungi admin.",
        );
      }

      if (profile['is_frozen'] == true) {
        await _supabase.auth.signOut();
        return ApiResponse(
          success: false,
          message:
              "Akun Anda sedang dibekukan. Silakan hubungi admin untuk aktivasi.",
        );
      }

      late AppUser user;

      if (profile['role'] == 'admin') {
        user = AdminUser(id: profile['id'], email: email);
      } else {
        user = CustomerUser(
          id: profile['id'],
          email: email,
          accountNumber: profile['account_number'] ?? '-',
          balance: (profile['balance'] ?? 0).toDouble(),
          pin: profile['pin'],
        );
      }

      return ApiResponse(success: true, data: user);
    } on AuthException catch (e) {
      return ApiResponse(success: false, message: e.message);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: "Terjadi kesalahan saat login: ${e.toString()}",
      );
    }
  }

  Future<ApiResponse<void>> register(
    String email,
    String password,
    String accountNumber,
  ) async {
    try {
      final AuthResponse authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        return ApiResponse(success: false, message: "Pendaftaran user gagal.");
      }

      final user = authResponse.user!;

      await _supabase.from('profiles').insert({
        'id': user.id,
        'email': email,
        'account_number': accountNumber,
        'balance': 0.0,
        'role': 'customer',
        'is_frozen': false,
        'is_banned': false,
        'pin': '123456',
      });

      await _supabase.auth.signOut();

      return ApiResponse(
        success: true,
        message:
            "Pendaftaran berhasil! PIN default Anda adalah 123456. Silakan Login.",
      );
    } on AuthException catch (e) {
      return ApiResponse(success: false, message: e.message);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: "Terjadi kesalahan saat pendaftaran: ${e.toString()}",
      );
    }
  }

  Future<ApiResponse<String>> sendMagicLink(String email) async {
    try {
      await _supabase.auth.signInWithOtp(email: email, shouldCreateUser: false);

      return ApiResponse(
        success: true,
        data: 'success',
        message:
            "Link/OTP telah dikirim ke email $email. Silakan cek kotak masuk Anda.",
      );
    } on AuthException catch (e) {
      return ApiResponse(success: false, message: e.message);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: "Gagal mengirim link: ${e.toString()}",
      );
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
