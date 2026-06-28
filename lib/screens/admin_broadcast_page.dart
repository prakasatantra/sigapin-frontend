import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/auth_service.dart';
import '../services/admin_service.dart';
import '../services/master_data_service.dart';
import '../models/jurusan.dart';
import '../models/angkatan.dart';
import '../models/kelas.dart';
import '../theme/app_colors.dart';

class AdminBroadcastPage extends StatefulWidget {
  const AdminBroadcastPage({super.key});

  @override
  State<AdminBroadcastPage> createState() => _AdminBroadcastPageState();
}

class _AdminBroadcastPageState extends State<AdminBroadcastPage> {
  final _judulController = TextEditingController();
  final _isiController = TextEditingController();
  
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  
  List<Jurusan> _jurusanList = [];
  List<Angkatan> _angkatanList = [];
  List<Kelas> _kelasList = [];
  
  String? _selectedJurusan;
  String? _selectedAngkatan;
  String? _selectedKelas;
  bool _isLoading = false;
  int? _totalTarget;
  int? _estimasiReachable;

  @override
  void initState() {
    super.initState();
    _loadFilters();
    _updatePreview();
  }

  Future<void> _updatePreview() async {
    final preview = await AdminService.getBroadcastPreview(
      jurusan: _selectedJurusan,
      angkatan: _selectedAngkatan,
      kelas: _selectedKelas,
    );
    if (preview != null && mounted) {
      setState(() {
        _totalTarget = preview['total_target'];
        _estimasiReachable = preview['estimasi_reachable'];
      });
    }
  }

  Future<void> _loadFilters() async {
    final j = await MasterDataService.getJurusan();
    final a = await MasterDataService.getAngkatan();
    final k = await MasterDataService.getKelas();
    setState(() {
      _jurusanList = j;
      _angkatanList = a;
      _kelasList = k;
    });
  }

  Future<void> _pickImage() async {
    // Request permission based on platform and version
    PermissionStatus status;
    if (Platform.isAndroid) {
      // For Android 13+ (API 33+), we need photos permission
      // For older versions, we need storage permission
      status = await Permission.photos.status;
      if (status.isDenied) {
        status = await Permission.photos.request();
      }
      
      if (status.isPermanentlyDenied) {
        // Fallback for older Android or if photos permission doesn't apply
        status = await Permission.storage.request();
      }
    } else {
      status = await Permission.photos.request();
    }

    if (status.isGranted || status.isLimited) {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } else if (status.isPermanentlyDenied) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Izin Akses Galeri'),
            content: const Text('Aplikasi membutuhkan izin untuk mengakses galeri. Silakan aktifkan di pengaturan.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c), child: const Text('Batal')),
              TextButton(onPressed: () => openAppSettings(), child: const Text('Buka Pengaturan')),
            ],
          ),
        );
      }
    }
  }

  Future<void> _send() async {
    if (_judulController.text.isEmpty || _isiController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul dan Isi wajib diisi')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Kirim Broadcast?'),
        content: Text('Pesan akan dikirimkan ke $_estimasiReachable perangkat yang aktif.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Kirim')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    
    final response = await AdminService.sendBroadcast(
      judul: _judulController.text,
      isi: _isiController.text,
      targetJurusan: _selectedJurusan,
      targetAngkatan: _selectedAngkatan,
      targetKelas: _selectedKelas,
      imageFile: _selectedImage,
    );
    
    setState(() => _isLoading = false);

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Broadcast Berhasil Dikirim')),
      );
      if (mounted) Navigator.of(context).pop();
    } else {
      final msg = response['message'] ?? 'Gagal mengirim broadcast';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red.shade800,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Broadcast Baru')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('Konten Pesan'),
            const SizedBox(height: 12),
            TextField(
              controller: _judulController,
              decoration: const InputDecoration(labelText: 'Judul Notifikasi', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _isiController,
              decoration: const InputDecoration(labelText: 'Isi Pesan', border: OutlineInputBorder()),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    if (_selectedImage != null) ...[
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(_selectedImage!, height: 150, width: double.infinity, fit: BoxFit.cover),
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: () {
                                  setState(() {
                                    _selectedImage = null;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_search, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(_selectedImage == null ? 'Pilih Gambar Poster' : 'Ganti Gambar', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSection('Target Penerima'),
            const SizedBox(height: 12),
            _buildDropdown('Filter Jurusan', _selectedJurusan, _jurusanList.map((e) => DropdownMenuItem(value: e.kodeTag, child: Text(e.namaJurusan))).toList(), (v) {
              setState(() => _selectedJurusan = v);
              _updatePreview();
            }),
            const SizedBox(height: 12),
            _buildDropdown('Filter Angkatan', _selectedAngkatan, _angkatanList.map((e) => DropdownMenuItem(value: e.tahun, child: Text(e.tahun))).toList(), (v) {
              setState(() => _selectedAngkatan = v);
              _updatePreview();
            }),
            const SizedBox(height: 12),
            _buildDropdown('Filter Kelas', _selectedKelas, _kelasList.map((e) => DropdownMenuItem(value: e.kodeTag, child: Text(e.namaKelas))).toList(), (v) {
              setState(() => _selectedKelas = v);
              _updatePreview();
            }),
            const SizedBox(height: 24),
            if (_totalTarget != null) _buildPreviewCard(),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _send,
              icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_rounded),
              label: const Text('Kirim'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.secondaryDark));
  }

  Widget _buildDropdown(String label, String? value, List<DropdownMenuItem<String>> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
      items: [const DropdownMenuItem(value: null, child: Text('Semua')), ...items],
      onChanged: onChanged,
    );
  }

  Widget _buildPreviewCard() {
    bool isZero = (_estimasiReachable ?? 0) == 0;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isZero ? Colors.orange.shade50 : AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isZero ? Colors.orange.shade200 : AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('Total Mahasiswa', '$_totalTarget', Icons.storage_rounded, AppColors.textSecondary),
              Container(width: 1, height: 30, color: isZero ? Colors.orange.shade200 : AppColors.primary.withOpacity(0.2)),
              _statItem(
                'Mahasiswa Aktif',
                '$_estimasiReachable', 
                Icons.cell_tower_rounded, 
                isZero ? Colors.orange.shade700 : AppColors.secondary
              ),
            ],
          ),
        ),
        if (isZero)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange.shade800),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Belum ada mahasiswa di filter ini yang terdaftar di sistem notifikasi.',
                    style: TextStyle(fontSize: 11, color: Colors.orange.shade900),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _statItem(String label, String val, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
        Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.8))),
      ],
    );
  }
}
