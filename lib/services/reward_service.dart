import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reward_models.dart';
import 'storage_service.dart';

class RewardService extends ChangeNotifier {
  static final RewardService _instance = RewardService._internal();
  factory RewardService() => _instance;
  RewardService._internal();

  UserProgress _userProgress = UserProgress();
  DateTime? _lastFocusDate;

  UserProgress get userProgress => _userProgress;
  DateTime? get lastFocusDate => _lastFocusDate;

  // UserProgress 접근자 메서드 추가
  Future<UserProgress> getUserProgress() async {
    await loadUserProgress();
    return _userProgress;
  }

  // 초기 로드
  Future<void> loadUserProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString('user_progress');
      final lastFocusDateString = prefs.getString('last_focus_date');

      if (progressJson != null) {
        final progressMap = jsonDecode(progressJson);
        _userProgress = UserProgress.fromJson(progressMap);
      }

      if (lastFocusDateString != null) {
        _lastFocusDate = DateTime.parse(lastFocusDateString);
      }

      dev.log('사용자 진행상황 로드: 레벨 ${_userProgress.currentLevel}, 경험치 ${_userProgress.totalExp}');
      notifyListeners();
    } catch (e) {
      dev.log('사용자 진행상황 로드 실패: $e');
    }
  }

  // 저장
  Future<void> saveUserProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = jsonEncode(_userProgress.toJson());
      await prefs.setString('user_progress', progressJson);
      
      if (_lastFocusDate != null) {
        await prefs.setString('last_focus_date', _lastFocusDate!.toIso8601String());
      }

      dev.log('사용자 진행상황 저장 완료');
    } catch (e) {
      dev.log('사용자 진행상황 저장 실패: $e');
    }
  }

  /// 집중 완료 시 보상 지급
  Future<List<String>> grantFocusReward({
    required int focusMinutes,
    required String categoryId,
    required bool wasCompleted,
    bool hadBreak = false,
  }) async {
    List<String> allAchievements = [];

    try {
      // 0. StorageService를 통해 집중 세션 데이터 저장
      await StorageService.saveFocusSession(
        minutes: focusMinutes,
        categoryId: categoryId,
      );
      
      // 1. 경험치 지급
      final expAchievements = await _grantExperience(focusMinutes, hadBreak);
      allAchievements.addAll(expAchievements);

      // 2. 집중 통계 업데이트
      await _updateFocusStats(focusMinutes, categoryId);

      // 3. 스트릭 업데이트
      final streakAchievements = await _updateStreak();
      allAchievements.addAll(streakAchievements);

      // 4. 식물 성장
      final plantAchievements = await _updatePlantGrowth(focusMinutes);
      allAchievements.addAll(plantAchievements);

      // 5. 배지 확인
      final badgeAchievements = await _checkBadges(focusMinutes, categoryId, wasCompleted);
      allAchievements.addAll(badgeAchievements);

      // 6. 칭호 업데이트
      final titleAchievements = await _updateTitle();
      allAchievements.addAll(titleAchievements);

      // 7. 변경사항 저장
      await saveUserProgress();
      
      dev.log('집중 보상 지급 완료: ${allAchievements.length}개 달성');
      
    } catch (e) {
      dev.log('집중 보상 지급 오류: $e');
    }

    return allAchievements;
  }

  // 경험치 지급
  Future<List<String>> _grantExperience(int focusMinutes, bool hadBreak) async {
    int expGained = _calculateExperience(focusMinutes, true, hadBreak);
    return await _addExperience(expGained);
  }

  // 경험치 계산
  int _calculateExperience(int minutes, bool completed, bool hadBreak) {
    int baseExp = minutes * 4; // 분당 4경험치
    
    if (completed) {
      baseExp += 20; // 완료 보너스
      if (hadBreak) {
        baseExp += 10; // 휴식 포함 보너스
      }
    }
    
    return baseExp;
  }

  // 경험치 추가 및 레벨업 확인
  Future<List<String>> _addExperience(int exp) async {
    List<String> achievements = [];
    
    int newTotalExp = _userProgress.totalExp + exp;
    int newCurrentLevelExp = _userProgress.currentLevelExp + exp;
    int currentLevel = _userProgress.currentLevel;
    int expToNextLevel = _userProgress.expToNextLevel;

    // 레벨업 확인
    while (newCurrentLevelExp >= expToNextLevel) {
      newCurrentLevelExp -= expToNextLevel;
      currentLevel++;
      expToNextLevel = _calculateExpForNextLevel(currentLevel);
      
      achievements.add('🎉 레벨 업! 레벨 $currentLevel 달성!');
      dev.log('레벨업: $currentLevel');
    }

    _userProgress = _userProgress.copyWith(
      totalExp: newTotalExp,
      currentLevel: currentLevel,
      currentLevelExp: newCurrentLevelExp,
      expToNextLevel: expToNextLevel,
    );

    return achievements;
  }

  // 다음 레벨까지 필요한 경험치 계산
  int _calculateExpForNextLevel(int level) {
    return 100 + (level * 50); // 레벨이 높아질수록 더 많은 경험치 필요
  }

  // 집중 통계 업데이트
  Future<void> _updateFocusStats(int minutes, String categoryId) async {
    _userProgress = _userProgress.copyWith(
      totalFocusMinutes: _userProgress.totalFocusMinutes + minutes,
      totalSessions: _userProgress.totalSessions + 1,
    );

    // 마지막 집중 날짜 업데이트
    _lastFocusDate = DateTime.now();
  }

  // 스트릭 업데이트
  Future<List<String>> _updateStreak() async {
    List<String> achievements = [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    int newStreak = _userProgress.currentStreak;
    
    if (_lastFocusDate != null) {
      final lastFocusDay = DateTime(
        _lastFocusDate!.year,
        _lastFocusDate!.month,
        _lastFocusDate!.day,
      );
      
      final daysDiff = today.difference(lastFocusDay).inDays;
      
      if (daysDiff == 0) {
        // 오늘 이미 집중했으면 스트릭 유지
      } else if (daysDiff == 1) {
        // 어제 집중했으면 스트릭 증가
        newStreak++;
        if (newStreak % 7 == 0) {
          achievements.add('🔥 ${newStreak}일 연속 집중! 불꽃이 더욱 뜨겁게!');
        } else if (newStreak == 3) {
          achievements.add('🔥 3일 연속 집중! 스트릭 시작!');
        }
      } else {
        // 하루 이상 건너뛰었으면 스트릭 리셋
        if (_userProgress.currentStreak > 0) {
          achievements.add('😞 연속 집중이 끊어졌습니다. 다시 시작해보세요!');
        }
        newStreak = 1;
      }
    } else {
      // 첫 집중
      newStreak = 1;
    }

    int maxStreak = _userProgress.maxStreak;
    if (newStreak > maxStreak) {
      maxStreak = newStreak;
      achievements.add('🏆 최고 연속 기록 갱신! ${maxStreak}일!');
    }

    _userProgress = _userProgress.copyWith(
      currentStreak: newStreak,
      maxStreak: maxStreak,
    );

    return achievements;
  }

  // 배지 확인 및 지급
  Future<List<String>> _checkBadges(int minutes, String categoryId, bool completed) async {
    List<String> achievements = [];
    List<Badge> earnedBadges = List.from(_userProgress.earnedBadges);

    // 첫 집중 배지
    if (_userProgress.totalSessions == 1) {
      earnedBadges.add(_createBadge(BadgeType.firstFocus));
      achievements.add('🏅 배지 획득: 첫 걸음');
    }

    // 마라톤 러너 (60분 이상)
    if (minutes >= 60 && !_hasBadge(BadgeType.marathon)) {
      earnedBadges.add(_createBadge(BadgeType.marathon));
      achievements.add('🏅 배지 획득: 마라톤 러너');
    }

    // 집중력 마스터 (완료)
    if (completed && !_hasBadge(BadgeType.focused)) {
      earnedBadges.add(_createBadge(BadgeType.focused));
      achievements.add('🏅 배지 획득: 집중력 마스터');
    }

    // 꾸준함의 힘 (7일 연속)
    if (_userProgress.currentStreak >= 7 && !_hasBadge(BadgeType.consistent)) {
      earnedBadges.add(_createBadge(BadgeType.consistent));
      achievements.add('🏅 배지 획득: 꾸준함의 힘');
    }

    // 시간대별 배지
    final hour = DateTime.now().hour;
    if (hour < 6 && !_hasBadge(BadgeType.earlyBird)) {
      earnedBadges.add(_createBadge(BadgeType.earlyBird));
      achievements.add('🏅 배지 획득: 일찍 일어나는 새');
    } else if (hour >= 22 && !_hasBadge(BadgeType.nightOwl)) {
      earnedBadges.add(_createBadge(BadgeType.nightOwl));
      achievements.add('🏅 배지 획득: 올빼미');
    }

    _userProgress = _userProgress.copyWith(earnedBadges: earnedBadges);
    return achievements;
  }

  // 식물 성장
  Future<List<String>> _updatePlantGrowth(int focusMinutes) async {
    return await _updateAnimalBond(focusMinutes);
  }

  // 동물 유대감 증가
  Future<List<String>> _updateAnimalBond(int minutes) async {
    List<String> achievements = [];
    AnimalCompanion currentAnimal = _userProgress.animal;
    
    // 유대 레벨 증가 (25분마다 1레벨)
    int bondIncrease = minutes ~/ 25;
    if (bondIncrease == 0 && minutes >= 5) bondIncrease = 1; // 최소 5분 집중하면 1레벨
    
    int newBondLevel = currentAnimal.bondLevel + bondIncrease;
    
    // 새로운 동물 해금 확인 (분 단위를 시간 단위로 정확하게 변환)
    final totalMinutes = _userProgress.totalFocusMinutes + minutes;
    final totalHours = totalMinutes ~/ 60; // 60분 = 1시간
    
    // 현재 해금 가능한 가장 높은 레벨의 동물 확인
    final nextAnimal = AnimalData.getNextUnlockAnimal(
      totalHours, 
      _userProgress.currentStreak, 
      _userProgress.currentLevel
    );
    
    // 현재 동물보다 더 높은 레벨의 동물이 해금되었는지 확인
    if (AnimalData.getUnlockHours(nextAnimal) > AnimalData.getUnlockHours(currentAnimal.type)) {
      // 새로운 동물로 변경
      final newAnimal = AnimalCompanion(
        type: nextAnimal,
        stage: AnimalStage.basic,
        bondLevel: 0,
        discoveredAt: DateTime.now(),
        isActive: true,
      );
      
      _userProgress = _userProgress.copyWith(animal: newAnimal);
      await saveUserProgress(); // 즉시 저장
      
      achievements.add('🎉 새로운 동물 친구! ${AnimalData.getAnimalEmoji(nextAnimal)} ${AnimalData.getAnimalName(nextAnimal)}을(를) 만났어요!');
    } else {
      // 기존 동물 유대감 증가
      AnimalCompanion updatedAnimal = currentAnimal.copyWith(
        bondLevel: newBondLevel,
      );
      
      _userProgress = _userProgress.copyWith(animal: updatedAnimal);
      await saveUserProgress(); // 즉시 저장
      
      if (bondIncrease > 0) {
        achievements.add('💕 ${AnimalData.getAnimalEmoji(currentAnimal.type)} ${AnimalData.getAnimalName(currentAnimal.type)}와(과) 더 친해졌어요! (유대 ${newBondLevel})');
      }
    }

    return achievements;
  }

  // 칭호 업데이트
  Future<List<String>> _updateTitle() async {
    List<String> achievements = [];
    String newTitle = TitleData.getTitleByLevel(_userProgress.currentLevel);
    
    if (newTitle != _userProgress.currentTitle) {
      _userProgress = _userProgress.copyWith(currentTitle: newTitle);
      achievements.add('👑 새로운 칭호 획득: $newTitle');
    }

    return achievements;
  }

  // 배지 보유 확인
  bool _hasBadge(BadgeType type) {
    return _userProgress.earnedBadges.any((badge) => badge.type == type);
  }

  // 배지 생성
  Badge _createBadge(BadgeType type) {
    final badgeInfo = BadgeData.getBadgeInfo(type);
    return Badge(
      type: type,
      name: badgeInfo['name'],
      description: badgeInfo['description'],
      icon: badgeInfo['icon'],
      color: badgeInfo['color'],
      earnedAt: DateTime.now(),
      isEarned: true,
    );
  }

  // 스트릭 불꽃 이모지 얻기
  String getStreakEmoji() {
    final streak = _userProgress.currentStreak;
    if (streak >= 30) return '🔥🔥🔥';
    if (streak >= 7) return '🔥🔥';
    if (streak >= 3) return '🔥';
    return '';
  }

  // 진행률 계산 (0.0 ~ 1.0)
  double getLevelProgress() {
    if (_userProgress.expToNextLevel == 0) return 1.0;
    return _userProgress.currentLevelExp / _userProgress.expToNextLevel;
  }

  // 데이터 리셋 (개발/테스트용)
  Future<void> resetProgress() async {
    _userProgress = UserProgress();
    _lastFocusDate = null;
    await saveUserProgress();
    notifyListeners();
    dev.log('사용자 진행상황 리셋 완료');
  }
} 