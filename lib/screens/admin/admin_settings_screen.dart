import 'package:flutter/material.dart';
import '../../models/admin_user.dart';
import '../../services/auth_service.dart';

class AdminSettingsScreen extends StatefulWidget {
  final AdminUser user;

  const AdminSettingsScreen({super.key, required this.user});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final AuthService _authService = AuthService();
  late bool _is2faEnabled;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _toggle2FA(bool newValue) async {
    setState(() {
      _isLoading = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Admin'),
        backgroundColor: Colors.blueAccent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            title: const Text('Otentikasi Dua Faktor (2FA)'),
            subtitle: const Text(
              'Mengaktifkan 2FA akan memicu pengiriman kode OTP ke email saat login.',
            ),
            trailing: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Switch(value: _is2faEnabled, onChanged: _toggle2FA),
          ),
          const Divider(),
        ],
      ),
    );
  }
}
