import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/api_response.dart';
import 'midtrans_service.dart';

class TransferService {
  final _supabase = Supabase.instance.client;

  Future<ApiResponse<void>> transferBalance({
    required String senderId,
    required String targetAccountNumber,
    required double amount,
  }) async {
    try {
      final targetData = await _supabase
          .from('profiles')
          .select()
          .eq('account_number', targetAccountNumber)
          .single();

      final String receiverId = targetData['id'];

      if (senderId == receiverId) {
        return ApiResponse(
          success: false,
          message: "Tidak bisa transfer ke diri sendiri.",
        );
      }

      final senderData = await _supabase
          .from('profiles')
          .select('balance')
          .eq('id', senderId)
          .single();

      final double senderBalance = (senderData['balance'] as num).toDouble();

      if (senderBalance < amount) {
        return ApiResponse(success: false, message: "Saldo tidak mencukupi.");
      }
      await _supabase
          .from('profiles')
          .update({'balance': senderBalance - amount})
          .eq('id', senderId);

      await _supabase
          .from('profiles')
          .update({
            'balance': (targetData['balance'] as num).toDouble() + amount,
          })
          .eq('id', receiverId);

      await _supabase.from('transactions').insert([
        {
          'user_id': senderId,
          'amount': amount,
          'type': 'transfer_out',
          'description': 'Transfer ke $targetAccountNumber',
        },
        {
          'user_id': receiverId,
          'amount': amount,
          'type': 'transfer_in',
          'description': 'Transfer dari pengirim',
        },
      ]);

      return ApiResponse(success: true, message: "Transfer Berhasil!");
    } catch (e) {
      return ApiResponse(
        success: false,
        message: "Rekening tujuan tidak ditemukan.",
      );
    }
  }

  Future<ApiResponse<String>> createDepositTransaction({
    required String userId,
    required double amount,
    required String email,
    required String username,
  }) async {
    try {
      final orderId = "DEP-${DateTime.now().millisecondsSinceEpoch}";

      // 1. Catat ke tabel transaksi sebagai 'pending'
      await _supabase.from('transactions').insert({
        'user_id': userId,
        'amount': amount,
        'type': 'deposit',
        'description': 'Deposit via Midtrans ($orderId)',
        'status': 'pending', 
      });
      final snapToken = await MidtransService().getSnapToken(
        orderId: orderId,
        amount: amount,
        username: username,
        email: email,
      );

      if (snapToken != null) {
        return ApiResponse(success: true, data: snapToken);
      } else {
        return ApiResponse(
          success: false,
          message: "Gagal mendapatkan token pembayaran",
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: "Error Deposit: ${e.toString()}",
      );
    }
  }

  Future<ApiResponse<void>> withdrawBalance({
    required String userId,
    required double amount,
    required String bankName,
    required String accountNo,
    required double currentBalance,
  }) async {
    try {
      if (currentBalance < amount) {
        return ApiResponse(success: false, message: "Saldo tidak mencukupi.");
      }


      await _supabase
          .from('profiles')
          .update({'balance': currentBalance - amount})
          .eq('id', userId);


      await _supabase.from('transactions').insert({
        'user_id': userId,
        'amount': amount,
        'type': 'withdrawal',
        'status':
            'pending', 
        'description': 'Penarikan Dana ke $bankName',
        'bank_name': bankName,
        'bank_account_number': accountNo,
      });

      return ApiResponse(
        success: true,
        message: "Permintaan penarikan sedang diproses.",
      );
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }
}
