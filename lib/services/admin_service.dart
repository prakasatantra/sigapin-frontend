import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api_config.dart';
import '../models/user.dart';
import '../models/reminder_schedule.dart';
import '../models/pesan_template.dart';
import '../models/holiday.dart';

class AdminService {
  static Future<Map<String, dynamic>> sendBroadcast({
    required String judul,
    required String isi,
    String? targetJurusan,
    String? targetAngkatan,
    String? targetKelas,
    File? imageFile,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/broadcast_mahasiswa.php'));
      request.headers['Authorization'] = 'Bearer ${AuthService.currentToken}';
      
      request.fields['judul'] = judul;
      request.fields['isi_pesan'] = isi;
      request.fields['jurusan'] = targetJurusan ?? '';
      request.fields['angkatan'] = targetAngkatan ?? '';
      request.fields['kelas'] = targetKelas ?? '';

      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan jaringan: $e'};
    }
  }

  static Future<Map<String, dynamic>?> getBroadcastPreview({
    String? jurusan,
    String? angkatan,
    String? kelas,
  }) async {
    String url = '${ApiConfig.baseUrl}/preview_broadcast.php?';
    if (jurusan != null) url += 'jurusan=$jurusan&';
    if (angkatan != null) url += 'angkatan=$angkatan&';
    if (kelas != null) url += 'kelas=$kelas&';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer ${AuthService.currentToken}'},
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['success'] == true) return body['data'];
    }
    return null;
  }

  static Future<List<ReminderSchedule>> getSchedules() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/get_schedule.php'),
      headers: {'Authorization': 'Bearer ${AuthService.currentToken}'},
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body)['data'];
      return data.map((e) => ReminderSchedule.fromJson(e)).toList();
    }
    return [];
  }

  static Future<bool> updateSchedule({required int id, String? jamKirim, int? isActive}) async {
    final body = <String, String>{'id': id.toString()};
    if (jamKirim != null) body['jam_kirim'] = jamKirim;
    if (isActive != null) body['is_active'] = isActive.toString();

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/update_schedule.php'),
      headers: {'Authorization': 'Bearer ${AuthService.currentToken}'},
      body: body,
    );
    return jsonDecode(response.body)['success'] == true;
  }

  static Future<List<PesanTemplate>> getTemplates() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/get_templates.php'),
      headers: {'Authorization': 'Bearer ${AuthService.currentToken}'},
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body)['data'];
      return data.map((e) => PesanTemplate.fromJson(e)).toList();
    }
    return [];
  }

  static Future<bool> updateTemplate({required int id, String? isiPesan, int? isActive}) async {
    final body = <String, String>{'id': id.toString()};
    if (isiPesan != null) body['isi_pesan'] = isiPesan;
    if (isActive != null) body['is_active'] = isActive.toString();

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/update_template.php'),
      headers: {'Authorization': 'Bearer ${AuthService.currentToken}'},
      body: body,
    );
    return jsonDecode(response.body)['success'] == true;
  }

  static Future<List<Holiday>> getHolidays() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/get_holidays.php'),
      headers: {'Authorization': 'Bearer ${AuthService.currentToken}'},
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body)['data'];
      return data.map((e) => Holiday.fromJson(e)).toList();
    }
    return [];
  }

  static Future<bool> addHoliday(String tanggal, String keterangan) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/add_holiday.php'),
      headers: {'Authorization': 'Bearer ${AuthService.currentToken}'},
      body: {'tanggal': tanggal, 'keterangan': keterangan},
    );
    return jsonDecode(response.body)['success'] == true;
  }

  static Future<bool> deleteHoliday(int id) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/delete_holiday.php'),
      headers: {'Authorization': 'Bearer ${AuthService.currentToken}'},
      body: {'id': id.toString()},
    );
    return jsonDecode(response.body)['success'] == true;
  }

  static Future<Map<String, dynamic>?> getAdminSummary() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/get_admin_summary.php'),
      headers: {'Authorization': 'Bearer ${AuthService.currentToken}'},
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['success'] == true) return body['data'];
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getDirekturSummary() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/get_direktur_summary.php'),
      headers: {'Authorization': 'Bearer ${AuthService.currentToken}'},
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['success'] == true) return body['data'];
    }
    return null;
  }

  static Future<List<User>> searchUsers(String query) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/search_users.php?query=$query'),
        headers: {'Authorization': 'Bearer ${AuthService.currentToken}'},
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          final List data = body['data'];
          return data.map((e) => User.fromJson(e)).toList();
        }
      }
    } catch (e) {
      print('Search users failed: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> adminChangePassword(String targetNim, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/admin_change_password.php'),
        headers: {'Authorization': 'Bearer ${AuthService.currentToken}'},
        body: {'target_nim': targetNim, 'new_password': newPassword},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan jaringan: $e'};
    }
  }
}
