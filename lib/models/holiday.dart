class Holiday {
  final int id;
  final String tanggal;
  final String keterangan;

  Holiday({
    required this.id,
    required this.tanggal,
    required this.keterangan,
  });

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      tanggal: json['tanggal']?.toString() ?? '',
      keterangan: json['keterangan']?.toString() ?? '',
    );
  }
}
