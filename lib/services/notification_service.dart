import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api_config.dart';
import 'database_service.dart';
import '../models/notification_log.dart';
import '../models/read_stats.dart';

class NotificationService {
  static Future<List<NotificationLog>> getLogs({int limit = 20, int offset = 0}) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/get_logs.php?limit=$limit&offset=$offset'),
        headers: {'Authorization': 'Bearer ${AuthService.currentToken}'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body)['data'];
        final logs = data.map((e) => NotificationLog.fromJson(e)).toList();
        
        // Save to local DB for offline access
        if (offset == 0) {
          // If first page, we can optionally clear old cache or just sync
          await DatabaseService.saveLogs(logs);
        } else {
          await DatabaseService.saveLogs(logs);
        }
        
        return logs;
      }
    } catch (e) {
      print('Fetch remote logs failed, using local: $e');
    }

    // Return from local DB if remote fails
    return await DatabaseService.getLogs(limit: limit, offset: offset);
  }

  static Future<ReadStats?> getReadStats(int logId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/get_read_stats.php?log_id=$logId'),
      headers: {'Authorization': 'Bearer ${AuthService.currentToken}'},
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['success'] == true) {
        return ReadStats.fromJson(body['data']);
      }
    }
    return null;
  }

  static Future<int> getUnreadCount() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/get_unread_count.php'),
      headers: {'Authorization': 'Bearer ${AuthService.currentToken}'},
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['unread_count'] ?? 0;
    }
    return 0;
  }

  static Future<void> markAsRead(String logId) async {
    final token = AuthService.currentToken;
    if (token == null) return;

    // Update locally first for instant feedback/offline sync
    await DatabaseService.markAsRead(int.parse(logId));

    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/mark_read.php'),
        headers: {'Authorization': 'Bearer $token'},
        body: {'log_id': logId},
      );
    } catch (e) {
      print('Mark as read (remote) failed: $e');
      // In a more advanced version, we could queue this for later sync
    }
  }

  static Future<bool> markAllAsRead() async {
    final token = AuthService.currentToken;
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/mark_all_read.php'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        // Update local database too
        final db = await DatabaseService.database;
        await db.update('notification_logs', {'is_read': 1});
        return true;
      }
    } catch (e) {
      print('Mark all as read failed: $e');
    }
    return false;
  }
}
