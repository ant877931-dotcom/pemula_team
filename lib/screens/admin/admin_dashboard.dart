// lib/screens/admin/admin_dashboard.dart

import 'package:flutter/material.dart';
import 'package:m_banking/screens/auth/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/format_extensions.dart';
import 'admin_ai_page.dart';
import 'user_management_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;

  int _activeUsers = 0;
  int _frozenUsers = 0;
  int _bannedUsers = 0;
  double _totalBalance = 0;
  String _adminEmail = "Administrator";

 
  final Color colorTop = const Color(0xFF007AFF);
  final Color colorBottom = const Color(0xFF003366);
  final Color colorGold = const Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    _fetchAdminStats();
    _getCurrentAdminInfo();
  }

  void _getCurrentAdminInfo() {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      setState(() {
        _adminEmail = user.email ?? "Administrator";
      });
    }
  }

  Future<void> _fetchAdminStats() async {
    setState(() => _isLoading = true);
    try {
      final List<dynamic> users = await _supabase
          .from('profiles')
          .select('is_frozen, is_banned, balance')
          .neq('role', 'admin');

      int active = 0;
      int frozen = 0;
      int banned = 0;
      double totalBal = 0;

      for (var u in users) {
        totalBal += (u['balance'] as num).toDouble();
        if (u['is_banned'] == true) {
          banned++;
        } else if (u['is_frozen'] == true) {
          frozen++;
        } else {
          active++;
        }
      }

      setState(() {
        _activeUsers = active;
        _frozenUsers = frozen;
        _bannedUsers = banned;
        _totalBalance = totalBal;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error Fetch Admin: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)
          ),
        title: Column(
          children: [         
            Icon(
              Icons
             .admin_panel_settings_rounded, 
              size: 50,
              color: colorGold,
            ),
            const SizedBox(height: 12),
            Text(
              "Logout Admin",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorBottom, 
              ),
            ),
          ],
        ),
        content: Text(
          "Apakah Anda yakin ingin keluar dari sistem manajemen?",
          textAlign: TextAlign.center,
          style: TextStyle(color: colorBottom.withOpacity(0.8)),
        ),

        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actionsPadding: const EdgeInsets.only(bottom: 16),
        actions: [
       
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              "Batal",
              style: TextStyle(
                color: colorBottom, 
                fontWeight: FontWeight.normal,
              ),
            ),
          ),

         
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              "Keluar",
              style: TextStyle(
                color: colorTop, 
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _supabase.auth.signOut();
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      drawer: _buildDrawer(),
      body: Stack(
        children: [
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
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchAdminStats,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          _buildAdminAppBar(),
                          const SizedBox(height: 20),
                          _buildGreetingHeader(),
                          const SizedBox(height: 25),
                          _buildLiquidityCard(),
                          const SizedBox(height: 30),
                          _buildUserStatusGrid(),
                          const SizedBox(height: 30),
                          _buildChartSection(),
                          const SizedBox(height: 30),
                          const Text(
                            "Navigasi Kontrol",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(height: 15),
                          _buildAdminMenu(),
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
              child: Icon(
                Icons.admin_panel_settings_rounded,
                size: 40,
                color: colorBottom,
              ),
            ),
            accountName: const Text(
              "",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(_adminEmail),
          ),

          ListTile(
            leading: Icon(Icons.people_alt_rounded,
             color: colorTop
             ),
            title: const Text("Manajemen Nasabah"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserManagementPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.psychology_rounded,
             color: Colors.purple
             ),
            title: const Text("AI Business Analyst"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminAIPage()),
              );
            },
          ),

          const Spacer(),

          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, 
            color: Color(0xFF003366)
            ),
            title: const Text(
              "Logout",
              style: TextStyle(
                color: Color(0xFF003366),
                fontWeight: FontWeight.bold,
              ),
            ),
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

  Widget _buildAdminAppBar() {
    return Builder(
      builder: (context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.menu_open_rounded, 
            color: colorGold, size: 32),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildGreetingHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "System Overview,",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          "ADMIN",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildLiquidityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: colorGold.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: colorBottom.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
           
              Text(
                "Total Likuiditas Nasabah",
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(Icons.analytics_rounded, color: colorGold, size: 22),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _totalBalance.toIDR(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colorBottom,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Total akumulasi saldo seluruh akun terdaftar",
            style: TextStyle(
              color: Colors.grey[600], 
              fontSize: 11,
              ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStatusGrid() {
    return Row(
      children: [
        _statBox("Aktif", _activeUsers.toString(), Colors.blue),
        const SizedBox(width: 15),
        _statBox("Bekukan", _frozenUsers.toString(), Colors.orange),
        const SizedBox(width: 15),
        _statBox("Blokir", _bannedUsers.toString(), Colors.red),
      ],
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: color, 
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700], 
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03),
           blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Grafik Distribusi",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                lineBarsData: [
                  _lineData(Colors.blue, _activeUsers.toDouble()),
                  _lineData(Colors.orange, _frozenUsers.toDouble()),
                  _lineData(Colors.red, _bannedUsers.toDouble()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _lineData(Color color, double val) {
    return LineChartBarData(
      spots: [const FlSpot(0, 0), FlSpot(1, val)],
      isCurved: true,
      color: color,
      barWidth: 4,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(show: true, color: color.withOpacity(0.1)),
    );
  }

  Widget _buildAdminMenu() {
    return Column(
      children: [
        _adminMenuTile(
          "Manajemen Nasabah",
          "Kelola status",
          Icons.people_alt_rounded,
          colorTop,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UserManagementPage()),
          ),
        ),
        const SizedBox(height: 12),
        _adminMenuTile(
          "AI Business Analyst",
          "Prediksi dan analisis data sistem",
          Icons.psychology_rounded,
          Colors.purple,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminAIPage()),
          ),
        ),
      ],
    );
  }

  Widget _adminMenuTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02),
           blurRadius: 10),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(
            icon,
           color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 15),
        ),
   
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
