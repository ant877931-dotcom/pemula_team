import 'package:flutter/material.dart';
import '../../models/customer_user.dart';
import '../../services/transfer_service.dart';
import '../../widgets/pin_dialog.dart';

class WithdrawalPage extends StatefulWidget {
  final CustomerUser user;
  const WithdrawalPage({super.key, required this.user});

  @override
  State<WithdrawalPage> createState() => _WithdrawalPageState();
}

class _WithdrawalPageState extends State<WithdrawalPage> {
  final _amountController = TextEditingController();
  final _bankNoController = TextEditingController();
  final _transferService = TransferService();
  String _selectedBank = "BCA";
  bool _isLoading = false;

  // Konstanta Warna Tema
  final Color primaryTeal = const Color(0xFF1A9591);
  final Color secondaryTeal = const Color(0xFF67C3C0);

  void _processWithdrawal() async {
    final amount = double.tryParse(_amountController.text) ?? 0;

    if (amount < 50000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Minimal penarikan Rp 50.000"),
          backgroundColor: Colors.orange, // Warna peringatan tetap orange/red agar kontras
        ),
      );
      return;
    }

    // 1. Verifikasi PIN (Dialog ini biasanya diatur di widgets/pin_dialog.dart, 
    // tapi style pemanggilannya kita pastikan tetap bersih)
    final isVerified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PinDialog(correctPin: widget.user.pin ?? "123456"),
    );

    if (isVerified != true) return;

    setState(() => _isLoading = true);

    // 2. Eksekusi Penarikan
    final response = await _transferService.withdrawBalance(
      userId: widget.user.id,
      amount: amount,
      bankName: _selectedBank,
      accountNo: _bankNoController.text,
      currentBalance: widget.user.balance,
    );

    setState(() => _isLoading = false);

    if (response.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message!),
          backgroundColor: primaryTeal, // DIUBAH: Menggunakan Teal untuk sukses
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tarik Tunai"),
        backgroundColor: primaryTeal, // DIUBAH: Teal
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedBank,
              items: ["BCA", "BNI", "MANDIRI", "BRI"].map((bank) {
                return DropdownMenuItem(value: bank, child: Text(bank));
              }).toList(),
              onChanged: (val) => setState(() => _selectedBank = val!),
              decoration: InputDecoration(
                labelText: "Bank Tujuan",
                labelStyle: TextStyle(color: primaryTeal),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: primaryTeal),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _bankNoController,
              cursorColor: primaryTeal,
              decoration: InputDecoration(
                labelText: "Nomor Rekening Bank",
                labelStyle: TextStyle(color: primaryTeal),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: primaryTeal),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _amountController,
              cursorColor: primaryTeal,
              decoration: InputDecoration(
                labelText: "Nominal Tarik",
                prefixText: "Rp ",
                labelStyle: TextStyle(color: primaryTeal),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: primaryTeal),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 30),
            
            // Tombol dengan Gradient Teal
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryTeal, secondaryTeal],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: primaryTeal.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _processWithdrawal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Tarik Sekarang",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}