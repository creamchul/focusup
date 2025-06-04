import 'package:flutter/material.dart';

// 배지 타입 enum
enum BadgeType {
  firstFocus,      // 첫 집중
  earlyBird,       // 아침 일찍 집중
  nightOwl,        // 밤 늦게 집중
  marathon,        // 장시간 집중
  consistent,      // 일주일 연속
  focused,         // 중간에 포기하지 않음
  explorer,        // 모든 카테고리 시도
  speedster,       // 짧은 시간 많이
  dedication,      // 한 카테고리 집중
  perfectionist,   // 완벽한 포모도로
}

// 배지 모델
class Badge {
  final BadgeType type;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final DateTime earnedAt;
  final bool isEarned;

  const Badge({
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.earnedAt,
    this.isEarned = false,
  });

  Badge copyWith({
    BadgeType? type,
    String? name,
    String? description,
    IconData? icon,
    Color? color,
    DateTime? earnedAt,
    bool? isEarned,
  }) {
    return Badge(
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      earnedAt: earnedAt ?? this.earnedAt,
      isEarned: isEarned ?? this.isEarned,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'name': name,
      'description': description,
      'earnedAt': earnedAt.toIso8601String(),
      'isEarned': isEarned,
    };
  }

  factory Badge.fromJson(Map<String, dynamic> json) {
    final badgeType = BadgeType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => BadgeType.firstFocus,
    );
    final badgeInfo = BadgeData.getBadgeInfo(badgeType);
    
    return Badge(
      type: badgeType,
      name: json['name'] ?? badgeInfo['name'],
      description: json['description'] ?? badgeInfo['description'],
      icon: badgeInfo['icon'],
      color: badgeInfo['color'],
      earnedAt: DateTime.parse(json['earnedAt']),
      isEarned: json['isEarned'] ?? false,
    );
  }
}

// 경험치 및 레벨 모델
class UserProgress {
  final int totalExp;
  final int currentLevel;
  final int currentLevelExp;
  final int expToNextLevel;
  final int totalFocusMinutes;
  final int totalSessions;
  final int currentStreak;
  final int maxStreak;
  final String currentTitle;
  final List<Badge> earnedBadges;
  final AnimalCompanion animal;

  UserProgress({
    this.totalExp = 0,
    this.currentLevel = 1,
    this.currentLevelExp = 0,
    this.expToNextLevel = 100,
    this.totalFocusMinutes = 0,
    this.totalSessions = 0,
    this.currentStreak = 0,
    this.maxStreak = 0,
    this.currentTitle = '집중 새싹',
    this.earnedBadges = const [],
    AnimalCompanion? animal,
  }) : animal = animal ?? AnimalCompanion();

  UserProgress copyWith({
    int? totalExp,
    int? currentLevel,
    int? currentLevelExp,
    int? expToNextLevel,
    int? totalFocusMinutes,
    int? totalSessions,
    int? currentStreak,
    int? maxStreak,
    String? currentTitle,
    List<Badge>? earnedBadges,
    AnimalCompanion? animal,
  }) {
    return UserProgress(
      totalExp: totalExp ?? this.totalExp,
      currentLevel: currentLevel ?? this.currentLevel,
      currentLevelExp: currentLevelExp ?? this.currentLevelExp,
      expToNextLevel: expToNextLevel ?? this.expToNextLevel,
      totalFocusMinutes: totalFocusMinutes ?? this.totalFocusMinutes,
      totalSessions: totalSessions ?? this.totalSessions,
      currentStreak: currentStreak ?? this.currentStreak,
      maxStreak: maxStreak ?? this.maxStreak,
      currentTitle: currentTitle ?? this.currentTitle,
      earnedBadges: earnedBadges ?? this.earnedBadges,
      animal: animal ?? this.animal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalExp': totalExp,
      'currentLevel': currentLevel,
      'currentLevelExp': currentLevelExp,
      'expToNextLevel': expToNextLevel,
      'totalFocusMinutes': totalFocusMinutes,
      'totalSessions': totalSessions,
      'currentStreak': currentStreak,
      'maxStreak': maxStreak,
      'currentTitle': currentTitle,
      'earnedBadges': earnedBadges.map((badge) => badge.toJson()).toList(),
      'animal': animal.toJson(),
    };
  }

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      totalExp: json['totalExp'] ?? 0,
      currentLevel: json['currentLevel'] ?? 1,
      currentLevelExp: json['currentLevelExp'] ?? 0,
      expToNextLevel: json['expToNextLevel'] ?? 100,
      totalFocusMinutes: json['totalFocusMinutes'] ?? 0,
      totalSessions: json['totalSessions'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      maxStreak: json['maxStreak'] ?? 0,
      currentTitle: json['currentTitle'] ?? '집중 새싹',
      earnedBadges: (json['earnedBadges'] as List<dynamic>?)
          ?.map((badgeJson) => Badge.fromJson(badgeJson))
          .toList() ?? [],
      animal: json['animal'] != null 
          ? AnimalCompanion.fromJson(json['animal']) 
          : AnimalCompanion(),
    );
  }
}

