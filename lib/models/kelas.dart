class Kelas {
  final int id;
  final String namaKelas;
  final String kodeTag;

  Kelas({
    required this.id,
    required this.namaKelas,
    required this.kodeTag,
  });

  factory Kelas.fromJson(Map<String, dynamic> json) {
    return Kelas(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      namaKelas: json['nama_kelas']?.toString() ?? '',
      kodeTag: json['kode_tag']?.toString() ?? '',
    );
  }
}
