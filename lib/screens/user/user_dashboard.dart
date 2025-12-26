import 'dart:async';
import 'package:flutter/material.dart';
import 'package:m_banking/screens/auth/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/customer_user.dart';
import '../../models/transaction_model.dart';
import '../../models/api_response.dart';
import '../../services/transaction_service.dart';
import '../../services/notification_service.dart'; // Pastikan file ini sudah dibuat
import '../../utils/format_extensions.dart';
import 'deposit_page.dart';
import 'withdrawal_page.dart';
import 'transfer_page.dart';
import 'profil_page.dart';
import 'ai_assistant_page.dart';

class UserDashboard extends StatefulWidget {
  final String userId;
  final dynamic user;

  const UserDashboard({super.key, required this.user, required this.userId});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  late CustomerUser _currentUser;
  final _transactionService = TransactionService();
  bool _isRefreshing = false;
  late RealtimeChannel _transactionChannel;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _fetchProfile();
    _listenToNewTransactions(); // Inisialisasi Realtime Notifikasi
  }

  @override
  void dispose() {
    // Tutup koneksi realtime saat halaman ditutup/logout
    Supabase.instance.client.removeChannel(_transactionChannel);
    super.dispose();
  }

  /// 1. REAL-TIME LISTENER: Menunggu Uang Masuk
  void _listenToNewTransactions() {
    _transactionChannel = Supabase.instance.client
        .channel('public:transactions')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'transactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: widget.userId,
          ),
          callback: (payload) {
            final newTx = payload.newRecord;
            final type = newTx['type'];
            final amount = (newTx['amount'] as num).toDouble();

            // Pemicu Notifikasi jika ada Deposit atau Transfer Masuk
            if (type == 'deposit' || type == 'transfer_in') {
              NotificationService.showNotification(
                title: "Uang Masuk! 💰",
                body: "Berhasil menerima saldo sebesar ${amount.toIDR()}",
              );
              _fetchProfile(); // Otomatis update saldo di layar
            }
          },
        )
        .subscribe();
  }

  /// 2. FUNGSI LOGOUT (KEAMANAN PENUH)
  Future<void> _handleLogout() async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Logout"),
        content: const Text("Apakah Anda yakin ingin keluar?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Keluar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // 1. Putuskan sesi Supabase
        await Supabase.instance.client.auth.signOut();

        // 2. Navigasi Paksa (Gunakan ini jika pushNamed gagal)
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ), // Panggil class Login langsung
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      }
    }
  }

  /// 3. REFRESH DATA PROFIL
  Future<void> _fetchProfile() async {
    setState(() => _isRefreshing = true);
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', widget.userId)
          .single();

      setState(() {
        _currentUser = CustomerUser(
          id: data['id'],
          email: data['email'],
          accountNumber: data['account_number'] ?? '-',
          balance: (data['balance'] as num).toDouble(),
          pin: data['pin'],
        );
      });
    } catch (e) {
      debugPrint("Error Refresh: $e");
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  void _navigateTo(Widget page) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
    if (result == true) _fetchProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("M-Banking Dashboard"),
        backgroundColor: const Color(0xFF1A9591), // DIUBAH: Indigo -> Teal
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _fetchProfile,
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.refresh),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _handleLogout),
        ],
      ),

      // FAB UNTUK AI ASSISTANT
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A9591), // DIUBAH: Indigo -> Teal
        onPressed: () => _navigateTo(AIAssistantPage(user: _currentUser)),
        child: const Icon(Icons.smart_toy, color: Colors.white),
      ),

      body: RefreshIndicator(
        onRefresh: _fetchProfile,
        color: const Color(0xFF1A9591), // DIUBAH: Indigo -> Teal
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBalanceCard(),
              const SizedBox(height: 30),
              _buildMenuGrid(),
              const SizedBox(height: 30),
              const Text(
                "Riwayat Transaksi",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              _buildTransactionHistory(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A9591), // DIUBAH: Indigo -> Teal
            Color(0xFF67C3C0), // DIUBAH: IndigoAccent -> Light Teal
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A9591).withOpacity(0.3), // DIUBAH: Shadow Teal
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Saldo Aktif", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            _currentUser.balance.toIDR(),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "No. Rekening: ${_currentUser.accountNumber}",
            style: const TextStyle(color: Colors.white, letterSpacing: 1.2),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _menuItem(
          Icons.add_circle,
          "TopUp",
          () => _navigateTo(DepositPage(user: _currentUser)),
        ),
        _menuItem(
          Icons.account_balance_wallet,
          "Tarik",
          () => _navigateTo(WithdrawalPage(user: _currentUser)),
        ),
        _menuItem(
          Icons.send,
          "Transfer",
          () => _navigateTo(TransferPage(user: _currentUser)),
        ),
        _menuItem(
          Icons.person,
          "Profil",
          () => _navigateTo(ProfilePage(user: _currentUser)),
        ),
      ],
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFF1A9591).withOpacity(0.1), // DIUBAH: Teal Soft Background
              borderRadius: BorderRadius.circular(15),
            ),
            child:  Icon(icon, color: Color(0xFF1A9591), size: 28), // DIUBAH: Icon Teal
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory() {
    return FutureBuilder<ApiResponse<List<TransactionModel>>>(
      future: _transactionService.getTransactionHistory(_currentUser.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator(color: Color(0xFF1A9591)));
        final history = snapshot.data?.data ?? [];
        if (history.isEmpty)
          return const Center(child: Text("Tidak ada transaksi."));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final tx = history[index];
            final bool isCredit =
                tx.type == 'deposit' || tx.type == 'transfer_in';
            return Card(
              child: ListTile(
                leading: Icon(
                  isCredit ? Icons.download : Icons.upload,
                  color: isCredit ? Colors.green : Colors.red,
                ),
                title: Text(tx.type.toUpperCase()),
                subtitle: Text(tx.description ?? "-"),
                trailing: Text(
                  "${isCredit ? '+' : '-'}${tx.amount.toIDR()}",
                  style: TextStyle(
                    color: isCredit ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}