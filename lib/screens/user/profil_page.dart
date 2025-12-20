import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/customer_user.dart';

class ProfilePage extends StatefulWidget {
  final CustomerUser user;
  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _supabase = Supabase.instance.client;
  final _pinController = TextEditingController();

  // Fungsi untuk mengubah PIN di Database
  Future<void> _updatePin() async {
    if (_pinController.text.length < 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("PIN harus 6 digit")));
      return;
    }

    try {
      await _supabase
          .from('profiles')
          .update({'pin': _pinController.text})
          .eq('id', widget.user.id);

      if (mounted) {
        Navigator.pop(context); // Tutup dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("PIN berhasil diperbarui!"),
            backgroundColor: Colors.green,
          ),
        );
        _pinController.clear();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Gagal memperbarui PIN")));
    }
  }

  // Dialog input PIN baru
  void _showChangePinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ubah PIN Keamanan"),
        content: TextField(
          controller: _pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            hintText: "Masukkan 6 digit PIN baru",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(onPressed: _updatePin, child: const Text("Simpan")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil Saya"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.indigo,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              widget.user.email,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 40),

            // Info Akun
            ListTile(
              leading: const Icon(Icons.account_balance),
              title: const Text("Nomor Rekening"),
              subtitle: Text(widget.user.accountNumber),
            ),

            // Tombol Ubah PIN
            ListTile(
              leading: const Icon(Icons.lock_outline, color: Colors.orange),
              title: const Text("Ubah PIN Keamanan"),
              subtitle: const Text("Ganti PIN untuk keamanan transaksi"),
              onTap: _showChangePinDialog,
            ),

            const SizedBox(height: 30),

            // Tombol Logout
          ],
        ),
      ),
    );
  }
}
