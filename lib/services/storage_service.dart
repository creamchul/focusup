import 'package:shared_preferences/shared_preferences.dart';
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
  
  /// 주간 집중 시간 리스트 (최근 7일)
  static List<int> getWeeklyFocusTime() {
    final List<int> weeklyData = [];
    final now = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateString = date.toIso8601String().split('T')[0];
      final focusTime = prefs.getInt('focus_time_$dateString') ?? 0;
      weeklyData.add(focusTime);
    }
    
    return weeklyData;
  }
  
  /// 월간 집중 시간 리스트 (최근 30일)
  static List<int> getMonthlyFocusTime() {
    final List<int> monthlyData = [];
    final now = DateTime.now();
    
    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateString = date.toIso8601String().split('T')[0];
      final focusTime = prefs.getInt('focus_time_$dateString') ?? 0;
      monthlyData.add(focusTime);
    }
    
    return monthlyData;
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
} 