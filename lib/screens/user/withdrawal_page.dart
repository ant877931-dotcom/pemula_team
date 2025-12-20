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

  void _processWithdrawal() async {
    final amount = double.tryParse(_amountController.text) ?? 0;

    if (amount < 50000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Minimal penarikan Rp 50.000")),
      );
      return;
    }

    // 1. Verifikasi PIN
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
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tarik Tunai")),
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
              decoration: const InputDecoration(labelText: "Bank Tujuan"),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _bankNoController,
              decoration: const InputDecoration(
                labelText: "Nomor Rekening Bank",
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: "Nominal Tarik",
                prefixText: "Rp ",
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _processWithdrawal,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Tarik Sekarang"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
