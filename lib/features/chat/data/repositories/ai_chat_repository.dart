import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fcm_app/shared/models/parsed_task_model.dart';
import 'package:fcm_app/shared/models/user_info_model.dart';
import '../models/ai_conversation_model.dart';
import '../models/ai_message_model.dart';

class AIChatRepository {
  static final AIChatRepository instance = AIChatRepository._internal();
  AIChatRepository._internal();

  final String baseUrl = 'http://localhost:3000/api/chat';

  // Persistent pending tasks for the confirmation overlay
  final ValueNotifier<Map<String, dynamic>?> pendingRequestDataNotifier =
      ValueNotifier(null);

  Future<void> initPendingTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksStr = prefs.getString('pending_tasks');
    final userInfoStr = prefs.getString('pending_user_info');

    if (tasksStr != null && userInfoStr != null) {
      try {
        final tasksList = (jsonDecode(tasksStr) as List)
            .map((e) => ParsedTask.fromJson(e))
            .toList();
        final userInfo = UserInfoModel.fromJson(jsonDecode(userInfoStr));

        pendingRequestDataNotifier.value = {
          'tasks': tasksList,
          'userInfo': userInfo,
        };
      } catch (e) {
        print('FCM AIChatRepository: Failed to load pending tasks -> $e');
        await clearPendingTasks();
      }
    }
  }

  Future<void> savePendingTasks(
      List<ParsedTask> tasks, UserInfoModel userInfo) async {
    final prefs = await SharedPreferences.getInstance();
    final tasksListJson = tasks.map((t) => t.toJson()).toList();

    await prefs.setString('pending_tasks', jsonEncode(tasksListJson));
    await prefs.setString('pending_user_info', jsonEncode(userInfo.toJson()));

    pendingRequestDataNotifier.value = {
      'tasks': tasks,
      'userInfo': userInfo,
    };
  }

  Future<void> clearPendingTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pending_tasks');
    await prefs.remove('pending_user_info');
    pendingRequestDataNotifier.value = null;
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<AIConversationModel>> getConversations() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/conversations'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;
        return data.map((e) => AIConversationModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('FCM AIChatRepository: getConversations Error -> $e');
      return [];
    }
  }

  Future<List<AIMessageModel>> getMessages(String conversationId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/conversations/$conversationId/messages'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;
        return data.map((e) => AIMessageModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('FCM AIChatRepository: getMessages Error -> $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> sendMessage(String content,
      {String? conversationId}) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'content': content,
        if (conversationId != null) 'conversationId': conversationId,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/message'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {'success': true, 'data': result['data']};
      }

      return {
        'success': false,
        'error': 'Failed to send message: ${response.statusCode}'
      };
    } catch (e) {
      print('FCM AIChatRepository: sendMessage Error -> $e');
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  Future<bool> deleteConversation(String conversationId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/conversations/$conversationId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print('FCM AIChatRepository: deleteConversation Error -> $e');
      return false;
    }
  }

  Future<bool> archiveConversation(String conversationId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/conversations/$conversationId/archive'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print('FCM AIChatRepository: archiveConversation Error -> $e');
      return false;
    }
  }

  Future<bool> updateMessageActionState(
      String messageId, String actionState) async {
    try {
      final headers = await _getHeaders();
      final body = {'action_state': actionState};

      final response = await http.patch(
        Uri.parse('$baseUrl/messages/$messageId/action'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print('FCM AIChatRepository: updateMessageActionState Error -> $e');
      return false;
    }
  }

  /// Confirm a repair request parsed by the AI assistant
  Future<bool> confirmRequest(List<ParsedTask> tasks,
      {String? messageId}) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'message_id': messageId,
        'request': {
          'tasks': tasks.map((t) => t.toJson()).toList(),
        }
      };

      final response = await http.post(
        Uri.parse('http://localhost:3000/api/repair/confirm'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      print(
          'FCM AIChatRepository: confirmRequest failed -> ${response.statusCode}');
      return false;
    } catch (e) {
      print('FCM AIChatRepository: confirmRequest Error -> $e');
      return false;
    }
  }
}
