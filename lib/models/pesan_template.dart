class PesanTemplate {
  final int id;
  final String namaRole;
  final String? namaJurusan;
  final String waktuTipe;
  final String isiPesan;
  final bool isActive;

  PesanTemplate({
    required this.id,
    required this.namaRole,
    this.namaJurusan,
    required this.waktuTipe,
    required this.isiPesan,
    required this.isActive,
  });

  factory PesanTemplate.fromJson(Map<String, dynamic> json) {
    return PesanTemplate(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      namaRole: json['nama_role']?.toString() ?? '',
      namaJurusan: json['nama_jurusan']?.toString(),
      waktuTipe: json['waktu_tipe']?.toString() ?? '',
      isiPesan: json['isi_pesan']?.toString() ?? '',
      isActive: (json['is_active']?.toString() == '1'),
    );
  }
}
