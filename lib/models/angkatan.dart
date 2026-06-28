class Angkatan {
  final int id;
  final String tahun;

  Angkatan({
    required this.id,
    required this.tahun,
  });

  factory Angkatan.fromJson(Map<String, dynamic> json) {
    return Angkatan(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      tahun: json['tahun']?.toString() ?? '',
    );
  }
}
