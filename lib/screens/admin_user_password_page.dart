import 'dart:async';
import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../models/user.dart';
import '../theme/app_colors.dart';

class AdminUserPasswordPage extends StatefulWidget {
  const AdminUserPasswordPage({super.key});

  @override
  State<AdminUserPasswordPage> createState() => _AdminUserPasswordPageState();
}

class _AdminUserPasswordPageState extends State<AdminUserPasswordPage> {
  final _searchController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  
  List<User> _searchResults = [];
  User? _selectedUser;
  bool _isSearching = false;
  bool _isSubmitting = false;
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _performSearch(query);
      } else {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);
    final results = await AdminService.searchUsers(query);
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  void _selectUser(User user) {
    setState(() {
      _selectedUser = user;
      _searchResults = [];
      _searchController.text = user.nim;
    });
  }

  Future<void> _submit() async {
    if (_selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih user terlebih dahulu')),
      );
      return;
    }

    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password baru tidak boleh kosong')),
      );
      return;
    }

    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi password tidak cocok')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Konfirmasi Perubahan'),
        content: Text('Anda yakin ingin mengubah password untuk ${_selectedUser!.nama} (${_selectedUser!.nim})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Ya, Ubah'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);
    final res = await AdminService.adminChangePassword(_selectedUser!.nim, _passwordController.text);
    setState(() => _isSubmitting = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password berhasil diperbarui')),
      );
      if (mounted) Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Gagal memperbarui password'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ganti Password User')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pencarian User',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.secondaryDark),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Ketik NIM Mahasiswa',
                hintText: 'Contoh: 2022110001',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ) : (_searchController.text.isNotEmpty ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _selectedUser = null;
                      _searchResults = [];
                    });
                  },
                ) : null),
                border: const OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
            ),
            
            if (_searchResults.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _searchResults.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    return ListTile(
                      title: Text(user.nama),
                      subtitle: Text('${user.nim} - ${user.jurusan ?? ''} ${user.angkatan ?? ''}'),
                      onTap: () => _selectUser(user),
                    );
                  },
                ),
              ),
            ],

            if (_selectedUser != null) ...[
              const SizedBox(height: 24),
              Card(
                color: AppColors.primary.withOpacity(0.05),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const CircleAvatar(child: Icon(Icons.person)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_selectedUser!.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('NIM: ${_selectedUser!.nim}'),
                            Text('Role: ${_selectedUser!.role}'),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => setState(() => _selectedUser = null),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Password Baru',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.secondaryDark),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Input Password Baru',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Konfirmasi Password Baru',
                  prefixIcon: Icon(Icons.check_circle_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: AppColors.primary,
                ),
                child: _isSubmitting 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Simpan Perubahan Password', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
