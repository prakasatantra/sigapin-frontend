import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../theme/app_colors.dart';

class DirekturDashboardPage extends StatefulWidget {
  const DirekturDashboardPage({super.key});

  @override
  State<DirekturDashboardPage> createState() => _DirekturDashboardPageState();
}

class _DirekturDashboardPageState extends State<DirekturDashboardPage> {
  Map<String, dynamic>? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() => _isLoading = true);
    final data = await AdminService.getDirekturSummary();
    setState(() {
      _summary = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analitik Direktur')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSummary,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ringkasan Bulan Ini', 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _cardStat('Total Broadcast', '${_summary?['total_broadcast_bulan_ini'] ?? 0}', AppColors.secondary),
                        _cardStat('Rata-rata Baca', '${_summary?['avg_read_rate'] ?? 0}%', Colors.green),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('Broadcast Paling Populer', 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...(_summary?['top_broadcasts'] as List? ?? []).map((b) => Card(
                      child: ListTile(
                        title: Text(b['judul']),
                        subtitle: Text('Penerima: ${b['recipients_count']}'),
                        trailing: Text('${b['read_count']} Dibaca', 
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
                      ),
                    )),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _cardStat(String label, String value, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: color)),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
