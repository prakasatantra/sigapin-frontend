import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../models/pesan_template.dart';
import '../theme/app_colors.dart';

class AdminTemplatePage extends StatefulWidget {
  const AdminTemplatePage({super.key});

  @override
  State<AdminTemplatePage> createState() => _AdminTemplatePageState();
}

class _AdminTemplatePageState extends State<AdminTemplatePage> {
  List<PesanTemplate> _templates = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    final data = await AdminService.getTemplates();
    setState(() {
      _templates = data;
      _isLoading = false;
    });
  }

  Future<void> _editTemplate(PesanTemplate t) async {
    final controller = TextEditingController(text: t.isiPesan);
    bool isActive = t.isActive;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit Template: ${t.namaRole}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${t.namaJurusan ?? "Semua Jurusan"} - ${t.waktuTipe}', 
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Isi Pesan',
                  hintText: 'Gunakan {sapaan} untuk sapaan dinamis',
                  border: OutlineInputBorder(),
                ),
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
                final success = await AdminService.updateTemplate(
                  id: t.id,
                  isiPesan: controller.text,
                  isActive: isActive ? 1 : 0,
                );
                if (success) {
                  Navigator.pop(context);
                  _loadTemplates();
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
      appBar: AppBar(title: const Text('Template Pesan Reminder')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTemplates,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _templates.length,
                itemBuilder: (context, index) {
                  final t = _templates[index];
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: t.isActive ? AppColors.primary.withOpacity(0.2) : Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${t.namaRole.toUpperCase()} (${t.waktuTipe.toUpperCase()})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: t.isActive ? Colors.green.shade50 : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              t.isActive ? 'AKTIF' : 'NONAKTIF',
                              style: TextStyle(
                                fontSize: 9, 
                                fontWeight: FontWeight.bold, 
                                color: t.isActive ? Colors.green.shade700 : Colors.red.shade700
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          if (t.namaJurusan != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.school_outlined, size: 14, color: AppColors.secondary),
                                  const SizedBox(width: 4),
                                  Text(t.namaJurusan!, style: const TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              t.isiPesan,
                              style: const TextStyle(fontSize: 13, height: 1.4, fontStyle: FontStyle.italic),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _editTemplate(t),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
