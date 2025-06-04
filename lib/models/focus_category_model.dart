import 'package:flutter/material.dart';

class FocusCategoryModel {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final bool isDefault;
  final bool isActive;
  final bool isFavorite;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FocusCategoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.isDefault = false,
    this.isActive = true,
    this.isFavorite = false,
    this.order = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FocusCategoryModel.fromMap(Map<String, dynamic> map) {
    return FocusCategoryModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      icon: IconData(
        map['iconCodePoint'] ?? Icons.category.codePoint,
        fontFamily: map['iconFontFamily'] ?? Icons.category.fontFamily,
      ),
      color: Color(map['colorValue'] ?? Colors.blue.value),
      isDefault: map['isDefault'] ?? false,
      isActive: map['isActive'] ?? true,
      isFavorite: map['isFavorite'] ?? false,
      order: map['order'] ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'colorValue': color.value,
      'isDefault': isDefault,
      'isActive': isActive,
      'isFavorite': isFavorite,
      'order': order,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  FocusCategoryModel copyWith({
    String? id,
    String? name,
    String? description,
    IconData? icon,
    Color? color,
    bool? isDefault,
    bool? isActive,
    bool? isFavorite,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FocusCategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      isFavorite: isFavorite ?? this.isFavorite,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'FocusCategoryModel(id: $id, name: $name, description: $description, isDefault: $isDefault, isActive: $isActive, order: $order)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FocusCategoryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Focus Forest 스타일 기본 카테고리들
  static List<FocusCategoryModel> getDefaultCategories() {
    final now = DateTime.now();
    return [
      FocusCategoryModel(
        id: 'work',
        name: '업무',
        description: '업무와 일 관련 집중',
        icon: Icons.work_outline,
        color: const Color(0xFF3B82F6), // 블루
        isDefault: true,
        order: 0,
        createdAt: now,
        updatedAt: now,
      ),
      FocusCategoryModel(
        id: 'study',
        name: '공부',
        description: '학습과 연구',
        icon: Icons.school_outlined,
        color: const Color(0xFF10B981), // 에메랄드 그린 (메인 컬러)
        isDefault: true,
        order: 1,
        createdAt: now,
        updatedAt: now,
      ),
      FocusCategoryModel(
        id: 'exercise',
        name: '운동',
        description: '체력 단련과 건강 관리',
        icon: Icons.fitness_center_outlined,
        color: const Color(0xFFF59E0B), // 오렌지
        isDefault: true,
        order: 2,
        createdAt: now,
        updatedAt: now,
      ),
      FocusCategoryModel(
        id: 'reading',
        name: '독서',
        description: '책 읽기와 문학 감상',
        icon: Icons.menu_book_outlined,
        color: const Color(0xFF8B5CF6), // 바이올렛
        isDefault: true,
        order: 3,
        createdAt: now,
        updatedAt: now,
      ),
      FocusCategoryModel(
        id: 'creative',
        name: '창작',
        description: '예술과 창의적 활동',
        icon: Icons.palette_outlined,
        color: const Color(0xFFEC4899), // 핑크
        isDefault: true,
        order: 4,
        createdAt: now,
        updatedAt: now,
      ),
      FocusCategoryModel(
        id: 'meditation',
        name: '명상',
        description: '마음 수련과 평온',
        icon: Icons.spa_outlined,
        color: const Color(0xFF059669), // 다크 그린
        isDefault: true,
        order: 5,
        createdAt: now,
        updatedAt: now,
      ),
      FocusCategoryModel(
        id: 'hobby',
        name: '취미',
        description: '개인적인 관심사와 여가',
        icon: Icons.interests_outlined,
        color: const Color(0xFF06B6D4), // 시안
        isDefault: true,
        order: 6,
        createdAt: now,
        updatedAt: now,
      ),
      FocusCategoryModel(
        id: 'other',
        name: '기타',
        description: '그 외 다른 활동',
        icon: Icons.more_horiz,
        color: const Color(0xFF6B7280), // 그레이
        isDefault: true,
        order: 7,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  // 아이콘 선택 옵션들 (Focus Forest 스타일)
  static List<IconData> getAvailableIcons() {
    return [
      Icons.work_outline,
      Icons.school_outlined,
      Icons.fitness_center_outlined,
      Icons.menu_book_outlined,
      Icons.palette_outlined,
      Icons.spa_outlined,
      Icons.interests_outlined,
      Icons.computer,
      Icons.music_note_outlined,
      Icons.camera_alt_outlined,
      Icons.restaurant_outlined,
      Icons.home_outlined,
      Icons.directions_car_outlined,
      Icons.shopping_cart_outlined,
      Icons.favorite_outline,
      Icons.star_outline,
      Icons.lightbulb_outline,
      Icons.build_outlined,
      Icons.sports_soccer_outlined,
      Icons.games_outlined,
      Icons.travel_explore_outlined,
      Icons.science_outlined,
      Icons.psychology_outlined,
      Icons.language_outlined,
      Icons.forest_outlined,
      Icons.eco_outlined,
      Icons.self_improvement_outlined,
      Icons.timer_outlined,
      Icons.more_horiz,
    ];
  }

  // Focus Forest 색상 팔레트
  static List<Color> getAvailableColors() {
    return [
      const Color(0xFF10B981), // 에메랄드 그린 (메인)
      const Color(0xFF059669), // 다크 그린
      const Color(0xFF34D399), // 라이트 그린
      const Color(0xFF3B82F6), // 블루
      const Color(0xFF1D4ED8), // 다크 블루
      const Color(0xFF60A5FA), // 라이트 블루
      const Color(0xFF8B5CF6), // 바이올렛
      const Color(0xFF7C3AED), // 다크 바이올렛
      const Color(0xFFA78BFA), // 라이트 바이올렛
      const Color(0xFFEC4899), // 핑크
      const Color(0xFFDB2777), // 다크 핑크
      const Color(0xFFF472B6), // 라이트 핑크
      const Color(0xFFF59E0B), // 오렌지
      const Color(0xFFD97706), // 다크 오렌지
      const Color(0xFFFBBF24), // 라이트 오렌지
      const Color(0xFFEF4444), // 레드
      const Color(0xFF06B6D4), // 시안
      const Color(0xFF6B7280), // 그레이
    ];
  }
} 