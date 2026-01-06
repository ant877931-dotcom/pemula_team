import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart'; // Pastikan import ini ada untuk redirect setelah sukses

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  final _newPasswordController = TextEditingController();

  final _supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool _isTokenSent = false; // State untuk mengecek apakah token sudah dikirim

  // --- PALET WARNA (Sesuai Login Screen) ---
  final Color colorTop = const Color(0xFF007AFF);
  final Color colorBottom = const Color(0xFF003366);
  final Color colorAccent = const Color(0xFFFDB813); // Kuning Aksen

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  // 1. KIRIM KODE OTP KE EMAIL
  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage("Masukkan email Anda", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Menggunakan signInWithOtp agar user mendapat kode 6 digit
      await _supabase.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false, // Penting: Hanya untuk user yang sudah ada
      );

      setState(() {
        _isTokenSent = true; // Ubah tampilan ke input token
        _isLoading = false;
      });

      _showMessage("Kode token dikirim ke email Anda.", Colors.green);
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage("Gagal mengirim kode: ${e.toString()}", Colors.red);
    }
  }

  // 2. VERIFIKASI TOKEN
  Future<void> _verifyOtpAndShowPasswordDialog() async {
    final token = _tokenController.text.trim();
    final email = _emailController.text.trim();

    if (token.length != 6) {
      _showMessage("Token harus 6 digit", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Verifikasi token. Jika berhasil, user akan otomatis LOGIN (mendapat session)
      final AuthResponse res = await _supabase.auth.verifyOTP(
        type: OtpType.email,
        token: token,
        email: email,
      );

      setState(() => _isLoading = false);

      if (res.session != null) {
        // Jika verifikasi sukses & dapat sesi, tampilkan Popup Ganti Password
        if (mounted) _showChangePasswordDialog();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage("Token salah atau kadaluarsa.", Colors.red);
    }
  }

  // 3. POPUP GANTI PASSWORD & UPDATE KE DATABASE
  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User tidak bisa tap di luar untuk tutup
      builder: (context) {
        bool isUpdating = false;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                "Buat Password Baru",
                style: TextStyle(
                  color: colorBottom,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Masukkan password baru Anda di bawah ini.",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Password Baru",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                  ),
                ],
              ),
              actions: [
                if (isUpdating)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorAccent,
                      foregroundColor: colorBottom,
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      if (_newPasswordController.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Password minimal 6 karakter"),
                          ),
                        );
                        return;
                      }

                      setStateDialog(() => isUpdating = true);

                      try {
                        // Update password user yang sedang login saat ini
                        await _supabase.auth.updateUser(
                          UserAttributes(password: _newPasswordController.text),
                        );

                        // Logout agar user login ulang dengan password baru
                        await _supabase.auth.signOut();

                        if (mounted) {
                          Navigator.pop(context); // Tutup Dialog
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Password berhasil diubah! Silakan login.",
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setStateDialog(() => isUpdating = false);
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text("Gagal: $e")));
                      }
                    },
                    child: const Text(
                      "SIMPAN PASSWORD",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _showMessage(String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colorTop, colorBottom],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Tombol Back
              Positioned(
                top: 10,
                left: 10,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon Ilustrasi
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.15),
                        ),
                        child: Icon(
                          _isTokenSent
                              ? Icons.mark_email_read_rounded
                              : Icons.lock_reset_rounded,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 25),

                      Text(
                        _isTokenSent ? "Verifikasi Token" : "Lupa Password?",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 15),

                      Text(
                        _isTokenSent
                            ? "Masukkan 6 digit kode yang dikirim ke ${_emailController.text}"
                            : "Masukkan email terdaftar untuk menerima kode token.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Card Form Input
                      Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            if (!_isTokenSent)
                              // Input Email
                              TextFormField(
                                controller: _emailController,
                                style: const TextStyle(color: Colors.white),
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: "Email",
                                  labelStyle: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    color: colorAccent,
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: colorAccent),
                                  ),
                                ),
                              )
                            else
                              // Input Token
                              TextFormField(
                                controller: _tokenController,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  letterSpacing: 5,
                                  fontWeight: FontWeight.bold,
                                ),
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                maxLength: 6,
                                decoration: InputDecoration(
                                  counterText: "",
                                  hintText: "000000",
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: colorAccent),
                                  ),
                                ),
                              ),

                            const SizedBox(height: 40),

                            // Button Action
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : (_isTokenSent
                                          ? _verifyOtpAndShowPasswordDialog
                                          : _sendOtp),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorAccent,
                                  foregroundColor: colorBottom,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? CircularProgressIndicator(
                                        color: colorBottom,
                                      )
                                    : Text(
                                        _isTokenSent
                                            ? "VERIFIKASI KODE"
                                            : "KIRIM KODE",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Tombol Ganti Email (Jika salah ketik)
                      if (_isTokenSent)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isTokenSent = false;
                              _tokenController.clear();
                            });
                          },
                          child: const Text(
                            "Salah Email? Kembali",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}