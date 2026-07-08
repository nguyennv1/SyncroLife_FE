import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';

class AppState extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSynced = false;
  bool get isSynced => _isSynced;

  bool _hasConnectionError = false;
  bool get hasConnectionError => _hasConnectionError;

  bool _isDarkMode = true;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    AppColors.isDark = _isDarkMode;
    notifyListeners();
  }

  // Session state
  String? loggedInUserId;
  String? loggedInUsername;
  String? token;
  String _userRole = 'Customer';
  String get userRole => _userRole;
  bool get isAdmin => _userRole.toLowerCase() == 'admin';

  String? _googlePhotoUrl;
  String? get googlePhotoUrl => _googlePhotoUrl;
  set googlePhotoUrl(String? value) {
    _googlePhotoUrl = value;
    notifyListeners();
  }

  bool get isLoggedIn => loggedInUserId != null;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Real-time data lists
  List<dynamic> ongoingSchedules = [];
  List<dynamic> historySchedules = [];
  List<dynamic> selectedDateSchedules = [];
  Map<String, dynamic>? userProfile;
  List<dynamic> userHabits = [];
  List<dynamic> userGoals = [];
  Map<String, dynamic>? latestRecommendation;
  List<dynamic> userMeals = [];
  List<dynamic> foodAnalysisHistory = [];
  List<dynamic> adminUsers = [];
  Map<String, dynamic>? adminRevenue;

  // Selected date on Sync screen (defaults to today)
  DateTime selectedSyncDate = DateTime.now();

  // Mock data fallbacks in case C# backend is offline
  final List<Map<String, dynamic>> ongoingSchedulesMock = [
    {'id': 101, 'title': "Morning Routine", 'description': "Meditation + Stretch", 'time': "07:00", 'type': "GENERAL"},
    {'id': 102, 'title': "Working", 'description': "Product review", 'time': "09:00", 'type': "WORK"},
    {'id': 103, 'title': "Lunch Break", 'description': "High protein meal plan", 'time': "12:00", 'type': "MEAL"},
    {'id': 104, 'title': "AI Suggestion", 'description': "Syncro found a 45-min gap for Cardio", 'time': "14:00", 'type': "GYM"},
    {'id': 105, 'title': "Client meeting", 'description': "3 hrs call", 'time': "15:00", 'type': "WORK"},
  ];

  final List<Map<String, dynamic>> historySchedulesMock = [
    {'id': 201, 'title': "Working", 'description': "Design sync", 'time': "08:00", 'type': "WORK"},
    {'id': 202, 'title': "AI Suggestion", 'description': "Syncro found a 1 hr gap for Yoga", 'time': "08:45", 'type': "GYM"},
    {'id': 203, 'title': "Lunch Break", 'description': "High protein meal plan", 'time': "11:00", 'type': "MEAL"},
    {'id': 204, 'title': "Nap", 'description': "1 hr quality nap", 'time': "12:00", 'type': "SLEEP"},
    {'id': 205, 'title': "Team meeting", 'description': "2 hrs call", 'time': "14:00", 'type': "WORK"},
  ];

  final List<Map<String, dynamic>> selectedDateSchedulesMock = [
    {'id': 301, 'title': "Sprint Planning", 'description': "1 hour", 'time': "08:00", 'type': "WORK"},
    {'id': 302, 'title': "Design Review", 'description': "45 mins", 'time': "09:00", 'type': "GENERAL"},
    {'id': 303, 'title': "Lunch - Grilled Chicken Bowl", 'description': "45 mins", 'time': "12:00", 'type': "MEAL"},
    {'id': 304, 'title': "Cardio", 'description': "45 mins", 'time': "13:00", 'type': "GYM"},
    {'id': 305, 'title': "Client Presentation", 'description': "2 hours", 'time': "13:30", 'type': "WORK"},
  ];

  final Map<String, dynamic> userProfileMock = {
    'name': "Guest User",
    'subscriptionType': "FREE",
    'bmi': 0.0,
    'targetCalories': 0.0,
    'monthlyBudget': 0.0,
    'allergies': "",
    'gender': "",
    'height': 0.0,
    'weight': 0.0,
    'dateOfBirth': "",
    'dob': "",
  };

  final List<Map<String, dynamic>> userGoalsMock = [
    {'title': "Lose 5 lbs", 'targetValue': 100.0, 'currentValue': 65.0, 'unit': "%"},
    {'title': "Run 5K under 25min", 'targetValue': 100.0, 'currentValue': 40.0, 'unit': "%"},
    {'title': "Meal prep 5x/week", 'targetValue': 100.0, 'currentValue': 80.0, 'unit': "%"},
  ];

  AppState() {
    _initSession();
  }

  Future<void> _initSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      await loadSavedSession();
    } catch (e) {
      debugPrint("AppState: Error restoring session: $e");
    } finally {
      // If no session was loaded (user is not logged in), load guest mock data
      if (loggedInUserId == null) {
        await loadAllData();
      }
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loggedInUserId', loggedInUserId ?? '');
    await prefs.setString('loggedInUsername', loggedInUsername ?? '');
    await prefs.setString('token', token ?? '');
    await prefs.setString('userRole', _userRole);
    if (_googlePhotoUrl != null) {
      await prefs.setString('googlePhotoUrl', _googlePhotoUrl!);
    } else {
      await prefs.remove('googlePhotoUrl');
    }
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('loggedInUserId');
    await prefs.remove('loggedInUsername');
    await prefs.remove('token');
    await prefs.remove('userRole');
    await prefs.remove('googlePhotoUrl');
    _googlePhotoUrl = null;
  }

  Future<void> loadSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString('loggedInUserId');
    final savedUsername = prefs.getString('loggedInUsername');
    final savedToken = prefs.getString('token');
    final savedUserRole = prefs.getString('userRole');
    _googlePhotoUrl = prefs.getString('googlePhotoUrl');

    if (savedUserId != null && savedUserId.isNotEmpty && savedToken != null && savedToken.isNotEmpty) {
      loggedInUserId = savedUserId;
      loggedInUsername = savedUsername;
      token = savedToken;
      _userRole = savedUserRole ?? 'Customer';
      _apiService.token = token;
      
      // Load all data
      await loadAllData(userId: loggedInUserId);
    }
  }

  // Helpers
  String formatDate(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }

  Future<void> loadAllData({String? userId}) async {
    _isLoading = true;
    _hasConnectionError = false;

    final targetUserId = userId ?? loggedInUserId;

    if (targetUserId != null) {
      userProfile = null;
      ongoingSchedules = [];
      historySchedules = [];
      userGoals = [];
      userHabits = [];
      latestRecommendation = null;
      userMeals = [];
      selectedDateSchedules = [];
      notifyListeners();
    } else {
      notifyListeners();
    }

    if (targetUserId == null) {
      // Guest mode (Bypass): Use mock data
      userProfile = userProfileMock;
      ongoingSchedules = ongoingSchedulesMock;
      historySchedules = historySchedulesMock;
      userGoals = userGoalsMock;
      userHabits = [];
      userMeals = [
        {
          'mealId': 'mock-meal-1',
          'name': 'Grilled Chicken Caesar Salad (Mock)',
          'category': 'Salad',
          'portionSize': '1 bowl',
          'calories': 350,
          'protein': 28.0,
          'carbs': 10.0,
          'fats': 22.0,
          'fiber': 3.0,
          'sodium': 650.0,
          'isVegetarian': false,
          'isVegan': false,
          'description': '1. Grill 150g chicken breast and slice.\n2. Toss romaine lettuce, cherry tomatoes, and parmesan cheese with Caesar dressing.\n3. Top with chicken and croutons.',
        }
      ];
      foodAnalysisHistory = [
        {
          'analysisId': 'mock-scan-1',
          'foodName': 'Banh Mi (Mock Scan)',
          'confidence': 0.96,
          'calories': 450,
          'protein': 18.0,
          'carbs': 52.0,
          'fats': 15.0,
          'fiber': 4.0,
          'sodium': 780.0,
          'description': 'Vietnamese sandwich with pork, pate, pickled vegetables, and cilantro.',
          'aiNotes': 'High carbohydrate content from the bread. Good amount of protein, but watch out for sodium.',
          'createdAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        }
      ];
      selectedDateSchedules = ongoingSchedules;
      latestRecommendation = null;
      _isLoading = false;
      _hasConnectionError = false;
      notifyListeners();
      return;
    }

    // Logged in: Fetch from APIs independently to prevent cascading failures
    bool profileSuccess = false;
    bool scheduleSuccess = false;
    bool goalsSuccess = false;

    // 1. Fetch User Profile
    try {
      userProfile = await _apiService.fetchUserDetails(targetUserId);
      profileSuccess = true;
    } catch (e) {
      debugPrint("AppState: Failed to load user profile: $e");
      userProfile = null;
    }

    // 2. Fetch Today's Schedule
    try {
      ongoingSchedules = await _apiService.fetchTodaySchedule();
      scheduleSuccess = true;
    } catch (e) {
      debugPrint("AppState: Failed to load today's schedule: $e");
      ongoingSchedules = [];
    }

    // 3. Fetch Yesterday's Schedule for history tab
    try {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      historySchedules = await _apiService.fetchScheduleForDate(formatDate(yesterday));
    } catch (e) {
      debugPrint("AppState: Failed to load history schedule: $e");
      historySchedules = [];
    }

    // 4. Fetch Goals
    try {
      userGoals = await _apiService.fetchMyGoals();
      goalsSuccess = true;
    } catch (e) {
      debugPrint("AppState: Failed to load goals: $e");
      userGoals = [];
    }

    // 5. Fetch Habits
    try {
      userHabits = await _apiService.fetchMyHabits();
    } catch (e) {
      debugPrint("AppState: Failed to load habits: $e");
      userHabits = [];
    }

    // 6. Fetch Latest Recommendation
    try {
      latestRecommendation = await _apiService.fetchLatestRecommendation();
    } catch (e) {
      debugPrint("AppState: Failed to load latest recommendation: $e");
      latestRecommendation = null;
    }

    // 7. Fetch Meals from database
    try {
      userMeals = await _apiService.fetchMeals();
    } catch (e) {
      debugPrint("AppState: Failed to load meals: $e");
      userMeals = [];
    }

    // 8. Fetch Food Analysis History from database
    try {
      foodAnalysisHistory = await _apiService.fetchFoodAnalysisHistory();
    } catch (e) {
      debugPrint("AppState: Failed to load food analysis history: $e");
      foodAnalysisHistory = [];
    }

    // Determine connection error state:
    // If all key endpoints failed, it's a connection error.
    _hasConnectionError = (!profileSuccess && !scheduleSuccess && !goalsSuccess);

    // By default, load selected date schedules for today
    selectedDateSchedules = ongoingSchedules;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadScheduleForDate(DateTime date) async {
    _isLoading = true;
    selectedSyncDate = date;
    notifyListeners();

    try {
      if (loggedInUserId != null) {
        selectedDateSchedules = await _apiService.fetchScheduleForDate(formatDate(date));
      } else {
        selectedDateSchedules = selectedDateSchedulesMock;
      }
    } catch (e) {
      debugPrint("AppState: Failed to load schedule for ${formatDate(date)}. Details: $e");
      selectedDateSchedules = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginUser(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      if ((username == 'admin' && password == 'admin') || (username == 'customer' && password == 'customer')) {
        try {
          final result = await _apiService.login(username, password);
          loggedInUserId = (result['userId'] ?? result['id'] ?? result['user_id'])?.toString();
          loggedInUsername = (result['username'] ?? username)?.toString();
          token = result['token']?.toString();
          _userRole = (result['role'] ?? result['Role'] ?? 'Customer').toString();
          _apiService.token = token;
          await _saveSession();
          await loadAllData(userId: loggedInUserId);
        } catch (e) {
          // Backend is offline, use mock credentials
          if (username == 'admin') {
            loggedInUserId = 'mock-admin-id';
            loggedInUsername = 'admin';
            _userRole = 'Admin';
          } else {
            loggedInUserId = 'mock-customer-id';
            loggedInUsername = 'customer';
            _userRole = 'Customer';
          }
          token = 'mock-jwt-token';
          _apiService.token = token;
          await _saveSession();
          await loadAllData(userId: null); // load mock data
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }

      final result = await _apiService.login(username, password);
      loggedInUserId = (result['userId'] ?? result['id'] ?? result['user_id'])?.toString();
      loggedInUsername = (result['username'] ?? username)?.toString();
      token = result['token']?.toString();
      _userRole = (result['role'] ?? result['Role'] ?? 'Customer').toString();
      
      // Update token in apiService to make subsequent authenticated calls succeed
      _apiService.token = token;
      await _saveSession();
      
      // Load user details & schedules for the newly logged in Guid
      await loadAllData(userId: loggedInUserId);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> registerUser(String username, String password, String confirmPassword) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.register(username, password, confirmPassword);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void logout() {
    loggedInUserId = null;
    loggedInUsername = null;
    token = null;
    _apiService.token = null;
    _userRole = 'Customer';
    adminUsers = [];
    try {
      GoogleSignIn().signOut();
    } catch (e) {
      debugPrint("AppState: Google Sign-Out error: $e");
    }
    _clearSession();
    loadAllData();
  }

  Future<void> loadAdminData() async {
    if (!isAdmin) return;
    _isLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _apiService.fetchAllUsers(),
        _apiService.fetchRevenue().catchError((e) {
          debugPrint('Failed to load real revenue, using mock: $e');
          return _getMockRevenue();
        }),
      ]);
      adminUsers = results[0] as List<dynamic>;
      adminRevenue = results[1] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('AppState: Failed to load admin data: $e');
      adminUsers = [];
      adminRevenue = _getMockRevenue();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> _getMockRevenue() {
    return {
      'today': 150000.0,
      'month': 2450000.0,
      'year': 18900000.0,
      'daily': [
        {'date': '2026-07-01', 'amount': 100000.0},
        {'date': '2026-07-02', 'amount': 50000.0},
        {'date': '2026-07-03', 'amount': 200000.0},
        {'date': '2026-07-04', 'amount': 150000.0},
        {'date': '2026-07-05', 'amount': 50000.0},
        {'date': '2026-07-06', 'amount': 300000.0},
        {'date': '2026-07-07', 'amount': 250000.0},
        {'date': '2026-07-08', 'amount': 150000.0},
      ],
      'monthly': [
        {'month': 1, 'amount': 1200000.0},
        {'month': 2, 'amount': 1500000.0},
        {'month': 3, 'amount': 2200000.0},
        {'month': 4, 'amount': 1800000.0},
        {'month': 5, 'amount': 3100000.0},
        {'month': 6, 'amount': 4200000.0},
        {'month': 7, 'amount': 2450000.0},
      ]
    };
  }

  Future<void> syncSchedule() async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _apiService.syncSchedule();
      if (success) {
        _isSynced = !_isSynced; // Toggle for demonstration
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleSync() {
    _isSynced = !_isSynced;
    notifyListeners();
  }

  Future<bool> loginWithGoogle(String serverAuthCode, {String? clientId, String? redirectUri}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiService.loginWithGoogle(serverAuthCode, clientId: clientId, redirectUri: redirectUri);
      loggedInUserId = (result['userId'] ?? result['id'] ?? result['user_id'])?.toString();
      loggedInUsername = (result['username'] ?? result['email'])?.toString();
      token = result['token']?.toString();
      _userRole = (result['role'] ?? result['Role'] ?? 'Customer').toString();
      
      _apiService.token = token;
      await _saveSession();
      
      await loadAllData(userId: loggedInUserId);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> syncGoogleCalendar() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.syncGoogleCalendar();
      await loadAllData(userId: loggedInUserId);
      await loadScheduleForDate(selectedSyncDate);
    } catch (e) {
      debugPrint("AppState: Failed to sync Google Calendar: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    required String fullName,
    required String gender,
    required double height,
    required double weight,
    required int targetCalories,
    required double monthlyBudget,
    required String allergies,
    required String dateOfBirth,
  }) async {
    final targetUserId = loggedInUserId;
    if (targetUserId == null) {
      userProfileMock['name'] = fullName;
      userProfileMock['gender'] = gender;
      userProfileMock['height'] = height;
      userProfileMock['weight'] = weight;
      userProfileMock['targetCalories'] = targetCalories.toDouble();
      userProfileMock['monthlyBudget'] = monthlyBudget;
      userProfileMock['allergies'] = allergies;
      userProfileMock['dateOfBirth'] = dateOfBirth;
      userProfileMock['dob'] = dateOfBirth;
      
      if (height > 0 && weight > 0) {
        userProfileMock['bmi'] = double.parse((weight / ((height / 100) * (height / 100))).toStringAsFixed(1));
      }
      userProfile = Map.from(userProfileMock);
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      String? formattedDob;
      if (dateOfBirth.isNotEmpty) {
        try {
          String tempDob = dateOfBirth;
          if (tempDob.contains('T')) {
            tempDob = tempDob.split('T')[0];
          }
          final parsedDate = DateTime.tryParse(tempDob);
          if (parsedDate != null) {
            formattedDob = "${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}";
          } else {
            formattedDob = tempDob;
          }
        } catch (_) {
          formattedDob = dateOfBirth;
        }
      }

      final data = {
        'fullName': fullName,
        'gender': gender,
        'height': height,
        'weight': weight,
        'targetCalories': targetCalories,
        'monthlyBudget': monthlyBudget,
        'allergies': allergies,
        'dateOfBirth': formattedDob,
        'dob': formattedDob,
      };

      await _apiService.updateUserDetails(targetUserId, data);
      await loadAllData(userId: targetUserId);
      
      try {
        await _apiService.generateRecommendations();
        latestRecommendation = await _apiService.fetchLatestRecommendation();
      } catch (e) {
        debugPrint("AppState: Failed to generate recommendations after profile update: $e");
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint("AppState: Failed to update user profile: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addAllergy(String allergy) async {
    final rawAllergies = userProfile?['allergies'];
    List<String> list = [];
    if (rawAllergies is List) {
      list = rawAllergies.map((e) => e.toString()).toList();
    } else if (rawAllergies is String && rawAllergies.isNotEmpty) {
      list = rawAllergies.split(',').map((e) => e.trim()).toList();
    }
    if (!list.contains(allergy)) {
      list.add(allergy);
      final String allergiesStr = list.join(',');
      
      double heightVal = 0.0;
      final rawH = userProfile?['height'];
      if (rawH != null) heightVal = double.tryParse(rawH.toString()) ?? 0.0;

      double weightVal = 0.0;
      final rawW = userProfile?['weight'];
      if (rawW != null) weightVal = double.tryParse(rawW.toString()) ?? 0.0;

      int caloriesVal = 0;
      final rawCal = userProfile?['targetCalories'] ?? userProfile?['calories'];
      if (rawCal != null) {
        caloriesVal = double.tryParse(rawCal.toString())?.toInt() ?? int.tryParse(rawCal.toString()) ?? 0;
      }

      double budgetVal = 0.0;
      final rawB = userProfile?['monthlyBudget'] ?? userProfile?['budget'];
      if (rawB != null) budgetVal = double.tryParse(rawB.toString()) ?? 0.0;

      final dobStr = userProfile?['dateOfBirth']?.toString() ?? userProfile?['dob']?.toString() ?? '';

      await updateProfile(
        fullName: userProfile?['fullName']?.toString() ?? userProfile?['name']?.toString() ?? '',
        gender: userProfile?['gender']?.toString() ?? '',
        height: heightVal,
        weight: weightVal,
        targetCalories: caloriesVal,
        monthlyBudget: budgetVal,
        allergies: allergiesStr,
        dateOfBirth: dobStr,
      );
    }
  }

  Future<void> removeAllergy(String allergy) async {
    final rawAllergies = userProfile?['allergies'];
    List<String> list = [];
    if (rawAllergies is List) {
      list = rawAllergies.map((e) => e.toString()).toList();
    } else if (rawAllergies is String && rawAllergies.isNotEmpty) {
      list = rawAllergies.split(',').map((e) => e.trim()).toList();
    }
    if (list.contains(allergy)) {
      list.remove(allergy);
      final String allergiesStr = list.join(',');

      double heightVal = 0.0;
      final rawH = userProfile?['height'];
      if (rawH != null) heightVal = double.tryParse(rawH.toString()) ?? 0.0;

      double weightVal = 0.0;
      final rawW = userProfile?['weight'];
      if (rawW != null) weightVal = double.tryParse(rawW.toString()) ?? 0.0;

      int caloriesVal = 0;
      final rawCal = userProfile?['targetCalories'] ?? userProfile?['calories'];
      if (rawCal != null) {
        caloriesVal = double.tryParse(rawCal.toString())?.toInt() ?? int.tryParse(rawCal.toString()) ?? 0;
      }

      double budgetVal = 0.0;
      final rawB = userProfile?['monthlyBudget'] ?? userProfile?['budget'];
      if (rawB != null) budgetVal = double.tryParse(rawB.toString()) ?? 0.0;

      final dobStr = userProfile?['dateOfBirth']?.toString() ?? userProfile?['dob']?.toString() ?? '';

      await updateProfile(
        fullName: userProfile?['fullName']?.toString() ?? userProfile?['name']?.toString() ?? '',
        gender: userProfile?['gender']?.toString() ?? '',
        height: heightVal,
        weight: weightVal,
        targetCalories: caloriesVal,
        monthlyBudget: budgetVal,
        allergies: allergiesStr,
        dateOfBirth: dobStr,
      );
    }
  }

  Future<void> addGoal({
    required String goalName,
    required String goalType,
    required double targetValue,
    required String unit,
    required String startDate,
    required String deadline,
  }) async {
    final targetUserId = loggedInUserId;
    if (targetUserId == null) {
      // Mock mode
      userGoalsMock.add({
        'goalId': 'mock-goal-${DateTime.now().millisecondsSinceEpoch}',
        'title': goalName,
        'goalName': goalName,
        'goalType': goalType,
        'targetValue': targetValue,
        'currentValue': 0.0,
        'unit': unit,
        'startDate': startDate,
        'deadline': deadline,
        'progressPercentage': 0,
        'isActive': true,
      });
      userGoals = List.from(userGoalsMock);
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();
    try {
      final data = {
        'goalName': goalName,
        'goalType': goalType,
        'targetValue': targetValue,
        'unit': unit,
        'startDate': startDate,
        'deadline': deadline.isNotEmpty ? deadline : null,
      };
      await _apiService.createGoal(data);
      userGoals = await _apiService.fetchMyGoals();
      notifyListeners();
    } catch (e) {
      debugPrint("AppState: Failed to create goal: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> editGoal({
    required String goalId,
    required String goalName,
    required String goalType,
    required double targetValue,
    required double currentValue,
    required String unit,
    required String startDate,
    required String deadline,
    required bool isActive,
  }) async {
    final targetUserId = loggedInUserId;
    if (targetUserId == null) {
      // Mock mode
      final idx = userGoalsMock.indexWhere((g) => g['goalId'] == goalId || g['title'] == goalName || g['goalName'] == goalName);
      if (idx != -1) {
        userGoalsMock[idx]['title'] = goalName;
        userGoalsMock[idx]['goalName'] = goalName;
        userGoalsMock[idx]['goalType'] = goalType;
        userGoalsMock[idx]['targetValue'] = targetValue;
        userGoalsMock[idx]['currentValue'] = currentValue;
        userGoalsMock[idx]['unit'] = unit;
        userGoalsMock[idx]['startDate'] = startDate;
        userGoalsMock[idx]['deadline'] = deadline;
        userGoalsMock[idx]['isActive'] = isActive;
        if (targetValue > 0) {
          userGoalsMock[idx]['progressPercentage'] = ((currentValue / targetValue) * 100).toInt();
        }
      }
      userGoals = List.from(userGoalsMock);
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();
    try {
      final data = {
        'goalName': goalName,
        'goalType': goalType,
        'targetValue': targetValue,
        'currentValue': currentValue,
        'unit': unit,
        'startDate': startDate,
        'deadline': deadline.isNotEmpty ? deadline : null,
        'isActive': isActive,
      };
      await _apiService.updateGoal(goalId, data);
      userGoals = await _apiService.fetchMyGoals();
      notifyListeners();
    } catch (e) {
      debugPrint("AppState: Failed to update goal: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeGoal(String goalId, {String? mockGoalName}) async {
    final targetUserId = loggedInUserId;
    if (targetUserId == null) {
      // Mock mode
      userGoalsMock.removeWhere((g) => g['goalId'] == goalId || g['title'] == mockGoalName || g['goalName'] == mockGoalName);
      userGoals = List.from(userGoalsMock);
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.deleteGoal(goalId);
      userGoals = await _apiService.fetchMyGoals();
      notifyListeners();
    } catch (e) {
      debugPrint("AppState: Failed to delete goal: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> scanFood(List<int> bytes, String filename) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (loggedInUserId == null) {
        // Guest mode fallback (always simulate success for Banh Mi)
        await Future.delayed(const Duration(seconds: 2));
        final mockResult = {
          'analysisId': 'mock-scan-${DateTime.now().millisecondsSinceEpoch}',
          'foodName': 'Pho Bo (Mock Scan)',
          'confidence': 0.98,
          'calories': 500,
          'protein': 25.0,
          'carbs': 60.0,
          'fats': 12.0,
          'fiber': 3.0,
          'sodium': 1200.0,
          'description': 'Vietnamese beef noodle soup with rice noodles, sliced beef, and fresh herbs.',
          'aiNotes': 'Excellent protein source. Broth contains high sodium, so consume in moderation.',
          'createdAt': DateTime.now().toIso8601String(),
        };
        foodAnalysisHistory.insert(0, mockResult);
        if (foodAnalysisHistory.length > 5) {
          foodAnalysisHistory = foodAnalysisHistory.take(5).toList();
        }
        return mockResult;
      }

      final result = await _apiService.analyzeFood(bytes, filename);
      // Reload history to ensure it syncs with backend limit of 5
      foodAnalysisHistory = await _apiService.fetchFoodAnalysisHistory();
      notifyListeners();
      return result;
    } catch (e) {
      debugPrint("AppState: Failed to scan food: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<dynamic>> fetchSubscriptionPlans() async {
    try {
      return await _apiService.fetchSubscriptionPlans();
    } catch (e) {
      debugPrint("AppState: Failed to fetch plans: $e");
      // Fallback mock plan
      return [
        {
          'planId': '5b7d12f3-ea11-40ef-bc28-98d01cd59e0a',
          'planName': 'Plus',
          'description': 'Plus plan with 30 AI scans per 24 hours',
          'price': 50000.0,
          'durationDays': 30,
          'features': '30 scans/day, Advanced AI Coach, Priority response'
        }
      ];
    }
  }

  Future<Map<String, dynamic>> createPaymentLink(String planId) async {
    try {
      return await _apiService.createPaymentLink(planId);
    } catch (e) {
      debugPrint("AppState: Failed to create payment link: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> checkPaymentStatus(String userId) async {
    try {
      return await _apiService.checkPaymentStatus(userId);
    } catch (e) {
      debugPrint("AppState: Failed to check payment status: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> cancelPayment(String userId) async {
    try {
      return await _apiService.cancelPayment(userId);
    } catch (e) {
      debugPrint("AppState: Failed to cancel payment: $e");
      rethrow;
    }
  }
}
