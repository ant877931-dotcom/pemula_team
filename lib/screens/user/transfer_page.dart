import 'package:flutter/material.dart';
import '../../services/transfer_service.dart';
import '../../models/customer_user.dart';
import '../../widgets/pin_dialog.dart'; // Import dialog PIN yang kita buat sebelumnya

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

  /// FUNGSI UTAMA: Alur Transfer dengan PIN
  void _handleTransferProcess() async {
    final amount = double.tryParse(_amountController.text) ?? 0;

    // 1. Validasi Input Dasar
    if (_targetController.text.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Isi nomor rekening dan nominal dengan benar"),
        ),
      );
      return;
    }

    if (amount > widget.user.balance) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Saldo tidak mencukupi")));
      return;
    }

    // 2. Munculkan Dialog PIN
    // Kita mengambil PIN yang tersimpan di objek user (hasil login/refresh)
    final isVerified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PinDialog(correctPin: widget.user.pin ?? "123456"),
    );

    // 3. Jika PIN Benar, Eksekusi ke Database
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Transfer Berhasil!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Kembali ke dashboard & trigger refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? "Transfer Gagal"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Transfer Antar Rekening"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Rekening Tujuan",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _targetController,
              decoration: const InputDecoration(
                hintText: "Masukkan nomor rekening",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_search),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Nominal Transfer",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: "Contoh: 50000",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monetization_on),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleTransferProcess,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Konfirmasi Transfer",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