// 동물 종류
enum AnimalType {
  cat,        // 🐱 고양이
  dog,        // 🐶 강아지
  rabbit,     // 🐰 토끼
  penguin,    // 🐧 펭귄
  fox,        // 🦊 여우
  lion,       // 🦁 사자
  wolf,       // 🐺 늑대
  eagle,      // 🦅 독수리
  bear,       // 🐻 곰
  owl,        // 🦉 부엉이
  zebra,      // 🦓 얼룩말
  elephant,   // 🐘 코끼리
  giraffe,    // 🦒 기린
  butterfly,  // 🦋 나비
  dragon,     // 🐲 용
}

// 동물 단계
enum AnimalStage {
  basic,      // 기본 단계
  evolved,    // 진화 단계
  special,    // 특별 단계
  legendary,  // 전설 단계
}

// 동물 동반자 모델
class AnimalCompanion {
  final AnimalType type;
  final AnimalStage stage;
  final int bondLevel; // 유대 레벨 (집중 시간에 따라 증가)
  final DateTime discoveredAt;
  final bool isActive; // 현재 활성화된 동물인지

  AnimalCompanion({
    this.type = AnimalType.cat,
    this.stage = AnimalStage.basic,
    this.bondLevel = 0,
    DateTime? discoveredAt,
    this.isActive = true,
  }) : discoveredAt = discoveredAt ?? DateTime.now();

  AnimalCompanion copyWith({
    AnimalType? type,
    AnimalStage? stage,
    int? bondLevel,
    DateTime? discoveredAt,
    bool? isActive,
  }) {
    return AnimalCompanion(
      type: type ?? this.type,
      stage: stage ?? this.stage,
      bondLevel: bondLevel ?? this.bondLevel,
      discoveredAt: discoveredAt ?? this.discoveredAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'stage': stage.name,
      'bondLevel': bondLevel,
      'discoveredAt': discoveredAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory AnimalCompanion.fromJson(Map<String, dynamic> json) {
    return AnimalCompanion(
      type: AnimalType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AnimalType.cat,
      ),
      stage: AnimalStage.values.firstWhere(
        (e) => e.name == json['stage'],
        orElse: () => AnimalStage.basic,
      ),
      bondLevel: json['bondLevel'] ?? 0,
      discoveredAt: json['discoveredAt'] != null 
          ? DateTime.parse(json['discoveredAt'])
          : DateTime.now(),
      isActive: json['isActive'] ?? true,
    );
  }
}

// 배지 정보 데이터
class BadgeData {
  static Map<String, dynamic> getBadgeInfo(BadgeType type) {
    switch (type) {
      case BadgeType.firstFocus:
        return {
          'name': '첫 걸음',
          'description': '첫 번째 집중을 완료했습니다',
          'icon': Icons.star,
          'color': Colors.amber,
        };
      case BadgeType.earlyBird:
        return {
          'name': '일찍 일어나는 새',
          'description': '오전 6시 이전에 집중했습니다',
          'icon': Icons.wb_sunny,
          'color': Colors.orange,
        };
      case BadgeType.nightOwl:
        return {
          'name': '올빼미',
          'description': '밤 10시 이후에 집중했습니다',
          'icon': Icons.nightlight,
          'color': Colors.indigo,
        };
      case BadgeType.marathon:
        return {
          'name': '마라톤 러너',
          'description': '60분 이상 연속 집중했습니다',
          'icon': Icons.directions_run,
          'color': Colors.red,
        };
      case BadgeType.consistent:
        return {
          'name': '꾸준함의 힘',
          'description': '7일 연속 집중했습니다',
          'icon': Icons.calendar_today,
          'color': Colors.green,
        };
      case BadgeType.focused:
        return {
          'name': '집중력 마스터',
          'description': '중간에 포기하지 않고 완주했습니다',
          'icon': Icons.psychology,
          'color': Colors.purple,
        };
      case BadgeType.explorer:
        return {
          'name': '탐험가',
          'description': '모든 카테고리에서 집중했습니다',
          'icon': Icons.explore,
          'color': Colors.teal,
        };
      case BadgeType.speedster:
        return {
          'name': '스피드 러너',
          'description': '하루에 5회 이상 집중했습니다',
          'icon': Icons.flash_on,
          'color': Colors.yellow,
        };
      case BadgeType.dedication:
        return {
          'name': '전문가',
          'description': '한 카테고리에서 10회 집중했습니다',
          'icon': Icons.workspace_premium,
          'color': Colors.blue,
        };
      case BadgeType.perfectionist:
        return {
          'name': '완벽주의자',
          'description': '포모도로를 완벽하게 완주했습니다',
          'icon': Icons.check_circle,
          'color': Colors.pink,
        };
    }
  }

