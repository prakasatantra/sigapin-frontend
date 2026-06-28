class Jurusan {
  final int id;
  final String namaJurusan;
  final String kodeTag;

  Jurusan({
    required this.id,
    required this.namaJurusan,
    required this.kodeTag,
  });

  factory Jurusan.fromJson(Map<String, dynamic> json) {
    return Jurusan(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      namaJurusan: json['nama_jurusan']?.toString() ?? '',
      kodeTag: json['kode_tag']?.toString() ?? '',
    );
  }
}
