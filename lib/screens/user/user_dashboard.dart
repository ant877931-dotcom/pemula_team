// lib/screens/user/user_dashboard.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:m_banking/screens/auth/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/customer_user.dart';
import '../../models/transaction_model.dart';
import '../../models/api_response.dart';
import '../../services/transaction_service.dart';
import '../../services/notification_service.dart';
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
  late RealtimeChannel _transactionChannel;

  // --- PALET WARNA ---
  final Color colorTop = const Color(0xFF007AFF);    
  final Color colorBottom = const Color(0xFF003366); 
  final Color colorGold = const Color(0xFFFFD700);   

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _fetchProfile();
    _listenToNewTransactions();
  }

  @override
  void dispose() {
    Supabase.instance.client.removeChannel(_transactionChannel);
    super.dispose();
  }

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

            if (type == 'deposit' || type == 'transfer_in') {
              NotificationService.showNotification(
                title: "Uang Masuk! 💰",
                body: "Berhasil menerima saldo sebesar ${amount.toIDR()}",
              );
              _fetchProfile();
            }
          },
        )
        .subscribe();
  }

  Future<void> _handleLogout() async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Konfirmasi Logout"),
        content: const Text("Apakah Anda yakin ingin keluar?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Keluar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client.auth.signOut();
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> _fetchProfile() async {
    try {
      final data = await Supabase.instance.client.from('profiles').select().eq('id', widget.userId).single();
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
    }
  }

  void _navigateTo(Widget page) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (result == true) _fetchProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          // Latar belakang biru melengkung yang lebih luas untuk menampung greeting
          Container(
            height: 300,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colorTop, colorBottom],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),
          
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _fetchProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    _buildCustomAppBar(),
                    const SizedBox(height: 20),
                    _buildGreetingHeader(), // Widget Kata Pembuka Baru
                    const SizedBox(height: 25),
                    _buildBalanceCard(),
                    const SizedBox(height: 30),
                    _buildMenuGrid(),
                    const SizedBox(height: 35),
                    const Text(
                      "Aktivitas Terakhir",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                    ),
                    const SizedBox(height: 15),
                    _buildTransactionHistory(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    
    );
  }

  // --- WIDGET KATA PEMBUKA (WELCOME HEADER) ---
  Widget _buildGreetingHeader() {
    String userName = _currentUser.email.split('@')[0];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Welcome to,",
          style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w400),
        ),
        Text(
          userName.toUpperCase(),
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.1),
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [colorTop, colorBottom]),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: colorGold,
              child: Icon(Icons.person, size: 40, color: colorBottom),
            ),
            accountName: const Text("User Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(_currentUser.email),
          ),
          ListTile(
            leading: Icon(Icons.person_outline, color: colorTop),
            title: const Text("Profil Saya"),
            onTap: () {
              Navigator.pop(context);
              _navigateTo(ProfilePage(user: _currentUser));
            },
          ),
          ListTile(
            leading: Icon(Icons.smart_toy_outlined, color: colorTop),
            title: const Text("AI Assistant"),
            trailing: Icon(Icons.circle, color: colorGold, size: 10),
            onTap: () {
              Navigator.pop(context);
              _navigateTo(AIAssistantPage(user: _currentUser));
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFF003366)),
            title: const Text("Logout", style: TextStyle(color:Color(0xFF003366), fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context);
              _handleLogout();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Builder(
      builder: (context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.menu_open_rounded, color: colorGold, size: 32),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
          
          const SizedBox(width: 48), 
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: colorGold.withOpacity(0.3), width: 1.5), 
        boxShadow: [
          BoxShadow(color: colorBottom.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Saldo Tersedia", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
              Icon(Icons.shield_rounded, color: colorGold, size: 22),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _currentUser.balance.toIDR(),
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: colorBottom),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorBottom.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "No. Rekening: ${_currentUser.accountNumber}",
              style: TextStyle(color: colorBottom, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _menuItem(Icons.add_circle_rounded, "TopUp", () => _navigateTo(DepositPage(user: _currentUser))),
          _menuItem(Icons.account_balance_wallet_rounded, "Tarik", () => _navigateTo(WithdrawalPage(user: _currentUser))),
          _menuItem(Icons.send_rounded, "Transfer", () => _navigateTo(TransferPage(user: _currentUser))),
          _menuItem(Icons.history_rounded, "Update", () => _fetchProfile()),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 55, width: 55,
            decoration: BoxDecoration(
              color: colorTop.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colorTop, size: 28), 
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory() {
    return FutureBuilder<ApiResponse<List<TransactionModel>>>(
      future: _transactionService.getTransactionHistory(_currentUser.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ));
        }
        final history = snapshot.data?.data ?? [];
        if (history.isEmpty) return const Center(child: Text("Tidak ada aktivitas transaksi."));

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: history.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final tx = history[index];
            final bool isCredit = tx.type == 'deposit' || tx.type == 'transfer_in';
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isCredit ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  child: Icon(isCredit ? Icons.add : Icons.remove, color: isCredit ? Colors.green : Colors.red, size: 18),
                ),
                title: Text(tx.type.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text(tx.description ?? "-", style: const TextStyle(fontSize: 11)),
                trailing: Text(
                  "${isCredit ? '+' : '-'}${tx.amount.toIDR()}",
                  style: TextStyle(color: isCredit ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            );
          },
        );
      },
    );
  }
}