  static List<BadgeType> getAllBadgeTypes() {
    return BadgeType.values;
  }
}

// 칭호 데이터
class TitleData {
  static String getTitleByLevel(int level) {
    if (level >= 50) return '동물의 왕';
    if (level >= 30) return '사파리 마스터';
    if (level >= 20) return '야생동물 전문가';
    if (level >= 15) return '동물 훈련사';
    if (level >= 10) return '동물 친구';
    if (level >= 5) return '집중 탐험가';
    return '집중 새싹';
  }

  static Color getTitleColor(String title) {
    switch (title) {
      case '동물의 왕': return Colors.red;
      case '사파리 마스터': return Colors.purple;
      case '야생동물 전문가': return Colors.blue;
      case '동물 훈련사': return Colors.green;
      case '동물 친구': return Colors.orange;
      case '집중 탐험가': return Colors.amber;
      default: return Colors.grey;
    }
  }
}

// 동물별 정보 데이터
class AnimalData {
  static String getAnimalEmoji(AnimalType type) {
    switch (type) {
      case AnimalType.cat: return '🐱';
      case AnimalType.dog: return '🐶';
      case AnimalType.rabbit: return '🐰';
      case AnimalType.penguin: return '🐧';
      case AnimalType.fox: return '🦊';
      case AnimalType.lion: return '🦁';
      case AnimalType.wolf: return '🐺';
      case AnimalType.eagle: return '🦅';
      case AnimalType.bear: return '🐻';
      case AnimalType.owl: return '🦉';
      case AnimalType.zebra: return '🦓';
      case AnimalType.elephant: return '🐘';
      case AnimalType.giraffe: return '🦒';
      case AnimalType.butterfly: return '🦋';
      case AnimalType.dragon: return '🐲';
    }
  }

  static String getAnimalName(AnimalType type) {
    switch (type) {
      case AnimalType.cat: return '고양이';
      case AnimalType.dog: return '강아지';
      case AnimalType.rabbit: return '토끼';
      case AnimalType.penguin: return '펭귄';
      case AnimalType.fox: return '여우';
      case AnimalType.lion: return '사자';
      case AnimalType.wolf: return '늑대';
      case AnimalType.eagle: return '독수리';
      case AnimalType.bear: return '곰';
      case AnimalType.owl: return '부엉이';
      case AnimalType.zebra: return '얼룩말';
      case AnimalType.elephant: return '코끼리';
      case AnimalType.giraffe: return '기린';
      case AnimalType.butterfly: return '나비';
      case AnimalType.dragon: return '용';
    }
  }

