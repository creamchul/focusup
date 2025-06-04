import 'dart:developer' as dev;
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';
import '../models/focus_category_model.dart';

/// 집중 패턴 분석 데이터
class FocusPattern {
  final int hourOfDay;
  final double averageFocusTime;
  final int sessionCount;
  final double efficiency; // 목표 대비 달성률

  const FocusPattern({
    required this.hourOfDay,
    required this.averageFocusTime,
    required this.sessionCount,
    required this.efficiency,
  });
}

/// 생산성 지표
class ProductivityMetrics {
  final double weeklyAverage;
  final double monthlyAverage;
  final double streak;
  final double consistency; // 규칙성 점수 (0-1)
  final Map<String, double> categoryDistribution;
  final List<FocusPattern> hourlyPattern;

  const ProductivityMetrics({
    required this.weeklyAverage,
    required this.monthlyAverage,
    required this.streak,
    required this.consistency,
    required this.categoryDistribution,
    required this.hourlyPattern,
  });
}

/// 목표 달성 데이터
class GoalProgress {
  final int dailyGoal;
  final int currentProgress;
  final double achievementRate;
  final int streak;
  final List<bool> weeklyAchievements;

  const GoalProgress({
    required this.dailyGoal,
    required this.currentProgress,
    required this.achievementRate,
    required this.streak,
    required this.weeklyAchievements,
  });
}

class AnalyticsService {
  static const String _dailyGoalKey = 'daily_focus_goal';
  static const String _hourlyDataKeyPrefix = 'hourly_focus_';
  
