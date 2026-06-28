import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_config.dart';
import 'database_service.dart';

class AuthService {
  static User? currentUser;

  static String? get currentToken => currentUser?.apiToken;

  static Future<void> _saveSession(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(user.toJson()));
  }

  static Future<bool> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      currentUser = User.fromJson(jsonDecode(userData));
      await _registerOneSignalIdentity(currentUser!);
      return true;
    }
    return false;
  }

  static Future<void> refreshUserInfo() async {
    if (currentToken == null) return;
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/get_user_info.php'),
        headers: {'Authorization': 'Bearer $currentToken'},
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          final newUser = User.fromJson({
            ...body['data'],
            'api_token': currentToken,
          });
          currentUser = newUser;
          await _saveSession(newUser);
          await _registerOneSignalIdentity(newUser);
        }
      }
    } catch (e) {
      print('Refresh User Info failed: $e');
    }
  }

  static Future<User> login(String nim, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/login.php'),
      body: {'nim': nim, 'password': password},
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Login gagal');
    }

    final user = User.fromJson(body['data']);
    currentUser = user;
    
    await _saveSession(user);
    await _registerOneSignalIdentity(user);

    return user;
  }

  static Future<void> _registerOneSignalIdentity(User user) async {
    try {
      await OneSignal.login(user.nim);
      await Future.delayed(const Duration(seconds: 3));

      final tagMap = <String, String>{};
      tagMap['role'] = user.role.toLowerCase().trim();
      tagMap['gender'] = (user.gender ?? 'L').toLowerCase().trim();
      
      final List<String> metaParts = [];
      if (user.jurusan != null && user.jurusan!.isNotEmpty) metaParts.add(user.jurusan!.toLowerCase());
      if (user.angkatan != null && user.angkatan!.isNotEmpty) metaParts.add(user.angkatan!.toLowerCase());
      if (user.kelas != null && user.kelas!.isNotEmpty) metaParts.add(user.kelas!.toLowerCase());

      if (metaParts.isNotEmpty) {
        tagMap['metadata'] = metaParts.join('#');
      }

      if (tagMap.isNotEmpty) {
        await OneSignal.User.addTags(tagMap);
      }

      final currentSubId = OneSignal.User.pushSubscription.id;
      if (currentSubId != null && currentSubId.isNotEmpty) {
        await _syncPlayerId(currentSubId);
      }

      OneSignal.User.pushSubscription.addObserver((state) {
        if (state.current.id != null) {
          _syncPlayerId(state.current.id!);
        }
      });
    } catch (e) {
      print('OneSignal Sync error: $e');
    }
  }

  static Future<void> _syncPlayerId(String playerId) async {
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/sync_player_id.php'),
        headers: {'Authorization': 'Bearer $currentToken'},
        body: {'player_id': playerId},
      );
    } catch (e) {
      print('Sync PlayerID failed: $e');
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    await OneSignal.logout();
    await DatabaseService.clearAll();
    currentUser = null;
  }

  static Future<bool> changePassword(String oldPassword, String newPassword) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/change_password.php'),
      headers: {'Authorization': 'Bearer $currentToken'},
      body: {'old_password': oldPassword, 'new_password': newPassword},
    );
    final body = jsonDecode(response.body);
    return body['success'] == true;
  }
}
