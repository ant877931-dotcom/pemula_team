// lib/screens/user/deposit_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/customer_user.dart';
import '../../services/transfer_service.dart';
import 'midtrans_payment_page.dart';
import '../../utils/format_extensions.dart';

class DepositPage extends StatefulWidget {
  final CustomerUser user;
  const DepositPage({super.key, required this.user});

  @override
  State<DepositPage> createState() => _DepositPageState();
}

class _DepositPageState extends State<DepositPage> {
  final _amountController = TextEditingController();
  final _transferService = TransferService();
  bool _isLoading = false;

  /// FUNGSI PROSES DEPOSIT
  void _handleDeposit() async {
    final amount = double.tryParse(_amountController.text) ?? 0;

    // 1. Validasi Input
    if (amount < 10000) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Minimal Top Up Rp 10.000")));
      return;
    }

    setState(() => _isLoading = true);

    // 2. Minta Snap Token dari TransferService
    final response = await _transferService.createDepositTransaction(
      userId: widget.user.id,
      amount: amount,
      email: widget.user.email,
      username: widget.user.email.split('@')[0],
    );

    setState(() => _isLoading = false);

    if (response.success && response.data != null) {
      // 3. Buka WebView Midtrans
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MidtransPaymentPage(snapToken: response.data!),
        ),
      );

      // 4. JIKA PEMBAYARAN SELESAI (Result dari WebView adalah true)
      if (result == true && mounted) {
        _saveTransactionToDatabase(amount);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? "Gagal terhubung ke Midtrans"),
          ),
        );
      }
    }
  }

  /// FUNGSI SIMPAN KE DATABASE (Agar data masuk ke Tabel Transactions)
  void _saveTransactionToDatabase(double amount) async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;

      // A. Masukkan data ke tabel transactions
      await supabase.from('transactions').insert({
        'user_id': widget.user.id,
        'amount': amount,
        'type': 'deposit',
        'description': 'Top Up Saldo via Midtrans',
        'status': 'success',
        'created_at': DateTime.now().toIso8601String(),
      });

      // B. Update Saldo di tabel profiles
      final newBalance = widget.user.balance + amount;
      await supabase
          .from('profiles')
          .update({'balance': newBalance})
          .eq('id', widget.user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Top Up Berhasil! Saldo telah ditambahkan."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Kembali ke dashboard & refresh saldo
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error simpan data: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Top Up Saldo"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Masukkan Nominal Top Up",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: "Rp ",
                hintText: "0",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.indigo, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "* Minimal Top Up adalah Rp 10.000",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleDeposit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Lanjut ke Pembayaran",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
