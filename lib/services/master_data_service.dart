import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../models/jurusan.dart';
import '../models/angkatan.dart';
import '../models/kelas.dart';

class MasterDataService {
  static Future<List<Jurusan>> getJurusan() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/get_jurusan.php'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body)['data'];
      return data.map((e) => Jurusan.fromJson(e)).toList();
    }
    return [];
  }

  static Future<List<Angkatan>> getAngkatan() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/get_angkatan.php'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body)['data'];
      return data.map((e) => Angkatan.fromJson(e)).toList();
    }
    return [];
  }

  static Future<List<Kelas>> getKelas() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/get_kelas.php'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body)['data'];
      return data.map((e) => Kelas.fromJson(e)).toList();
    }
    return [];
  }
}
