import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';
import '../models/admin_user.dart';
import '../models/customer_user.dart';
import '../models/api_response.dart';
import '../config/supabase_config.dart';

class AuthService {
  final _supabase = SupabaseConfig().client;

  // 1. LOGIN METHOD (Updated with Status & PIN Check)
  Future<ApiResponse<AppUser>> login(String email, String password) async {
    try {
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Ambil data profile lengkap termasuk status is_frozen, is_banned, dan PIN
      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', response.user!.id)
          .single();

      // --- VALIDASI STATUS AKUN ---

      // 1. Cek apakah akun di-ban
      if (profile['is_banned'] == true) {
        await _supabase.auth.signOut(); // Paksa hapus session
        return ApiResponse(
          success: false,
          message: "Akun Anda telah di-banned secara permanen. Hubungi admin.",
        );
      }

      // 2. Cek apakah akun dibekukan (frozen)
      if (profile['is_frozen'] == true) {
        await _supabase.auth.signOut(); // Paksa hapus session
        return ApiResponse(
          success: false,
          message:
              "Akun Anda sedang dibekukan. Silakan hubungi admin untuk aktivasi.",
        );
      }

      // --------------------------------------------

      late AppUser user;

      // Conditional instantiation berdasarkan role (Polymorphism)
      if (profile['role'] == 'admin') {
        user = AdminUser(id: profile['id'], email: email);
      } else {
        // [UPDATE] Sekarang menyertakan PIN ke dalam objek CustomerUser
        user = CustomerUser(
          id: profile['id'],
          email: email,
          accountNumber: profile['account_number'] ?? '-',
          balance: (profile['balance'] ?? 0).toDouble(),
          pin: profile['pin'], // Menambahkan PIN dari database
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

  // 2. REGISTER METHOD
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

      // Insert data ke tabel profiles
      // [UPDATE] Menambahkan kolom pin dengan nilai default saat pendaftaran
      await _supabase.from('profiles').insert({
        'id': user.id,
        'email': email,
        'account_number': accountNumber,
        'balance': 0.0,
        'role': 'customer',
        'is_frozen': false,
        'is_banned': false,
        'pin': '123456', // PIN default untuk user baru
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

  // 3. SEND MAGIC LINK/OTP METHOD
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

  // 4. LOGOUT
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
