import 'package:shared_preferences/shared_preferences.dart';
import '../models/stats_period.dart';
import 'category_service.dart';

/// 로컬 데이터 저장을 위한 서비스
class StorageService {
  static SharedPreferences? _prefs;
  
  /// 서비스 초기화
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  /// SharedPreferences 인스턴스 반환
  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('StorageService가 초기화되지 않았습니다. init()을 먼저 호출하세요.');
    }
    return _prefs!;
  }
  
  // ============================================================================
  // 집중 세션 관련 데이터
  // ============================================================================
  
  /// 특정 날짜의 집중 시간 저장 (카테고리별로도 관리)
  static Future<void> saveFocusSession({
    required int minutes,
    String? categoryId,
  }) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    // 전체 집중 시간 업데이트
    final todayFocus = getTodayFocusTime();
    await setTodayFocusTime(todayFocus + minutes);
    
    // 전체 집중 시간 업데이트
    await addToTotalFocusTime(minutes);
    
    // 세션 수 증가
    await incrementTotalSessions();
    
    // 카테고리별 시간 업데이트
    if (categoryId != null) {
      final categoryKey = 'category_time_${categoryId}_$today';
      final currentCategoryTime = prefs.getInt(categoryKey) ?? 0;
      await prefs.setInt(categoryKey, currentCategoryTime + minutes);
    }
    
    // 25분 이상일 때만 나무 증가
    if (minutes >= 25) {
      await incrementTotalTrees();
    }
    
    // 연속 일수 업데이트
    await _updateStreakDays();
  }
  
  /// 오늘 집중 시간 (분)
  static int getTodayFocusTime() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return prefs.getInt('today_focus_$today') ?? 0;
  }
  
  /// 오늘 집중 시간 저장
  static Future<void> setTodayFocusTime(int minutes) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    await prefs.setInt('today_focus_$today', minutes);
    
    // 날짜별 기록도 함께 저장
    await prefs.setInt('focus_time_$today', minutes);
  }
  
  /// 카테고리별 오늘 집중 시간
  static int getTodayCategoryFocusTime(String categoryId) {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return prefs.getInt('category_time_${categoryId}_$today') ?? 0;
  }
  
  /// 카테고리별 총 집중 시간
  static int getCategoryTotalFocusTime(String categoryId) {
    return prefs.getInt('category_total_$categoryId') ?? 0;
  }
  
  /// 총 집중 세션 수
  static int getTotalSessions() {
    return prefs.getInt('total_sessions') ?? 0;
  }
  
  /// 총 집중 세션 수 증가
  static Future<void> incrementTotalSessions() async {
    final current = getTotalSessions();
    await prefs.setInt('total_sessions', current + 1);
  }
  
  /// 연속 집중 일수
  static int getStreakDays() {
    return prefs.getInt('streak_days') ?? 0;
  }
  
  /// 연속 집중 일수 업데이트
  static Future<void> updateStreakDays(int days) async {
    await prefs.setInt('streak_days', days);
  }
  
  /// 마지막 집중 날짜
  static String? getLastFocusDate() {
    return prefs.getString('last_focus_date');
  }
  
  /// 마지막 집중 날짜 업데이트
  static Future<void> updateLastFocusDate(String date) async {
    await prefs.setString('last_focus_date', date);
  }
  
  /// 연속 일수 자동 업데이트 (내부 메서드)
  static Future<void> _updateStreakDays() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastFocusDate = getLastFocusDate();
    
    if (lastFocusDate == null) {
      // 첫 집중 세션
      await updateStreakDays(1);
    } else {
      final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().split('T')[0];
      
      if (lastFocusDate == yesterday) {
        // 연속 집중
        final currentStreak = getStreakDays();
        await updateStreakDays(currentStreak + 1);
      } else if (lastFocusDate != today) {
        // 연속성 깨짐
        await updateStreakDays(1);
      }
    }
    
    await updateLastFocusDate(today);
  }

  // ============================================================================
  // 나무 관련 데이터
  // ============================================================================
  
  /// 심은 나무 총 개수
  static int getTotalTrees() {
    return prefs.getInt('total_trees') ?? 0;
  }
  
  /// 심은 나무 개수 증가
  static Future<void> incrementTotalTrees() async {
    final current = getTotalTrees();
    await prefs.setInt('total_trees', current + 1);
  }
  
  /// 현재 숲 레벨
  static int getForestLevel() {
    final trees = getTotalTrees();
    return (trees / 10).floor() + 1;
  }
  
  // ============================================================================
  // 설정 관련 데이터
  // ============================================================================
  
  /// 기본 포모도로 시간 (분)
  static int getDefaultPomodoroTime() {
    return prefs.getInt('default_pomodoro_time') ?? 25;
  }
  
  /// 기본 포모도로 시간 설정
  static Future<void> setDefaultPomodoroTime(int minutes) async {
    await prefs.setInt('default_pomodoro_time', minutes);
  }
  
  /// 휴식 시간 (분)
  static int getBreakTime() {
    return prefs.getInt('break_time') ?? 5;
  }
  
  /// 휴식 시간 설정
  static Future<void> setBreakTime(int minutes) async {
    await prefs.setInt('break_time', minutes);
  }
  
  /// 알림 활성화 여부
  static bool isNotificationEnabled() {
    return prefs.getBool('notification_enabled') ?? true;
  }
  
  /// 알림 활성화 설정
  static Future<void> setNotificationEnabled(bool enabled) async {
    await prefs.setBool('notification_enabled', enabled);
  }
  
  /// 사운드 활성화 여부
  static bool isSoundEnabled() {
    return prefs.getBool('sound_enabled') ?? true;
  }
  
  /// 사운드 활성화 설정
  static Future<void> setSoundEnabled(bool enabled) async {
    await prefs.setBool('sound_enabled', enabled);
  }
  
  /// 다크 모드 활성화 여부
  static bool isDarkModeEnabled() {
    return prefs.getBool('dark_mode_enabled') ?? false;
  }
  
  /// 다크 모드 설정
  static Future<void> setDarkModeEnabled(bool enabled) async {
    await prefs.setBool('dark_mode_enabled', enabled);
  }
  
  // ============================================================================
  // 통계 관련 데이터
  // ============================================================================
  
  /// 일별 집중 시간 데이터 가져오기
  static Map<DateTime, int> getDailyFocusTime(DateTime date) {
    final Map<DateTime, int> data = {};
    for (var i = 0; i < 24; i++) {
      final hourDate = DateTime(date.year, date.month, date.day, i);
      final key = 'focus_time_${hourDate.toIso8601String()}';
      data[hourDate] = prefs.getInt(key) ?? 0;
    }
    return data;
  }

  /// 주간 집중 시간 데이터 가져오기
  static Map<DateTime, int> getWeeklyFocusTime(DateTime date) {
    final weekStart = date.subtract(Duration(days: date.weekday - 1));
    final Map<DateTime, int> data = {};
    
    for (var i = 0; i < 7; i++) {
      final dayDate = weekStart.add(Duration(days: i));
      final key = 'focus_time_${dayDate.toIso8601String().split('T')[0]}';
      data[dayDate] = prefs.getInt(key) ?? 0;
    }
    return data;
  }

  /// 월간 집중 시간 데이터 가져오기
  static Map<DateTime, int> getMonthlyFocusTime(DateTime date) {
    final Map<DateTime, int> data = {};
    final daysInMonth = DateTime(date.year, date.month + 1, 0).day;
    
    for (var i = 1; i <= daysInMonth; i++) {
      final dayDate = DateTime(date.year, date.month, i);
      final key = 'focus_time_${dayDate.toIso8601String().split('T')[0]}';
      data[dayDate] = prefs.getInt(key) ?? 0;
    }
    return data;
  }

  /// 연간 집중 시간 데이터 가져오기
  static Map<DateTime, int> getYearlyFocusTime(DateTime date) {
    final Map<DateTime, int> data = {};
    
    for (var i = 1; i <= 12; i++) {
      final monthDate = DateTime(date.year, i);
      var monthlyTotal = 0;
      final daysInMonth = DateTime(date.year, i + 1, 0).day;
      
      for (var day = 1; day <= daysInMonth; day++) {
        final dayDate = DateTime(date.year, i, day);
        final key = 'focus_time_${dayDate.toIso8601String().split('T')[0]}';
        monthlyTotal += prefs.getInt(key) ?? 0;
      }
      
      data[monthDate] = monthlyTotal;
    }
    return data;
  }
  
  /// 카테고리별 주간 집중 시간
  static Map<String, List<int>> getCategoryWeeklyFocusTime() {
    final now = DateTime.now();
    final categoryData = <String, List<int>>{};
    
    // 기본 카테고리들에 대해 데이터 수집
    const categories = ['work', 'study', 'exercise', 'reading', 'creative', 'meditation', 'hobby', 'other'];
    
    for (final categoryId in categories) {
      final weeklyData = <int>[];
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateString = date.toIso8601String().split('T')[0];
        final focusTime = prefs.getInt('category_time_${categoryId}_$dateString') ?? 0;
        weeklyData.add(focusTime);
      }
      categoryData[categoryId] = weeklyData;
    }
    
    return categoryData;
  }
  
  /// 전체 집중 시간 (분)
  static int getTotalFocusTime() {
    return prefs.getInt('total_focus_time') ?? 0;
  }
  
  /// 전체 집중 시간 업데이트
  static Future<void> addToTotalFocusTime(int minutes) async {
    final current = getTotalFocusTime();
    await prefs.setInt('total_focus_time', current + minutes);
  }

  // 최근 세션 기록 (간단한 구현)
  static List<Map<String, dynamic>> getRecentSessions() {
    // 실제로는 JSON으로 저장하지만 여기서는 간단히 구현
    return [
      {
        'date': DateTime.now().subtract(const Duration(hours: 2)),
        'duration': 25,
        'type': 'pomodoro',
        'categoryId': 'study',
      },
      {
        'date': DateTime.now().subtract(const Duration(days: 1)),
        'duration': 30,
        'type': 'free',
        'categoryId': 'work',
      },
    ];
  }

  // 데이터 초기화 (개발용)
  static Future<void> clearAllData() async {
    await prefs.clear();
    
    // 카테고리 데이터도 초기화
    await CategoryService.clearAllData();
  }

  // 테스트 데이터 설정 (개발용)
  static Future<void> setTestData() async {
    await setTodayFocusTime(180); // 3시간
    await prefs.setInt('total_sessions', 12);
    await prefs.setInt('total_trees', 23);
    await prefs.setInt('streak_days', 7);
    await prefs.setInt('total_focus_time', 750); // 12시간 30분
    await updateLastFocusDate(DateTime.now().toIso8601String().split('T')[0]);
    
    // 카테고리별 테스트 데이터
    final today = DateTime.now().toIso8601String().split('T')[0];
    await prefs.setInt('category_time_study_$today', 60);  // 공부 1시간
    await prefs.setInt('category_time_work_$today', 90);   // 업무 1.5시간
    await prefs.setInt('category_time_exercise_$today', 30); // 운동 30분
    
    // 주간 데이터 설정
    for (int i = 0; i < 7; i++) {
      final date = DateTime.now().subtract(Duration(days: i)).toIso8601String().split('T')[0];
      await prefs.setInt('focus_time_$date', 60 + (i * 20)); // 점진적으로 증가하는 패턴
    }
  }

  /// 기간 비교 데이터 가져오기 (일간)
  static Map<String, int> getCompareDailyData() {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDaysAgo = today.subtract(const Duration(days: 2));

    return {
      '오늘': prefs.getInt('focus_time_${today.toIso8601String().split('T')[0]}') ?? 0,
      '어제': prefs.getInt('focus_time_${yesterday.toIso8601String().split('T')[0]}') ?? 0,
      '그저께': prefs.getInt('focus_time_${twoDaysAgo.toIso8601String().split('T')[0]}') ?? 0,
    };
  }

  /// 기간 비교 데이터 가져오기 (주간)
  static Map<String, int> getCompareWeeklyData() {
    final now = DateTime.now();
    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
    final twoWeeksAgoStart = thisWeekStart.subtract(const Duration(days: 14));

    Map<String, int> data = {
      '이번 주': 0,
      '저번 주': 0,
      '저저번 주': 0,
    };

    // 이번 주
    for (var i = 0; i < 7; i++) {
      final date = thisWeekStart.add(Duration(days: i));
      final key = 'focus_time_${date.toIso8601String().split('T')[0]}';
      data['이번 주'] = (data['이번 주'] ?? 0) + (prefs.getInt(key) ?? 0);
    }

    // 저번 주
    for (var i = 0; i < 7; i++) {
      final date = lastWeekStart.add(Duration(days: i));
      final key = 'focus_time_${date.toIso8601String().split('T')[0]}';
      data['저번 주'] = (data['저번 주'] ?? 0) + (prefs.getInt(key) ?? 0);
    }

    // 저저번 주
    for (var i = 0; i < 7; i++) {
      final date = twoWeeksAgoStart.add(Duration(days: i));
      final key = 'focus_time_${date.toIso8601String().split('T')[0]}';
      data['저저번 주'] = (data['저저번 주'] ?? 0) + (prefs.getInt(key) ?? 0);
    }

    return data;
  }

  /// 기간 비교 데이터 가져오기 (월간)
  static Map<String, int> getCompareMonthlyData() {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final lastMonth = DateTime(now.year, now.month - 1);
    final twoMonthsAgo = DateTime(now.year, now.month - 2);

    Map<String, int> data = {
      '이번 달': 0,
      '저번 달': 0,
      '저저번 달': 0,
    };

    // 각 월의 데이터 계산
    for (var entry in [
      {'date': thisMonth, 'key': '이번 달'},
      {'date': lastMonth, 'key': '저번 달'},
      {'date': twoMonthsAgo, 'key': '저저번 달'},
    ]) {
      final date = entry['date'] as DateTime;
      final key = entry['key'] as String;
      final daysInMonth = DateTime(date.year, date.month + 1, 0).day;

      for (var day = 1; day <= daysInMonth; day++) {
        final dayDate = DateTime(date.year, date.month, day);
        final storageKey = 'focus_time_${dayDate.toIso8601String().split('T')[0]}';
        data[key] = (data[key] ?? 0) + (prefs.getInt(storageKey) ?? 0);
      }
    }

    return data;
  }

  /// 기간 비교 데이터 가져오기 (연간)
  static Map<String, int> getCompareYearlyData() {
    final now = DateTime.now();
    final thisYear = now.year;

    Map<String, int> data = {
      '올해': 0,
      '작년': 0,
      '재작년': 0,
    };

    // 각 연도의 데이터 계산
    for (var entry in [
      {'year': thisYear, 'key': '올해'},
      {'year': thisYear - 1, 'key': '작년'},
      {'year': thisYear - 2, 'key': '재작년'},
    ]) {
      final year = entry['year'] as int;
      final key = entry['key'] as String;

      for (var month = 1; month <= 12; month++) {
        final daysInMonth = DateTime(year, month + 1, 0).day;
        for (var day = 1; day <= daysInMonth; day++) {
          final date = DateTime(year, month, day);
          final storageKey = 'focus_time_${date.toIso8601String().split('T')[0]}';
          data[key] = (data[key] ?? 0) + (prefs.getInt(storageKey) ?? 0);
        }
      }
    }

    return data;
  }

  /// 카테고리별 집중 시간 분석 데이터 가져오기
  static Future<Map<String, int>> getCategoryAnalysis(StatsPeriod period, DateTime date) async {
    Map<String, int> data = {};
    final categories = await CategoryService.getCategories();

    switch (period) {
      case StatsPeriod.day:
        final dateStr = date.toIso8601String().split('T')[0];
        for (var category in categories) {
          final time = prefs.getInt('category_time_${category.id}_$dateStr') ?? 0;
          if (time > 0) {
            data[category.name] = time;
          }
        }
        break;

      case StatsPeriod.week:
        final weekStart = date.subtract(Duration(days: date.weekday - 1));
        for (var category in categories) {
          int total = 0;
          for (var i = 0; i < 7; i++) {
            final dayDate = weekStart.add(Duration(days: i));
            final dateStr = dayDate.toIso8601String().split('T')[0];
            total += prefs.getInt('category_time_${category.id}_$dateStr') ?? 0;
          }
          if (total > 0) {
            data[category.name] = total;
          }
        }
        break;

      case StatsPeriod.month:
        final daysInMonth = DateTime(date.year, date.month + 1, 0).day;
        for (var category in categories) {
          int total = 0;
          for (var day = 1; day <= daysInMonth; day++) {
            final dayDate = DateTime(date.year, date.month, day);
            final dateStr = dayDate.toIso8601String().split('T')[0];
            total += prefs.getInt('category_time_${category.id}_$dateStr') ?? 0;
          }
          if (total > 0) {
            data[category.name] = total;
          }
        }
        break;

      case StatsPeriod.year:
        for (var category in categories) {
          int total = 0;
          for (var month = 1; month <= 12; month++) {
            final daysInMonth = DateTime(date.year, month + 1, 0).day;
            for (var day = 1; day <= daysInMonth; day++) {
              final dayDate = DateTime(date.year, month, day);
              final dateStr = dayDate.toIso8601String().split('T')[0];
              total += prefs.getInt('category_time_${category.id}_$dateStr') ?? 0;
            }
          }
          if (total > 0) {
            data[category.name] = total;
          }
        }
        break;
    }

    return data;
  }
} 