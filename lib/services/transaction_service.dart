import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/api_response.dart';
import '../models/transaction_model.dart';
import '../config/supabase_config.dart';

class TransactionService {
  final _supabase = SupabaseConfig().client;

  Future<ApiResponse<TransactionModel>> _processTransaction({
    required String userId,
    required double amount,
    required String type,
  }) async {
    if (amount <= 0) {
      return ApiResponse(
        success: false,
        message: "Jumlah transaksi harus positif.",
      );
    }

    try {
      final response = await _supabase.rpc(
        'handle_transaction',
        params: {
          'p_user_id': userId,
          'p_amount': amount,
          'p_transaction_type': type,
        },
      );

      if (response != null && response is Map<String, dynamic>) {
        final newTransaction = TransactionModel.fromJson(response);
        return ApiResponse(
          success: true,
          data: newTransaction,
          message:
              "${type == 'deposit' ? 'Deposit' : 'Penarikan'} berhasil dicatat.",
        );
      }

      return ApiResponse(
        success: false,
        message: "Transaksi gagal diproses oleh sistem.",
      );
    } on PostgrestException catch (e) {
      return ApiResponse(success: false, message: e.message);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: "Terjadi kesalahan sistem: ${e.toString()}",
      );
    }
  }

  Future<ApiResponse<TransactionModel>> deposit({
    required String userId,
    required double amount,
  }) async {
    return _processTransaction(userId: userId, amount: amount, type: 'deposit');
  }

  Future<ApiResponse<TransactionModel>> withdraw({
    required String userId,
    required double amount,
  }) async {
    return _processTransaction(
      userId: userId,
      amount: amount,
      type: 'withdrawal',
    );
  }

  Future<ApiResponse<List<TransactionModel>>> getTransactionHistory(
    String userId,
  ) async {
    try {
      final List<dynamic> response = await _supabase
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final transactions = response
          .map(
            (json) => TransactionModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      return ApiResponse(success: true, data: transactions);
    } on PostgrestException catch (e) {
      print('SUPABASE POSTGREST ERROR ');
      print('Query Gagal di getTransactionHistory: ${e.message}');
      print('-------------------------');
      return ApiResponse(success: false, message: e.message);
    } catch (e) {
      print('GENERAL ERROR ');
      print('Error tak terduga di getTransactionHistory: $e');
      print('---------------');
      return ApiResponse(
        success: false,
        message: "Gagal mengambil riwayat transaksi. Cek konsol.",
      );
    }
  }
}
