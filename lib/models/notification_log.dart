class NotificationLog {
  final int id;
  final String judul;
  final String isiPesan;
  final String tipe;
  final Map<String, dynamic>? targetFilter;
  final String? soundFile;
  final String? sentBy;
  final String? onesignalNotificationId;
  final int? recipientsCount;
  final String? gambarUrl; // Note: Schema SQL tidak memiliki gambar_url, tapi app Flutter memakainya. Saya akan membiarkannya agar tidak memutus fitur visual.
  bool isRead;
  final DateTime? createdAt;

  NotificationLog({
    required this.id,
    required this.judul,
    required this.isiPesan,
    required this.tipe,
    this.targetFilter,
    this.soundFile,
    this.sentBy,
    this.onesignalNotificationId,
    this.recipientsCount,
    this.gambarUrl,
    this.isRead = false,
    this.createdAt,
  });

  factory NotificationLog.fromJson(Map<String, dynamic> json) {
    return NotificationLog(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      judul: json['judul']?.toString() ?? '',
      isiPesan: json['isi_pesan']?.toString() ?? '',
      tipe: json['tipe']?.toString() ?? '',
      targetFilter: json['target_filter'] != null ? Map<String, dynamic>.from(json['target_filter']) : null,
      soundFile: json['sound_file']?.toString(),
      sentBy: json['sent_by']?.toString(),
      onesignalNotificationId: json['onesignal_notification_id']?.toString(),
      recipientsCount: int.tryParse(json['recipients_count']?.toString() ?? ''),
      gambarUrl: json['gambar_url']?.toString(),
      isRead: (json['is_read']?.toString() == '1'),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}
