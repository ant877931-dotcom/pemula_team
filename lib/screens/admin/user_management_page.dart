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

  // 1. MENGAMBIL DATA USER
  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase
          .from('profiles')
          .select('*')
          .neq('role', 'admin'); // Hanya nasabah

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

  // 2. FITUR PENCARIAN
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

  // 3. UPDATE STATUS (BANNED/FREEZE/ACTIVE)
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

      await _fetchUsers(); // Refresh data
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Berhasil mengubah status menjadi $action")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal mengubah status: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manajemen Nasabah"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Cari email atau no. rekening...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),

          // LIST USER
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                ? const Center(child: Text("Nasabah tidak ditemukan"))
                : RefreshIndicator(
                    onRefresh: _fetchUsers,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        final status = user['status'] ?? 'active';

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(status),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              user['email'] ?? 'No Email',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              "Acc: ${user['account_number']}\nSaldo: ${(user['balance'] as num).toDouble().toIDR()}",
                              style: const TextStyle(fontSize: 12),
                            ),
                            isThreeLine: true,
                            trailing: PopupMenuButton<String>(
                              onSelected: (val) =>
                                  _updateUserStatus(user['id'], val),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'active',
                                  child: Text("Aktifkan"),
                                ),
                                const PopupMenuItem(
                                  value: 'frozen',
                                  child: Text("Bekukan"),
                                ),
                                const PopupMenuItem(
                                  value: 'banned',
                                  child: Text("Blokir"),
                                ),
                              ],
                              icon: const Icon(Icons.more_vert),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'frozen':
        return Colors.orange;
      case 'banned':
        return Colors.red;
      default:
        return Colors.indigo;
    }
  }
}
