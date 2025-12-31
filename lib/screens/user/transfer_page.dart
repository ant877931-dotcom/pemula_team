import 'package:flutter/material.dart';
import '../../services/transfer_service.dart';
import '../../models/customer_user.dart';
import '../../widgets/pin_dialog.dart'; 
import '../../utils/format_extensions.dart';

class TransferPage extends StatefulWidget {
  final CustomerUser user;
  const TransferPage({super.key, required this.user});

  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  final _targetController = TextEditingController();
  final _amountController = TextEditingController();
  final _transferService = TransferService();
  bool _isLoading = false;

  // --- LOGIKA HIDE/SHOW ---
  bool _isAccountVisible = false;

  // --- PALET WARNA ---
  final Color colorTop = const Color(0xFF007AFF);    
  final Color colorBottom = const Color(0xFF003366); 
  final Color colorGold = const Color(0xFFFFD700);   

  void _handleTransferProcess() async {
    final amount = double.tryParse(_amountController.text) ?? 0;

    if (_targetController.text.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Isi nomor rekening dan nominal dengan benar")),
      );
      return;
    }

    if (amount > widget.user.balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Saldo tidak mencukupi"), backgroundColor: Colors.red),
      );
      return;
    }

    // Munculkan Dialog PIN yang sudah diperbaiki warnanya
    final isVerified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PinDialog(correctPin: widget.user.pin ?? "123456"),
    );

    if (isVerified == true) {
      _executeTransfer(amount);
    }
  }

  void _executeTransfer(double amount) async {
    setState(() => _isLoading = true);
    final result = await _transferService.transferBalance(
      senderId: widget.user.id,
      targetAccountNumber: _targetController.text,
      amount: amount,
    );
    setState(() => _isLoading = false);

    if (mounted) {
      if (result.success) {
        _showSuccessDialog(amount, _targetController.text);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? "Transfer Gagal"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSuccessDialog(double amount, String target) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
          side: BorderSide(color: colorGold, width: 2),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: colorGold.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.check_circle_rounded, color: colorGold, size: 70),
            ),
            const SizedBox(height: 20),
            Text("Transfer Berhasil!", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: colorBottom)),
            const SizedBox(height: 15),
            Divider(color: colorGold.withOpacity(0.3), thickness: 1),
            const SizedBox(height: 15),
            _buildDetailRow("Nominal", amount.toIDR()),
            const SizedBox(height: 10),
            _buildDetailRow("Tujuan", target),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorBottom,
                  foregroundColor: colorGold,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("KEMBALI KE DASHBOARD", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
        Text(value, style: TextStyle(color: colorBottom, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text(
          "TRANSFER", 
          style: TextStyle(
            fontWeight: FontWeight.w900, 
            letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: colorBottom,
        foregroundColor: colorGold,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [colorBottom, colorTop]),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Sumber Dana", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.user.balance.toIDR(), style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                      const Icon(Icons.account_balance_rounded, color: Colors.white24, size: 40),
                    ],
                  ),
                  const SizedBox(height: 5),
                  GestureDetector(
                    onTap: () => setState(() => _isAccountVisible = !_isAccountVisible),
                    child: Row(
                      children: [
                        Text(
                          "No. Rek: ${_isAccountVisible ? widget.user.accountNumber : "******"}", 
                          style: TextStyle(color: colorGold.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.bold)
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _isAccountVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          color: colorGold.withOpacity(0.5),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Rekening Tujuan", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildInputField(controller: _targetController, hint: "Masukkan nomor rekening", icon: Icons.person_add_alt_1_rounded, keyboardType: TextInputType.number),
                  const SizedBox(height: 25),
                  const Text("Nominal Transfer", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildInputField(controller: _amountController, hint: "0", icon: Icons.monetization_on_rounded, keyboardType: TextInputType.number, prefix: "Rp "),
                  const SizedBox(height: 40),
                  Container(
                    width: double.infinity,
                    height: 55,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [colorBottom, colorTop]),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleTransferProcess,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Konfirmasi Transfer", style: TextStyle(color: colorGold, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 10),
                          Icon(Icons.send_rounded, color: colorGold, size: 20),
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

  Widget _buildInputField({required TextEditingController controller, required String hint, required IconData icon, TextInputType keyboardType = TextInputType.text, String? prefix}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: colorGold.withOpacity(0.2))),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorBottom),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: colorBottom),
          prefixText: prefix,
          prefixStyle: TextStyle(color: colorBottom, fontWeight: FontWeight.bold),
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}