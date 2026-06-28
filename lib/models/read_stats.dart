class ReadStats {
  final String judul;
  final int? recipientsCount;
  final int readCount;
  final double? persentaseBaca;

  ReadStats({
    required this.judul,
    this.recipientsCount,
    required this.readCount,
    this.persentaseBaca,
  });

  factory ReadStats.fromJson(Map<String, dynamic> json) {
    return ReadStats(
      judul: json['judul']?.toString() ?? '',
      recipientsCount: int.tryParse(json['recipients_count']?.toString() ?? ''),
      readCount: int.tryParse(json['read_count']?.toString() ?? '0') ?? 0,
      persentaseBaca: double.tryParse(json['persentase_baca']?.toString() ?? ''),
    );
  }
}
