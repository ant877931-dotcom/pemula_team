// lib/screens/user/withdrawal_page.dart

import 'package:flutter/material.dart';
import '../../models/customer_user.dart';
import '../../services/transfer_service.dart';
import '../../widgets/pin_dialog.dart';
import '../../utils/format_extensions.dart';

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

  final Color colorTop = const Color(0xFF007AFF);
  final Color colorBottom = const Color(0xFF003366);
  final Color colorGold = const Color(0xFFFFD700);

  void _processWithdrawal() async {
    final amount = double.tryParse(_amountController.text) ?? 0;

    if (amount < 50000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Minimal penarikan Rp 50.000"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (amount > widget.user.balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Saldo tidak mencukupi"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final isVerified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PinDialog(correctPin: widget.user.pin ?? "123456"),
    );

    if (isVerified != true) return;

    setState(() => _isLoading = true);

    final response = await _transferService.withdrawBalance(
      userId: widget.user.id,
      amount: amount,
      bankName: _selectedBank,
      accountNo: _bankNoController.text,
      currentBalance: widget.user.balance,
    );

    setState(() => _isLoading = false);

    if (response.success && mounted) {
      _showSuccessDialog(amount, _selectedBank);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? "Terjadi kesalahan"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog(double amount, String bank) {
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
              decoration: BoxDecoration(
                color: colorGold.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_rounded,
                color: colorGold,
                size: 70,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Penarikan Berhasil!",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: colorBottom,
              ),
            ),
            const SizedBox(height: 15),
            Divider(color: colorGold.withOpacity(0.3), thickness: 1),
            const SizedBox(height: 15),
            _buildDetailRow("Nominal", amount.toIDR()),
            const SizedBox(height: 8),
            _buildDetailRow("Bank Tujuan", bank),
            const SizedBox(height: 25),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  "KEMBALI KE DASHBOARD",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: colorBottom,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text(
          "TARIK TUNAI",
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
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
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Saldo Tersedia",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.user.balance.toIDR(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(
                        Icons.outbox_rounded,
                        color: Colors.white24,
                        size: 40,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Bank Tujuan",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: colorGold.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<String>(
                        value: _selectedBank,
                        items: ["BCA", "BNI", "MANDIRI", "BRI"].map((bank) {
                          return DropdownMenuItem(
                            value: bank,
                            child: Text(
                              bank,
                              style: TextStyle(
                                color: colorBottom,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _selectedBank = val!),
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.account_balance_rounded,
                            color: colorBottom,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    "Nomor Rekening Bank",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildInputField(
                    controller: _bankNoController,
                    hint: "Masukkan nomor rekening",
                    icon: Icons.numbers_rounded,
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    "Nominal Tarik",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildInputField(
                    controller: _amountController,
                    hint: "Min. 50.000",
                    icon: Icons.payments_rounded,
                    keyboardType: TextInputType.number,
                    prefix: "Rp ",
                  ),

                  const SizedBox(height: 40),
                  Container(
                    width: double.infinity,
                    height: 55,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [colorBottom, colorTop]),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: colorBottom.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _processWithdrawal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Tarik Sekarang",
                                  style: TextStyle(
                                    color: colorGold,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Icon(
                                  Icons.arrow_circle_down_rounded,
                                  color: colorGold,
                                  size: 20,
                                ),
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? prefix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: colorGold.withOpacity(0.2)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        cursorColor: colorBottom,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: colorBottom,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: colorBottom),
          prefixText: prefix,
          prefixStyle: TextStyle(
            color: colorBottom,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          hintText: hint,
          hintStyle: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
      ),
    );
  }
}