  static String getAnimalDescription(AnimalType type) {
    switch (type) {
      case AnimalType.cat: return '집중력이 좋은 고양이';
      case AnimalType.dog: return '충실한 집중 파트너';
      case AnimalType.rabbit: return '빠른 집중력';
      case AnimalType.penguin: return '차분한 집중';
      case AnimalType.fox: return '영리한 집중';
      case AnimalType.lion: return '집중의 왕';
      case AnimalType.wolf: return '끈기와 인내';
      case AnimalType.eagle: return '높은 목표 달성';
      case AnimalType.bear: return '강인한 집중력';
      case AnimalType.owl: return '밤늦은 집중';
      case AnimalType.zebra: return '규칙적인 집중';
      case AnimalType.elephant: return '기억력 천재';
      case AnimalType.giraffe: return '높은 목표 달성';
      case AnimalType.butterfly: return '완전한 변화';
      case AnimalType.dragon: return '집중의 전설';
    }
  }

  // 동물 해금 조건 (총 집중 시간 기준)
  static int getUnlockHours(AnimalType type) {
    switch (type) {
      case AnimalType.cat: return 0;      // 기본 동물
      case AnimalType.dog: return 3;      
      case AnimalType.rabbit: return 5;   
      case AnimalType.penguin: return 10;  
      case AnimalType.fox: return 15;     
      case AnimalType.lion: return 25;    
      case AnimalType.wolf: return 30;    
      case AnimalType.eagle: return 40;   
      case AnimalType.bear: return 50;    
      case AnimalType.owl: return 60;     
      case AnimalType.zebra: return 70;   // 연속 7일 + 70시간
      case AnimalType.elephant: return 100; // 연속 14일 + 100시간
      case AnimalType.giraffe: return 150; // 연속 30일 + 150시간
      case AnimalType.butterfly: return 80; // 레벨 20 + 80시간
      case AnimalType.dragon: return 200;  // 레벨 50 + 200시간
    }
  }

  // 특별 해금 조건이 있는 동물들
  static Map<String, dynamic> getSpecialUnlockCondition(AnimalType type) {
    switch (type) {
      case AnimalType.zebra:
        return {'streakDays': 7, 'description': '7일 연속 집중'};
      case AnimalType.elephant:
        return {'streakDays': 14, 'description': '14일 연속 집중'};
      case AnimalType.giraffe:
        return {'streakDays': 30, 'description': '30일 연속 집중'};
      case AnimalType.butterfly:
        return {'level': 20, 'description': '레벨 20 달성'};
      case AnimalType.dragon:
        return {'level': 50, 'description': '레벨 50 달성'};
      default:
        return {};
    }
  }

  // 동물이 해금되었는지 확인
  static bool isUnlocked(AnimalType type, int totalHours, int streakDays, int level) {
    final requiredHours = getUnlockHours(type);
    final specialCondition = getSpecialUnlockCondition(type);
    
    // 기본 시간 조건
    if (totalHours < requiredHours) return false;
    
    // 특별 조건 확인
    if (specialCondition.containsKey('streakDays')) {
      if (streakDays < specialCondition['streakDays']) return false;
    }
    
    if (specialCondition.containsKey('level')) {
      if (level < specialCondition['level']) return false;
    }
    
    return true;
  }

  // 다음 해금 동물 가져오기
  static AnimalType getNextUnlockAnimal(int totalHours, int streakDays, int level) {
    AnimalType highestUnlocked = AnimalType.cat;
    
    // 모든 동물을 순회하면서 해금 가능한 가장 높은 레벨의 동물 찾기
    for (final type in AnimalType.values) {
      if (isUnlocked(type, totalHours, streakDays, level)) {
        // 현재 동물의 해금 시간이 이전에 찾은 동물보다 크면 업데이트
        if (getUnlockHours(type) > getUnlockHours(highestUnlocked)) {
          highestUnlocked = type;
        }
      }
    }
    
    return highestUnlocked;
  }

  // 다음으로 해금해야 할 동물 찾기
  static AnimalType getNextUnlockTarget(int totalHours, int streakDays, int level) {
    // 현재 해금된 가장 높은 레벨의 동물 찾기
    AnimalType currentHighest = getNextUnlockAnimal(totalHours, streakDays, level);
    
    // 다음으로 해금해야 할 동물 찾기
    for (final type in AnimalType.values) {
      if (!isUnlocked(type, totalHours, streakDays, level) && 
          getUnlockHours(type) > getUnlockHours(currentHighest)) {
        return type;
      }
    }
    
    // 모든 동물이 해금되었다면 마지막 동물 반환
    return AnimalType.dragon;
  }
} 