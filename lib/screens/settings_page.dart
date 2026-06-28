import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'change_password_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Akun'),
          const SizedBox(height: 12),
          _buildCard([
            ListTile(
              leading: const Icon(Icons.lock_reset_rounded, color: AppColors.textSecondary),
              title: const Text('Ubah Password'),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordPage())),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSectionTitle('Aplikasi'),
          const SizedBox(height: 12),
          _buildCard([
            ListTile(
              leading: const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary),
              title: const Text('Tentang SiGapin'),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () => _showAboutDialog(context),
            ),
            const Divider(height: 1, indent: 50),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Ingin Logout?'),
                    content: const Text('Anda akan keluar dari akun anda saat ini.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
                      TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Logout')),
                    ],
                  ),
                );
                if (confirm == true) {
                  await AuthService.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                  }
                }
              },
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.secondaryDark),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_active, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              const Text('SiGapin', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Text('Versi Beta', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              const Text(
                'Sistem Informasi Gajah Pintar (SiGapin).',
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.5),
              ),
              const Divider(height: 32),
              const Text(
                'Powered By: Teknologi Informasi batch 39.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
