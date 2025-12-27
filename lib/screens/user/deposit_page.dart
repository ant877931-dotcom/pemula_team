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

  // --- PALET WARNA KONSISTEN ---
  final Color colorTop = const Color(0xFF007AFF);    
  final Color colorBottom = const Color(0xFF003366); 
  final Color colorGold = const Color(0xFFFFD700);   

  void _handleDeposit() async {
    final amount = double.tryParse(_amountController.text.replaceAll('.', '')) ?? 0;

    if (amount < 10000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Minimal Top Up Rp 10.000"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    final response = await _transferService.createDepositTransaction(
      userId: widget.user.id,
      amount: amount,
      email: widget.user.email,
      username: widget.user.email.split('@')[0],
    );

    setState(() => _isLoading = false);

    if (response.success && response.data != null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MidtransPaymentPage(snapToken: response.data!),
        ),
      );

      if (result == true && mounted) {
        _saveTransactionToDatabase(amount);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? "Gagal terhubung ke Midtrans"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _saveTransactionToDatabase(double amount) async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;

      await supabase.from('transactions').insert({
        'user_id': widget.user.id,
        'amount': amount,
        'type': 'deposit',
        'description': 'Top Up Saldo via Midtrans',
        'status': 'success',
        'created_at': DateTime.now().toIso8601String(),
      });

      final newBalance = widget.user.balance + amount;
      await supabase
          .from('profiles')
          .update({'balance': newBalance})
          .eq('id', widget.user.id);

      if (mounted) {
        _showSuccessDialog(amount);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error simpan data: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 80),
            const SizedBox(height: 15),
            const Text("Top Up Berhasil!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            Text("Saldo sebesar ${amount.toIDR()} telah ditambahkan ke akun Anda.", textAlign: TextAlign.center),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(backgroundColor: colorBottom, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text("Selesai", style: TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text("TOP UP SALDO", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: colorBottom,
        foregroundColor: colorGold,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Info Saldo
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [colorBottom, colorTop]),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Saldo Anda Saat Ini", style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 5),
                      Text(widget.user.balance.toIDR(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Icon(Icons.account_balance_wallet_rounded, color: colorGold.withOpacity(0.5), size: 40),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Nominal Top Up", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                  const SizedBox(height: 15),
                  
                  // Input Area Premium
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                      border: Border.all(color: colorGold.withOpacity(0.3)),
                    ),
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      cursorColor: colorBottom,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorBottom),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.payments_rounded, color: colorBottom),
                        prefixText: "Rp ",
                        hintText: "0",
                        prefixStyle: TextStyle(color: colorBottom, fontWeight: FontWeight.bold, fontSize: 22),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 14, color: colorBottom.withOpacity(0.6)),
                      const SizedBox(width: 5),
                      Text("Minimal Top Up adalah Rp 10.000", style: TextStyle(color: colorBottom.withOpacity(0.6), fontSize: 12)),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Tombol Konfirmasi
                  Container(
                    width: double.infinity,
                    height: 55,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [colorBottom, colorTop]),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(color: colorBottom.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleDeposit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Lanjut Pembayaran", style: TextStyle(color: colorGold, fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 10),
                                Icon(Icons.arrow_forward_rounded, color: colorGold, size: 20),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}