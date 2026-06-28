class ReminderSchedule {
  final int id;
  final int roleId;
  final String namaRole;
  final String waktuTipe;
  final String jamKirim;
  final bool isActive;

  ReminderSchedule({
    required this.id,
    required this.roleId,
    required this.namaRole,
    required this.waktuTipe,
    required this.jamKirim,
    required this.isActive,
  });

  factory ReminderSchedule.fromJson(Map<String, dynamic> json) {
    return ReminderSchedule(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      roleId: int.tryParse(json['role_id']?.toString() ?? '0') ?? 0,
      namaRole: json['nama_role']?.toString() ?? '',
      waktuTipe: json['waktu_tipe']?.toString() ?? '',
      jamKirim: json['jam_kirim']?.toString() ?? '',
      isActive: (json['is_active']?.toString() == '1'),
    );
  }
}
