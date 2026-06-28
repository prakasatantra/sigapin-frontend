import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import 'admin_broadcast_page.dart';
import 'admin_dashboard_page.dart';
import 'admin_holiday_page.dart';
import 'admin_schedule_page.dart';
import 'admin_user_password_page.dart';
import 'change_password_page.dart';
import 'notification_list_page.dart';
import 'settings_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUnread();
  }

  Future<void> _fetchUnread() async {
    await AuthService.refreshUserInfo();
    final count = await NotificationService.getUnreadCount();
    if (mounted) {
      setState(() => _unreadCount = count);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('No User Found')));
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('SiGapin', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchUnread,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(user),
              const SizedBox(height: 24),
              _buildSectionTitle('Layanan Utama'),
              const SizedBox(height: 12),
              _buildMainActions(user),
              const SizedBox(height: 24),
              if (user.role.toLowerCase() == 'admin') ...[
                _buildSectionTitle('Manajemen Sistem'),
                const SizedBox(height: 12),
                _buildAdminGrid(),
                const SizedBox(height: 24),
              ],
              _buildSectionTitle('Lainnya'),
              const SizedBox(height: 12),
              _actionTile(
                icon: Icons.settings_rounded,
                title: 'Pengaturan',
                subtitle: 'Akun, Password, dan lainnya',
                color: Colors.blueGrey,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundColor: Colors.white24,
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selamat Datang,',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      user.nama,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoTile('Role', user.role.toUpperCase()),
              if (user.namaJurusan != null) _infoTile('Jurusan', user.namaJurusan!),
              if (user.angkatan != null) _infoTile('Angkatan', user.angkatan!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.secondaryDark),
    );
  }

  Widget _buildMainActions(user) {
    return Column(
      children: [
        _actionTile(
          icon: Icons.notifications_active_rounded,
          title: 'Kotak Masuk',
          subtitle: 'Lihat pengumuman & pengingat',
          color: AppColors.primaryDark,
          badgeCount: _unreadCount,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationListPage()),
            ).then((_) => _fetchUnread());
          },
        ),
      ],
    );
  }

  Widget _buildAdminGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _adminCard(Icons.insights, 'Analisis', 'Sistem', Colors.orange, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardPage()));
        }),
        _adminCard(Icons.campaign, 'Broadcast', 'Kirim Pesan', Colors.deepPurple, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminBroadcastPage()));
        }),
        _adminCard(Icons.event_note, 'Hari Libur', 'Auto-Mute', Colors.red, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminHolidayPage()));
        }),
        _adminCard(Icons.alarm, 'Jadwal', 'Reminder', Colors.green, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminSchedulePage()));
        }),
        _adminCard(Icons.password_rounded, 'Manage Password', 'Lupa Password', Colors.blue, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUserPasswordPage()));
        }),
      ],
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    int badgeCount = 0,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: badgeCount > 0 
          ? Badge(label: Text('$badgeCount'))
          : const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _adminCard(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

}
