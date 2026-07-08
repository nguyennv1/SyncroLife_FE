import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;
  String? token;

  // Auto-detect correct base URL based on platform:
  //   Web (Chrome/browser)    -> https://localhost:7142/api
  //   Android Emulator        -> https://10.0.2.2:7142/api  (10.0.2.2 = host machine localhost)
  //   Physical Android device -> https://<YOUR-LAN-IP>:7142/api  (change manually)
  static String get _defaultBaseUrl {
    if (kIsWeb) {
      return 'https://localhost:7142/api';
    }
    return 'http://syncrolife.runasp.net/api';
  }

  ApiService({String? baseUrl, this.token}) : baseUrl = baseUrl ?? _defaultBaseUrl;

  Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  String _extractErrorMessage(http.Response response) {
    try {
      final data = json.decode(response.body);
      if (data is Map) {
        if (data['errors'] != null) {
          final errs = data['errors'];
          if (errs is Map) {
            final List<String> messages = [];
            errs.forEach((key, value) {
              if (value is List) {
                messages.add("$key: ${value.join(', ')}");
              } else {
                messages.add("$key: $value");
              }
            });
            return "Validation Errors:\n" + messages.join("\n");
          }
        }
        return (data['message'] ?? data['error'] ?? data['title'] ?? data['errors'])?.toString()
            ?? 'Request failed (Status: ${response.statusCode})';
      }
    } catch (_) {}
    return response.body.isNotEmpty ? response.body : 'Request failed (Status: ${response.statusCode})';
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final String body = json.encode({
      'username': username,
      'password': password,
    });

    final response = await http.post(
      Uri.parse('$baseUrl/Auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  Future<Map<String, dynamic>> register(String username, String password, String confirmPassword) async {
    final String body = json.encode({
      'username': username,
      'password': password,
      'confirmPassword': confirmPassword,
    });

    final response = await http.post(
      Uri.parse('$baseUrl/Auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  List<dynamic> _mapScheduleList(List<dynamic> list) {
    return list.map((item) {
      if (item is! Map) return item;
      
      final title = (item['title'] ?? item['Title'] ?? 'Activity').toString();
      final description = (item['description'] ?? item['Description'] ?? '').toString();
      final scheduleId = item['scheduleId'] ?? item['ScheduleId'];
      final isCompleted = item['isCompleted'] ?? item['IsCompleted'] ?? false;
      
      // Extract time (HH:mm) from startTime ISO string
      String timeVal = '12:00';
      final rawStartTime = item['startTime'] ?? item['StartTime'];
      if (rawStartTime != null) {
        try {
          final dt = DateTime.parse(rawStartTime.toString()).toLocal();
          final hour = dt.hour.toString().padLeft(2, '0');
          final minute = dt.minute.toString().padLeft(2, '0');
          timeVal = '$hour:$minute';
        } catch (_) {
          // If already in HH:mm format
          final str = rawStartTime.toString();
          if (str.contains(':')) {
            final parts = str.split('T');
            final timePart = parts.length > 1 ? parts[1] : parts[0];
            final timeSub = timePart.split(':');
            if (timeSub.length >= 2) {
              timeVal = '${timeSub[0].trim()}:${timeSub[1].trim()}';
            }
          }
        }
      } else if (item['time'] != null || item['Time'] != null) {
        timeVal = (item['time'] ?? item['Time']).toString();
      }

      // Map typeName to type expected by UI (GYM, MEAL, SLEEP, WORK, TASK, GENERAL)
      String typeVal = 'GENERAL';
      final rawType = item['type'] ?? item['Type'];
      final rawTypeName = item['typeName'] ?? item['TypeName'];
      
      if (rawType != null) {
        typeVal = rawType.toString().toUpperCase();
      } else if (rawTypeName != null) {
        final name = rawTypeName.toString().toLowerCase();
        if (name.contains('work') || name.contains('study') || name.contains('meet')) {
          typeVal = 'WORK';
        } else if (name.contains('task') || name.contains('todo')) {
          typeVal = 'TASK';
        } else if (name.contains('gym') || name.contains('exercise') || name.contains('workout') || name.contains('cardio') || name.contains('yoga')) {
          typeVal = 'GYM';
        } else if (name.contains('meal') || name.contains('lunch') || name.contains('dinner') || name.contains('breakfast') || name.contains('food')) {
          typeVal = 'MEAL';
        } else if (name.contains('sleep') || name.contains('nap') || name.contains('bed')) {
          typeVal = 'SLEEP';
        }
      }

      return {
        'id': scheduleId,
        'title': title,
        'description': description,
        'time': timeVal,
        'type': typeVal,
        'isCompleted': isCompleted,
        'scheduleId': scheduleId,
        'startTime': rawStartTime,
        'endTime': item['endTime'] ?? item['EndTime'],
        'typeName': rawTypeName,
      };
    }).toList();
  }

  Future<List<dynamic>> fetchTodaySchedule() async {
    final int offset = DateTime.now().timeZoneOffset.inMinutes;
    final response = await http.get(
      Uri.parse('$baseUrl/Schedule/today?timezoneOffset=$offset'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final list = json.decode(response.body) as List<dynamic>;
      return _mapScheduleList(list);
    } else {
      throw Exception('Failed to load today schedule (Status: ${response.statusCode})');
    }
  }

  Future<List<dynamic>> fetchScheduleForDate(String date) async {
    final int offset = DateTime.now().timeZoneOffset.inMinutes;
    final response = await http.get(
      Uri.parse('$baseUrl/Schedule/date/$date?timezoneOffset=$offset'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final list = json.decode(response.body) as List<dynamic>;
      return _mapScheduleList(list);
    } else {
      throw Exception('Failed to load schedule for date $date (Status: ${response.statusCode})');
    }
  }

  Future<Map<String, dynamic>> fetchUserDetails(String userId) async {
    // Tries to request with path user-details/{userId}. We also support user-details?userId={userId} as fallback.
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/User/user-details/$userId'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {
      // Fallback to query parameter if path variable fails
      final response = await http.get(
        Uri.parse('$baseUrl/User/user-details?userId=$userId'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    }
    throw Exception('Failed to load user details for user $userId');
  }

  Future<List<dynamic>> fetchMyGoals() async {
    final response = await http.get(
      Uri.parse('$baseUrl/Goal/my-goals'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load goals (Status: ${response.statusCode})');
    }
  }

  Future<Map<String, dynamic>> createGoal(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Goal'),
      headers: _headers,
      body: json.encode(data),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  Future<bool> updateGoal(String goalId, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/Goal/$goalId'),
      headers: _headers,
      body: json.encode(data),
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  Future<bool> deleteGoal(String goalId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/Goal/$goalId'),
      headers: _headers,
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  Future<List<dynamic>> fetchMyHabits() async {
    final response = await http.get(
      Uri.parse('$baseUrl/Habit/my-habits'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load habits (Status: ${response.statusCode})');
    }
  }

  Future<bool> updateSchedule(dynamic id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/Schedule/$id'),
      headers: _headers,
      body: json.encode(data),
    );
    return response.statusCode == 200 || response.statusCode == 204;
  }

  Future<bool> deleteSchedule(dynamic id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/Schedule/$id'),
      headers: _headers,
    );
    return response.statusCode == 200 || response.statusCode == 204;
  }

  Future<bool> syncSchedule() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Schedule/auto-sync'),
        headers: _headers,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
    } catch (_) {
      // Fallback to mock success if endpoint does not exist yet
    }
    await Future.delayed(const Duration(seconds: 1));
    return true; 
  }

  Future<Map<String, dynamic>> loginWithGoogle(String serverAuthCode, {String? clientId, String? redirectUri}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Auth/google-login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'serverAuthCode': serverAuthCode,
        if (clientId != null) 'clientId': clientId,
        if (redirectUri != null) 'redirectUri': redirectUri,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  Future<void> syncGoogleCalendar() async {
    final response = await http.post(
      Uri.parse('$baseUrl/Schedule/sync-google'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(response));
    }
  }

  Future<Map<String, dynamic>?> fetchLatestRecommendation() async {
    final response = await http.get(
      Uri.parse('$baseUrl/Recommendation/latest'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to load recommendation (Status: ${response.statusCode})');
    }
  }

  Future<List<dynamic>> fetchMeals() async {
    final response = await http.get(
      Uri.parse('$baseUrl/Meal'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load meals (Status: ${response.statusCode})');
    }
  }

  Future<Map<String, dynamic>> analyzeFood(List<int> imageBytes, String filename) async {
    final uri = Uri.parse('$baseUrl/FoodAnalysis/analyze');
    final request = http.MultipartRequest('POST', uri);
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: filename,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  Future<List<dynamic>> fetchFoodAnalysisHistory() async {
    final response = await http.get(
      Uri.parse('$baseUrl/FoodAnalysis/history'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  Future<void> generateRecommendations() async {
    final response = await http.post(
      Uri.parse('$baseUrl/Recommendation/generate'),
      headers: _headers,
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to generate recommendations (Status: ${response.statusCode})');
    }
  }

  Future<Map<String, dynamic>> updateUserDetails(String userId, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/User/update-user/$userId'),
      headers: _headers,
      body: json.encode(data),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  Future<List<dynamic>> fetchAllUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/User/all-user'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  Future<List<dynamic>> fetchSubscriptionPlans() async {
    final response = await http.get(
      Uri.parse('$baseUrl/Payment/plans'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  Future<Map<String, dynamic>> createPaymentLink(String planId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Payment/create-payment-link'),
      headers: _headers,
      body: json.encode({'planId': planId}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  Future<Map<String, dynamic>> checkPaymentStatus(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/Payment/check-status?userId=$userId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  Future<Map<String, dynamic>> cancelPayment(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Payment/cancel?userId=$userId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  Future<Map<String, dynamic>> fetchRevenue() async {
    final response = await http.get(
      Uri.parse('$baseUrl/Payment/revenue'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }
}
