// lib/screens/admin/user_management_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/format_extensions.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // --- PALET WARNA ---
  final Color colorTop = const Color(0xFF007AFF);    
  final Color colorBottom = const Color(0xFF003366); 
  final Color colorGold = const Color(0xFFFFD700);   

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _searchController.addListener(_filterSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase
          .from('profiles')
          .select('*')
          .neq('role', 'admin')
          .order('created_at', ascending: false); // Urutkan dari yang terbaru

      setState(() {
        _allUsers = List<Map<String, dynamic>>.from(data);
        _filteredUsers = _allUsers;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error Fetch: $e");
      setState(() => _isLoading = false);
    }
  }

  void _filterSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        final email = (user['email'] ?? '').toString().toLowerCase();
        final acc = (user['account_number'] ?? '').toString().toLowerCase();
        return email.contains(query) || acc.contains(query);
      }).toList();
    });
  }

  Future<void> _updateUserStatus(String userId, String action) async {
    try {
      Map<String, dynamic> updateData = {};

      if (action == 'active') {
        updateData = {'is_frozen': false, 'is_banned': false};
      } else if (action == 'frozen') {
        updateData = {'is_frozen': true, 'is_banned': false};
      } else if (action == 'banned') {
        updateData = {'is_frozen': false, 'is_banned': true};
      }

      await _supabase.from('profiles').update(updateData).eq('id', userId);
      await _fetchUsers();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Status nasabah diperbarui: ${action.toUpperCase()}"),
            backgroundColor: colorBottom,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal mengubah status: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text(
          "MANAJEMEN NASABAH", 
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16)
        ),
        centerTitle: true,
        backgroundColor: colorBottom,
        foregroundColor: colorGold,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // HEADER SEARCH (Floating Style)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            decoration: BoxDecoration(
              color: colorBottom,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Cari Email atau No. Rekening...",
                    hintStyle: TextStyle(color: Color(0xFF003366), fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded, color: colorBottom),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
              ),
            ),
          ),

          // LIST USER
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: colorBottom))
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off_rounded, size: 60, color: Colors.grey[300]),
                            const SizedBox(height: 10),
                            Text("Nasabah tidak ditemukan", style: TextStyle(color: Colors.grey[500])),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchUsers,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: _filteredUsers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            
                            // Logika Status
                            bool isBanned = user['is_banned'] ?? false;
                            bool isFrozen = user['is_frozen'] ?? false;
                            String statusLabel = "Aktif";
                            Color statusColor = Colors.green;
                            
                            if (isBanned) {
                              statusLabel = "Diblokir";
                              statusColor = Colors.red;
                            } else if (isFrozen) {
                              statusLabel = "Dibekukan";
                              statusColor = Colors.orange;
                            }

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                                ],
                                border: Border.all(color: isBanned ? Colors.red.withOpacity(0.3) : Colors.transparent),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: colorBottom.withOpacity(0.1),
                                  child: Text(
                                    (user['email'] ?? "U").substring(0, 1).toUpperCase(),
                                    style: TextStyle(color: colorBottom, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        user['email'] ?? 'No Email',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      "Acc: ${user['account_number'] ?? '-'}",
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      (user['balance'] as num).toDouble().toIDR(),
                                      style: TextStyle(
                                        color: colorBottom, 
                                        fontWeight: FontWeight.w800, 
                                        fontSize: 13
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    // Status Chip
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: statusColor.withOpacity(0.5), width: 0.5),
                                      ),
                                      child: Text(
                                        statusLabel,
                                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Action Menu
                                    SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: PopupMenuButton<String>(
                                        padding: EdgeInsets.zero,
                                        icon: Icon(Icons.more_horiz, color: Colors.grey[400]),
                                        onSelected: (val) => _updateUserStatus(user['id'], val),
                                        itemBuilder: (context) => [
                                          _buildMenuItem('active', "Aktifkan Akun", Icons.check_circle_outline, Colors.green),
                                          _buildMenuItem('frozen', "Bekukan Sementara", Icons.ac_unit, Colors.orange),
                                          _buildMenuItem('banned', "Blokir Permanen", Icons.block, Colors.red),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(String value, String label, IconData icon, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}