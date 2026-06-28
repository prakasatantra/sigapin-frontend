class User {
  final String nim;
  final String nama;
  final String role;
  final String? jurusan;
  final String? namaJurusan;
  final String? angkatan;
  final String? gender;
  final String? kelas;
  final String? apiToken;
  final String? onesignalPlayerId;

  User({
    required this.nim,
    required this.nama,
    required this.role,
    this.jurusan,
    this.namaJurusan,
    this.angkatan,
    this.gender,
    this.kelas,
    this.apiToken,
    this.onesignalPlayerId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    String role = (json['role'] ?? '').toString().trim();
    String nama = (json['nama'] ?? '').toString().trim();
    String gender = (json['gender']?.toString().trim() ?? 'L');

    // Penanganan gelar dan sapaan berdasarkan role dan gender
    String roleLower = role.toLowerCase();
    String namaLower = nama.toLowerCase();

    if (roleLower == 'direktur') {
      String sapaan = (gender == 'P') ? 'Bu' : 'Pak';
      if (!namaLower.startsWith('pak ') && !namaLower.startsWith('bu ')) {
        nama = '$sapaan $nama';
      }
      if (!nama.toLowerCase().contains('dr.')) {
        // Jika sudah ada sapaan Pak/Bu, pastikan dr. ada setelahnya
        if (nama.startsWith('$sapaan ')) {
          nama = nama.replaceFirst('$sapaan ', '$sapaan dr. ');
        } else {
          nama = 'dr. $nama';
        }
      }
    } else if (roleLower == 'dosen' || roleLower == 'admin') {
      String sapaan = (gender == 'P') ? 'Bu' : 'Pak';
      if (!namaLower.startsWith('pak ') && !namaLower.startsWith('bu ')) {
        nama = '$sapaan $nama';
      }
    } else if (roleLower == 'karyawan' || roleLower == 'mahasiswa') {
      String sapaan = (gender == 'P') ? 'Mbak' : 'Mas';
      if (!namaLower.startsWith('mas ') && !namaLower.startsWith('mbak ')) {
        nama = '$sapaan $nama';
      }
    }

    return User(
      nim: (json['nim'] ?? '').toString().trim(),
      nama: nama,
      role: role,
      jurusan: json['jurusan']?.toString().trim(),
      namaJurusan: json['nama_jurusan']?.toString().trim(),
      angkatan: json['angkatan']?.toString().trim(),
      gender: gender,
      kelas: json['kelas']?.toString().trim(),
      apiToken: json['api_token']?.toString().trim(),
      onesignalPlayerId: json['onesignal_player_id']?.toString().trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nim': nim,
      'nama': nama,
      'role': role,
      'jurusan': jurusan,
      'nama_jurusan': namaJurusan,
      'angkatan': angkatan,
      'gender': gender,
      'kelas': kelas,
      'api_token': apiToken,
      'onesignal_player_id': onesignalPlayerId,
    };
  }
}
