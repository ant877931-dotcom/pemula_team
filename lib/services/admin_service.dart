import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/api_response.dart';

class AdminService {
  final _supabase = SupabaseConfig().client;
  final _userTable = 'profiles';

  // Admin Manage User: Freeze/Non-aktif sementara (Poin 1.b)
  Future<ApiResponse<void>> toggleFreezeUser(
    String userId,
    bool currentStatus,
  ) async {
    try {
      await _supabase
          .from(_userTable)
          .update({
            'is_frozen': !currentStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      return ApiResponse(
        success: true,
        message: "Status akun berhasil diubah.",
      );
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // Admin Manage User: Banned Akun (Poin 1.b)
  Future<ApiResponse<void>> toggleBanUser(
    String userId,
    bool currentStatus,
  ) async {
    try {
      await _supabase
          .from(_userTable)
          .update({
            'is_banned': !currentStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      return ApiResponse(
        success: true,
        message: "Status banned akun berhasil diubah.",
      );
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // Admin Menentukan No Rekening Whitelist (Poin 1.b)
  Future<ApiResponse<void>> addAllowedAccount(String accountNumber) async {
    try {
      await _supabase.from('allowed_accounts').insert({
        'account_number': accountNumber,
      });

      return ApiResponse(
        success: true,
        message: "Nomor rekening berhasil ditambahkan ke whitelist.",
      );
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // Unique violation error
        return ApiResponse(
          success: false,
          message: "Nomor rekening sudah ada di whitelist.",
        );
      }
      return ApiResponse(success: false, message: e.message);
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }
}
