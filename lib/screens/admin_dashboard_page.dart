import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  Map<String, dynamic>? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() => _isLoading = true);
    final data = await AdminService.getAdminSummary();
    setState(() {
      _summary = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard Analytics')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSummary,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _cardStat('Total User Reachable', '${_summary?['total_reachable'] ?? 0}', Icons.people, Colors.orange),
                        _cardStat('Status Reminder', _summary?['is_muted'] == true ? 'Muted' : 'Aktif', 
                            _summary?['is_muted'] == true ? Icons.notifications_off : Icons.notifications_active,
                            _summary?['is_muted'] == true ? Colors.red : Colors.green),
                      ],
                    ),
                    if (_summary?['is_muted'] == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text('Alasan Mute: ${_summary?['mute_reason']}', 
                            style: const TextStyle(color: Colors.red, fontSize: 12, fontStyle: FontStyle.italic)),
                      ),
                    const SizedBox(height: 24),
                    const Text('Broadcast Terakhir', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...(_summary?['recent_broadcasts'] as List? ?? []).map((b) => Card(
                      child: ListTile(
                        title: Text(b['judul']),
                        subtitle: Text('Terkirim: ${b['created_at']}'),
                        trailing: Text('${b['recipients_count'] ?? 0} Penerima'),
                      ),
                    )),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _cardStat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
