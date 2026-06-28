import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../models/reminder_schedule.dart';
import '../theme/app_colors.dart';

class AdminSchedulePage extends StatefulWidget {
  const AdminSchedulePage({super.key});

  @override
  State<AdminSchedulePage> createState() => _AdminSchedulePageState();
}

class _AdminSchedulePageState extends State<AdminSchedulePage> {
  List<ReminderSchedule> _schedules = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);
    final data = await AdminService.getSchedules();
    setState(() {
      _schedules = data;
      _isLoading = false;
    });
  }

  Future<void> _editSchedule(ReminderSchedule s) async {
    final timeController = TextEditingController(text: s.jamKirim);
    bool isActive = s.isActive;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit Schedule: ${s.namaRole} (${s.waktuTipe})'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: timeController,
                decoration: const InputDecoration(labelText: 'Jam Kirim (HH:MM)'),
              ),
              SwitchListTile(
                title: const Text('Aktif'),
                value: isActive,
                onChanged: (v) => setDialogState(() => isActive = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final success = await AdminService.updateSchedule(
                  id: s.id,
                  jamKirim: timeController.text,
                  isActive: isActive ? 1 : 0,
                );
                if (success) {
                  Navigator.pop(context);
                  _loadSchedules();
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Jadwal Reminder')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSchedules,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _schedules.length,
                itemBuilder: (context, index) {
                  final s = _schedules[index];
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (s.waktuTipe == 'pagi' ? Colors.orange : Colors.indigo).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          s.waktuTipe == 'pagi' ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
                          color: s.waktuTipe == 'pagi' ? Colors.orange : Colors.indigo,
                        ),
                      ),
                      title: Text(
                        '${s.namaRole.toUpperCase()} - ${s.waktuTipe.toUpperCase()}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Waktu Pengiriman: ${s.jamKirim.substring(0, 5)}',
                          style: const TextStyle(color: AppColors.secondaryDark, fontWeight: FontWeight.w500),
                        ),
                      ),
                      trailing: Switch(
                        value: s.isActive,
                        activeColor: Colors.green,
                        onChanged: (v) async {
                          await AdminService.updateSchedule(id: s.id, isActive: v ? 1 : 0);
                          _loadSchedules();
                        },
                      ),
                      onTap: () => _editSchedule(s),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
