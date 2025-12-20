// lib/services/transaction_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/api_response.dart';
import '../models/transaction_model.dart';
import '../config/supabase_config.dart';

class TransactionService {
  final _supabase = SupabaseConfig().client;

  // Method inti yang berinteraksi dengan PostgreSQL function (private)
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
      // Panggil RPC Supabase: handle_transaction
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

  // Wrapper untuk Deposit
  Future<ApiResponse<TransactionModel>> deposit({
    required String userId,
    required double amount,
  }) async {
    return _processTransaction(userId: userId, amount: amount, type: 'deposit');
  }

  // Wrapper untuk Penarikan
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

  // Method untuk mengambil riwayat transaksi user
  Future<ApiResponse<List<TransactionModel>>> getTransactionHistory(
    String userId,
  ) async {
    try {
      // Pastikan nama tabel 'transactions' dan kolom 'user_id' sudah benar
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
      // Tambahkan LOGGING untuk melihat error dari Supabase
      print('--- SUPABASE POSTGREST ERROR ---');
      print('Query Gagal di getTransactionHistory: ${e.message}');
      print('----------------------------------');
      return ApiResponse(success: false, message: e.message);
    } catch (e) {
      // Tambahkan LOGGING untuk melihat error umum
      print('--- GENERAL ERROR ---');
      print('Error tak terduga di getTransactionHistory: $e');
      print('-----------------------');
      return ApiResponse(
        success: false,
        message: "Gagal mengambil riwayat transaksi. Cek konsol.",
      );
    }
  }
}
