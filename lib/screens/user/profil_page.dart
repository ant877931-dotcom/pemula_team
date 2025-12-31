// lib/screens/user/profil_page.dart

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


  bool _isAccountVisible = false;


  final Color colorTop = const Color(0xFF007AFF);    
  final Color colorBottom = const Color(0xFF003366); 
  final Color colorGold = const Color(0xFFFFD700); 
  final Color colorGoldDark = const Color(0xFFB8860B); 


  String _maskAccountNumber() {
    return "************"; 
  }


  Future<void> _updatePin() async {
    if (_pinController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("PIN harus 6 digit"), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      await _supabase
          .from('profiles')
          .update({'pin': _pinController.text})
          .eq('id', widget.user.id);

      if (mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("PIN berhasil diperbarui!", style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: colorBottom,
          ),
        );
        _pinController.clear();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal memperbarui PIN"), backgroundColor: Colors.red),
      );
    }
  }

  void _showChangePinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
          side: BorderSide(color: colorGold, width: 2),
        ),
        title: Center(
          child: Text(
            "Keamanan ", 
            style: TextStyle(fontWeight: FontWeight.bold, color: colorBottom, )
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Ubah PIN Anda secara berkala untuk menjaga keamanan akun."),
            const SizedBox(height: 20),
            TextField(
              controller: _pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.bold, color: colorBottom),
              decoration: InputDecoration(
                counterText: "",
                filled: true,
                fillColor: colorGold.withOpacity(0.15),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15), 
                  borderSide: BorderSide(color: colorGoldDark, width: 2)
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            onPressed: _updatePin,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorGold,
              foregroundColor: colorBottom,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            child: const Text("SIMPAN PIN", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: Text("PROFILE", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, color: colorGold)),
        centerTitle: true,
        backgroundColor: colorBottom, 
        elevation: 0,
        iconTheme: IconThemeData(color: colorGold),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER GRADIENT ---
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [colorBottom, colorBottom.withOpacity(0.8)],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(50),
                      bottomRight: Radius.circular(50),
                    ),
                  ),
                ),
                Positioned(
                  top: 35,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: colorGold, width: 4),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 70, color: colorBottom),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 90),


            Text(
              widget.user.email.toUpperCase(),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: colorBottom, letterSpacing: 0.5),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: colorBottom, 
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorGold, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                
                  const SizedBox(width: 8),
                  Text(
                    "NASABAH", 
                    style: TextStyle(color: colorGold, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                children: [

                  _buildProfileCard(
                    icon: Icons.account_balance_wallet_rounded,
                    title: "NOMOR REKENING",
                    value: _isAccountVisible 
                        ? widget.user.accountNumber 
                        : _maskAccountNumber(),
                    accentColor: colorBottom, 
                    borderGold: false,
                    onTap: () {
                      setState(() {
                        _isAccountVisible = !_isAccountVisible;
                      });
                    },
                    trailing: Icon(
                      _isAccountVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: colorBottom.withOpacity(0.4),
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildProfileCard(
                    icon: Icons.security_rounded,
                    title: "PIN TRANSAKSI",
                    value: "••••••",
                    accentColor: colorGoldDark, 
                    onTap: _showChangePinDialog,
                    trailing: Icon(Icons.arrow_forward_ios_rounded, color: colorGoldDark, size: 16),
                    borderGold: true, 
                  ),
                  const SizedBox(height: 15),
                  _buildProfileCard(
                    icon: Icons.verified_user_rounded,
                    title: "STATUS AKUN",
                    value: "Aktif",
                    accentColor: const Color(0xFF2E7D32),
                    borderGold: false,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 140),
            Text(
              "M-BANKING ", 
              style: TextStyle(color: colorGoldDark.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard({
    required IconData icon,
    required String title,
    required String value,
    required Color accentColor,
    VoidCallback? onTap,
    Widget? trailing,
    required bool borderGold,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: borderGold ? Border.all(color: colorGold, width: 1.5) : null,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title, 
                    style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.bold, letterSpacing: 1)
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value, 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorBottom, letterSpacing: _isAccountVisible ? 1 : 2)
                  ),
                ],
              ),
            ),
            trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}