  /// 일일 목표 시간 설정 (분)
  static Future<void> setDailyGoal(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyGoalKey, minutes);
    dev.log('일일 목표 설정: $minutes분');
  }
  
  /// 일일 목표 시간 조회
  static Future<int> getDailyGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_dailyGoalKey) ?? 120; // 기본 2시간
  }
  
  /// 시간대별 집중 데이터 저장
  static Future<void> recordHourlyFocus(int hour, int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final key = '$_hourlyDataKeyPrefix${today}_$hour';
    
    final currentMinutes = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, currentMinutes + minutes);
    
    dev.log('시간대별 집중 데이터 저장: ${hour}시 +$minutes분');
  }
  
  /// 생산성 지표 계산
  static Future<ProductivityMetrics> calculateProductivityMetrics() async {
    try {
      // 주간/월간 평균 계산
      final weeklyData = StorageService.getWeeklyFocusTime();
      final monthlyData = StorageService.getMonthlyFocusTime();
      
      final weeklyAverage = weeklyData.isNotEmpty 
          ? weeklyData.reduce((a, b) => a + b) / weeklyData.length 
          : 0.0;
      
      final monthlyAverage = monthlyData.isNotEmpty 
          ? monthlyData.reduce((a, b) => a + b) / monthlyData.length 
          : 0.0;
      
      // 연속 집중 일수
      final streak = StorageService.getStreakDays().toDouble();
      
      // 일관성 점수 계산 (표준편차의 역수)
      final consistency = _calculateConsistency(weeklyData);
      
      // 카테고리별 분포
      final categoryDistribution = await _calculateCategoryDistribution();
      
      // 시간대별 패턴
      final hourlyPattern = await _calculateHourlyPattern();
      
      return ProductivityMetrics(
        weeklyAverage: weeklyAverage,
        monthlyAverage: monthlyAverage,
        streak: streak,
        consistency: consistency,
        categoryDistribution: categoryDistribution,
        hourlyPattern: hourlyPattern,
      );
    } catch (e) {
      dev.log('생산성 지표 계산 실패: $e');
      return const ProductivityMetrics(
        weeklyAverage: 0,
        monthlyAverage: 0,
        streak: 0,
        consistency: 0,
        categoryDistribution: {},
        hourlyPattern: [],
      );
    }
  }
  
  /// 목표 달성률 계산
  static Future<GoalProgress> calculateGoalProgress() async {
    try {
      final dailyGoal = await getDailyGoal();
      final currentProgress = StorageService.getTodayFocusTime();
      final achievementRate = dailyGoal > 0 ? (currentProgress / dailyGoal).clamp(0.0, 1.0) : 0.0;
      
      // 최근 7일 달성 여부
      final weeklyData = StorageService.getWeeklyFocusTime();
      final weeklyAchievements = weeklyData.map((minutes) => minutes >= dailyGoal).toList();
      
      // 연속 달성 일수 계산
      int currentStreak = 0;
      for (int i = weeklyAchievements.length - 1; i >= 0; i--) {
        if (weeklyAchievements[i]) {
          currentStreak++;
        } else {
          break;
        }
      }
      
      return GoalProgress(
        dailyGoal: dailyGoal,
        currentProgress: currentProgress,
        achievementRate: achievementRate,
        streak: currentStreak,
        weeklyAchievements: weeklyAchievements,
      );
    } catch (e) {
      dev.log('목표 달성률 계산 실패: $e');
      return const GoalProgress(
        dailyGoal: 120,
        currentProgress: 0,
        achievementRate: 0.0,
        streak: 0,
        weeklyAchievements: [],
      );
    }
  }
  
  /// 최적 집중 시간대 분석
  static Future<List<int>> getBestFocusHours() async {
    try {
      final hourlyPattern = await _calculateHourlyPattern();
      
      // 평균 집중 시간으로 정렬
      final sortedHours = hourlyPattern.toList()
        ..sort((a, b) => b.averageFocusTime.compareTo(a.averageFocusTime));
      
      // 상위 3개 시간대 반환
      return sortedHours.take(3).map((p) => p.hourOfDay).toList();
    } catch (e) {
      dev.log('최적 집중 시간대 분석 실패: $e');
      return [9, 14, 20]; // 기본값
    }
  }
  
  /// 주간 트렌드 분석
  static Future<Map<String, dynamic>> analyzeWeeklyTrend() async {
    try {
      final weeklyData = StorageService.getWeeklyFocusTime();
      
      if (weeklyData.length < 2) {
        return {
          'trend': 'insufficient_data',
          'change': 0.0,
          'prediction': 0.0,
        };
      }
      
      // 선형 회귀로 트렌드 계산
      double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
      final n = weeklyData.length;
      
      for (int i = 0; i < n; i++) {
        sumX += i;
        sumY += weeklyData[i];
        sumXY += i * weeklyData[i];
        sumX2 += i * i;
      }
      
      final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
      final intercept = (sumY - slope * sumX) / n;
      
      // 다음 주 예측
      final prediction = slope * n + intercept;
      
      // 변화율 계산
      final firstHalf = weeklyData.take(n ~/ 2).reduce((a, b) => a + b) / (n ~/ 2);
      final secondHalf = weeklyData.skip(n ~/ 2).reduce((a, b) => a + b) / (n - n ~/ 2);
      final changeRate = firstHalf > 0 ? ((secondHalf - firstHalf) / firstHalf) * 100 : 0.0;
      
      String trend;
      if (slope > 5) {
        trend = 'increasing';
      } else if (slope < -5) {
        trend = 'decreasing';
      } else {
        trend = 'stable';
      }
      
      return {
        'trend': trend,
        'change': changeRate,
        'prediction': prediction.clamp(0, 480), // 최대 8시간
        'slope': slope,
      };
    } catch (e) {
      dev.log('주간 트렌드 분석 실패: $e');
      return {
        'trend': 'stable',
        'change': 0.0,
        'prediction': 0.0,
      };
    }
  }
  
  /// 개인화된 추천 생성
  static Future<List<String>> generateRecommendations() async {
    final recommendations = <String>[];
    
    try {
      final metrics = await calculateProductivityMetrics();
      final goalProgress = await calculateGoalProgress();
      final bestHours = await getBestFocusHours();
      final trend = await analyzeWeeklyTrend();
      
      // 목표 달성률 기반 추천
      if (goalProgress.achievementRate < 0.5) {
        recommendations.add('일일 목표를 더 작은 단위로 나누어 보세요. 작은 성공이 큰 변화를 만듭니다.');
      } else if (goalProgress.achievementRate > 0.9) {
        recommendations.add('목표를 달성하고 있어요! 더 도전적인 목표를 설정해보는 것은 어떨까요?');
      }
      
      // 일관성 기반 추천
      if (metrics.consistency < 0.3) {
        recommendations.add('규칙적인 집중 시간을 만들어보세요. 매일 같은 시간에 집중하면 습관이 됩니다.');
      }
      
      // 최적 시간대 추천
      if (bestHours.isNotEmpty) {
        final bestHour = bestHours.first;
        recommendations.add('${bestHour}시경에 집중력이 가장 좋아요. 중요한 작업은 이 시간에 해보세요.');
      }
      
      // 트렌드 기반 추천
      switch (trend['trend']) {
        case 'decreasing':
          recommendations.add('최근 집중 시간이 줄어들고 있어요. 휴식이 필요한 시기일 수 있습니다.');
          break;
        case 'increasing':
          recommendations.add('집중 시간이 꾸준히 늘고 있어요! 이 패턴을 유지해보세요.');
          break;
      }
      
      // 스트릭 기반 추천
      if (metrics.streak >= 7) {
        recommendations.add('${metrics.streak.toInt()}일 연속 집중! 대단해요. 이 흐름을 이어가세요.');
      } else if (metrics.streak == 0) {
        recommendations.add('새로운 시작이에요. 작은 목표부터 차근차근 해보세요.');
      }
      
      // 카테고리 균형 추천
      if (metrics.categoryDistribution.length == 1) {
        recommendations.add('다양한 분야에 집중해보는 것도 좋아요. 뇌에 새로운 자극을 주세요.');
      }
      
      // 기본 추천이 없으면 일반적인 조언 추가
      if (recommendations.isEmpty) {
        recommendations.addAll([
          '꾸준히 집중하고 계시네요! 이 패턴을 유지해보세요.',
          '집중과 휴식의 균형이 중요해요. 적절한 휴식도 잊지 마세요.',
          '작은 목표들의 달성이 큰 성과로 이어집니다.',
        ]);
      }
      
      return recommendations.take(3).toList(); // 최대 3개 추천
    } catch (e) {
      dev.log('추천 생성 실패: $e');
      return [
        '꾸준한 집중이 가장 중요해요.',
        '작은 목표부터 시작해보세요.',
        '규칙적인 습관을 만들어보세요.',
      ];
    }
  }
  
  /// 일관성 점수 계산
  static double _calculateConsistency(List<int> data) {
    if (data.length < 2) return 0.0;
    
    final mean = data.reduce((a, b) => a + b) / data.length;
    final variance = data.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / data.length;
    final standardDeviation = variance > 0 ? variance : 1.0;
    
    // 표준편차가 작을수록 일관성이 높음 (0-1 사이로 정규화)
    return (1.0 / (1.0 + standardDeviation / mean)).clamp(0.0, 1.0);
  }
  
  /// 카테고리별 분포 계산
  static Future<Map<String, double>> _calculateCategoryDistribution() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categories = FocusCategoryModel.getDefaultCategories();
      final distribution = <String, double>{};
      
      int totalTime = 0;
      
      // 각 카테고리별 총 시간 계산
      for (final category in categories) {
        final categoryTime = StorageService.getCategoryTotalFocusTime(category.id);
        distribution[category.name] = categoryTime.toDouble();
        totalTime += categoryTime;
      }
      
      // 백분율로 변환
      if (totalTime > 0) {
        distribution.updateAll((key, value) => (value / totalTime) * 100);
      }
      
      return distribution;
    } catch (e) {
      dev.log('카테고리 분포 계산 실패: $e');
      return {};
    }
  }
  
  /// 시간대별 패턴 계산
  static Future<List<FocusPattern>> _calculateHourlyPattern() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final patterns = <FocusPattern>[];
      
      // 최근 7일간의 시간대별 데이터 수집
      for (int hour = 0; hour < 24; hour++) {
        int totalMinutes = 0;
        int sessionCount = 0;
        
        for (int day = 0; day < 7; day++) {
          final date = DateTime.now().subtract(Duration(days: day));
          final dateString = date.toIso8601String().split('T')[0];
          final key = '$_hourlyDataKeyPrefix${dateString}_$hour';
          
          final minutes = prefs.getInt(key) ?? 0;
          if (minutes > 0) {
            totalMinutes += minutes;
            sessionCount++;
          }
        }
        
        final averageFocusTime = sessionCount > 0 ? totalMinutes / sessionCount : 0.0;
        final efficiency = averageFocusTime > 0 ? (averageFocusTime / 60).clamp(0.0, 1.0) : 0.0;
        
        patterns.add(FocusPattern(
          hourOfDay: hour,
          averageFocusTime: averageFocusTime,
          sessionCount: sessionCount,
          efficiency: efficiency,
        ));
      }
      
      return patterns;
    } catch (e) {
      dev.log('시간대별 패턴 계산 실패: $e');
      return [];
    }
  }
  
  /// 모든 분석 데이터 초기화 (테스트용)
  static Future<void> clearAnalyticsData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => 
        key.startsWith(_hourlyDataKeyPrefix) ||
        key == _dailyGoalKey
      ).toList();
      
      for (final key in keys) {
        await prefs.remove(key);
      }
      
      dev.log('분석 데이터 초기화 완료');
    } catch (e) {
      dev.log('분석 데이터 초기화 실패: $e');
    }
  }
} 