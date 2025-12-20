import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/api_response.dart';
import 'midtrans_service.dart';

class TransferService {
  final _supabase = Supabase.instance.client;

  // --- FITUR TRANSFER SESAMA USER ---
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

      // Update Saldo Pengirim
      await _supabase
          .from('profiles')
          .update({'balance': senderBalance - amount})
          .eq('id', senderId);

      // Update Saldo Penerima
      await _supabase
          .from('profiles')
          .update({
            'balance': (targetData['balance'] as num).toDouble() + amount,
          })
          .eq('id', receiverId);

      // Catat History
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

  // --- FITUR DEPOSIT VIA MIDTRANS ---
  // Ditambahkan parameter email dan username untuk Midtrans
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
        'status': 'pending', // Pastikan kolom ini ada di database
      });

      // 2. Panggil Midtrans dengan NAMED PARAMETERS (Memperbaiki Error Anda)
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

      // 1. Kurangi saldo di tabel profiles
      await _supabase
          .from('profiles')
          .update({'balance': currentBalance - amount})
          .eq('id', userId);

      // 2. Catat transaksi penarikan
      await _supabase.from('transactions').insert({
        'user_id': userId,
        'amount': amount,
        'type': 'withdrawal',
        'status':
            'pending', // Status pending karena proses bank asli butuh waktu
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
