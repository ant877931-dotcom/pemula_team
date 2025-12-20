// lib/screens/admin/manage_transactions_page.dart

import 'package:flutter/material.dart';

class ManageTransactionsPage extends StatefulWidget {
  // <--- Pastikan nama ini persis
  const ManageTransactionsPage({super.key});

  @override
  State<ManageTransactionsPage> createState() => _ManageTransactionsPageState();
}

class _ManageTransactionsPageState extends State<ManageTransactionsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Log Transaksi")),
      body: const Center(child: Text("Data Transaksi Akan Muncul Di Sini")),
    );
  }
}
