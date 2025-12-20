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

  @override
  void initState() {
    super.initState();
    _fetchAdminStats();
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

  // FUNGSI LOGOUT
  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Logout Admin"),
        content: const Text("Apakah Anda yakin ingin keluar?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Keluar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _supabase.auth.signOut();
        if (mounted) {
          // NAVIGASI LANGSUNG KE CLASS LOGIN (Ganti 'LoginPage' dengan nama class login Anda)
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        debugPrint("Error Logout: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _fetchAdminStats,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout),
          ), // Tombol Logout di Atas
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Statistik Nasabah",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  _buildLineChart(),

                  const SizedBox(height: 25),

                  Row(
                    children: [
                      _statCard("Aktif", _activeUsers.toString(), Colors.blue),
                      const SizedBox(width: 10),
                      _statCard(
                        "Bekukan",
                        _frozenUsers.toString(),
                        Colors.orange,
                      ),
                      const SizedBox(width: 10),
                      _statCard("Blokir", _bannedUsers.toString(), Colors.red),
                    ],
                  ),

                  const SizedBox(height: 25),
                  const Text(
                    "Menu Navigasi",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  _menuTile(
                    "Manajemen Nasabah",
                    Icons.people,
                    Colors.indigo,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UserManagementPage(),
                        ),
                      );
                    },
                  ),
                  _menuTile(
                    "AI Business Analyst",
                    Icons.psychology,
                    Colors.purple,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminAIPage()),
                      );
                    },
                  ),
                  const Divider(height: 40),
                  // Menu Logout di bagian bawah daftar
                  _menuTile(
                    "Logout Akun Admin",
                    Icons.exit_to_app,
                    Colors.red,
                    _handleLogout,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLineChart() {
    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            _lineData(Colors.blue, _activeUsers.toDouble()),
            _lineData(Colors.orange, _frozenUsers.toDouble()),
            _lineData(Colors.red, _bannedUsers.toDouble()),
          ],
        ),
      ),
    );
  }

  LineChartBarData _lineData(Color color, double val) {
    return LineChartBarData(
      spots: [const FlSpot(0, 0), FlSpot(1, val)],
      isCurved: true,
      color: color,
      barWidth: 4,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(show: true, color: color.withOpacity(0.1)),
    );
  }

  Widget _statCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuTile(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(
            color: color == Colors.red ? Colors.red : Colors.black,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
