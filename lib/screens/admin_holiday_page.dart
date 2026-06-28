import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../models/holiday.dart';
import '../theme/app_colors.dart';

class AdminHolidayPage extends StatefulWidget {
  const AdminHolidayPage({super.key});

  @override
  State<AdminHolidayPage> createState() => _AdminHolidayPageState();
}

class _AdminHolidayPageState extends State<AdminHolidayPage> {
  List<Holiday> _holidays = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHolidays();
  }

  Future<void> _loadHolidays() async {
    setState(() => _isLoading = true);
    final data = await AdminService.getHolidays();
    setState(() {
      _holidays = data;
      _isLoading = false;
    });
  }

  Future<void> _addHoliday() async {
    DateTime selectedDate = DateTime.now();
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tambah Hari Libur'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Tanggal'),
                subtitle: Text("${selectedDate.toLocal()}".split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = picked);
                  }
                },
              ),
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Keterangan'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final success = await AdminService.addHoliday(
                  "${selectedDate.toLocal()}".split(' ')[0],
                  controller.text,
                );
                if (success) {
                  Navigator.pop(context);
                  _loadHolidays();
                }
              },
              child: const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Atur Hari Libur')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadHolidays,
              child: _holidays.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_available_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('Tidak ada hari libur terjadwal', style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _holidays.length,
                    itemBuilder: (context, index) {
                      final h = _holidays[index];
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.red.shade100),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.event_busy_rounded, color: Colors.red),
                          ),
                          title: Text(
                            h.keterangan,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            h.tanggal,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey),
                            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: const Text('Hapus Hari Libur?'),
                                  content: const Text('Tindakan ini akan mengaktifkan kembali reminder pada tanggal tersebut.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
                                    TextButton(
                                      onPressed: () => Navigator.pop(c, true), 
                                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                                      child: const Text('Hapus'),
                                    ),
                                  ],
                                ),
                              );
                              if (ok == true) {
                                await AdminService.deleteHoliday(h.id);
                                _loadHolidays();
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addHoliday,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Libur'),
      ),
    );
  }
}
