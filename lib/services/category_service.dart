import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/focus_category_model.dart';

class CategoryService {
  static const String _categoriesKey = 'focus_categories';
  static const String _defaultsInitializedKey = 'defaults_initialized';

  /// 모든 카테고리 가져오기
  static Future<List<FocusCategoryModel>> getCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 기본 카테고리가 초기화되지 않았다면 초기화
      final defaultsInitialized = prefs.getBool(_defaultsInitializedKey) ?? false;
      if (!defaultsInitialized) {
        await _initializeDefaultCategories();
      }
      
      final categoriesJson = prefs.getStringList(_categoriesKey) ?? [];
      
      if (categoriesJson.isEmpty) {
        // 데이터가 없으면 기본 카테고리 반환
        return FocusCategoryModel.getDefaultCategories();
      }
      
      final categories = <FocusCategoryModel>[];
      
      // 각 카테고리를 안전하게 파싱
      for (final json in categoriesJson) {
        try {
          final category = FocusCategoryModel.fromMap(jsonDecode(json));
          if (category.isActive) {
            categories.add(category);
          }
        } catch (e) {
          print('카테고리 파싱 실패, 건너뜀: $e');
          continue;
        }
      }
      
      // 파싱된 카테고리가 없으면 기본 카테고리 반환
      if (categories.isEmpty) {
        print('유효한 카테고리가 없어 기본 카테고리를 반환합니다');
        return FocusCategoryModel.getDefaultCategories();
      }
      
      // order 순으로 정렬
      categories.sort((a, b) => a.order.compareTo(b.order));
      
      return categories;
    } catch (e) {
      print('카테고리 로딩 실패, 기본 카테고리 반환: $e');
      return FocusCategoryModel.getDefaultCategories();
    }
  }

  /// 기본 카테고리 초기화
  static Future<void> _initializeDefaultCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final defaultCategories = FocusCategoryModel.getDefaultCategories();
      
      final categoriesJson = <String>[];
      
      // 각 카테고리를 안전하게 직렬화
      for (final category in defaultCategories) {
        try {
          categoriesJson.add(jsonEncode(category.toMap()));
        } catch (e) {
          print('카테고리 직렬화 실패, 건너뜀: ${category.name} - $e');
          continue;
        }
      }
      
      await prefs.setStringList(_categoriesKey, categoriesJson);
      await prefs.setBool(_defaultsInitializedKey, true);
      
      print('기본 카테고리 초기화 완료: ${categoriesJson.length}개');
    } catch (e) {
      print('기본 카테고리 초기화 실패: $e');
      // 초기화 실패해도 계속 진행
    }
  }

  /// 카테고리 ID로 조회
  static Future<FocusCategoryModel?> getCategoryById(String categoryId) async {
    try {
      final categories = await getCategories();
      return categories.firstWhere(
        (category) => category.id == categoryId,
        orElse: () => throw StateError('Category not found'),
      );
    } catch (e) {
      print('카테고리 조회 실패 (ID: $categoryId): $e');
      return null;
    }
  }

  /// 새 카테고리 추가
  static Future<bool> addCategory(FocusCategoryModel category) async {
    try {
      final categories = await getCategories();
      
      // 이름 중복 체크
      final exists = categories.any((c) => 
          c.name.toLowerCase() == category.name.toLowerCase());
      if (exists) {
        throw Exception('같은 이름의 카테고리가 이미 존재합니다');
      }
      
      // 새 order 값 설정
      final maxOrder = categories.isEmpty ? 0 : 
          categories.map((c) => c.order).reduce((a, b) => a > b ? a : b);
      
      final newCategory = category.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        order: maxOrder + 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      categories.add(newCategory);
      await _saveCategories(categories);
      
      return true;
    } catch (e) {
      print('카테고리 추가 실패: $e');
      return false;
    }
  }

  /// 카테고리 수정
  static Future<bool> updateCategory(FocusCategoryModel category) async {
    try {
      final categories = await getCategories();
      final index = categories.indexWhere((c) => c.id == category.id);
      
      if (index == -1) {
        throw Exception('카테고리를 찾을 수 없습니다');
      }
      
      categories[index] = category.copyWith(updatedAt: DateTime.now());
      await _saveCategories(categories);
      
      return true;
    } catch (e) {
      print('카테고리 수정 실패: $e');
      return false;
    }
  }

  /// 카테고리 삭제 (비활성화)
  static Future<bool> deleteCategory(String categoryId) async {
    try {
      final categories = await getCategories();
      final index = categories.indexWhere((c) => c.id == categoryId);
      
      if (index == -1) {
        throw Exception('카테고리를 찾을 수 없습니다');
      }
      
      // 기본 카테고리는 삭제 불가
      if (categories[index].isDefault) {
        throw Exception('기본 카테고리는 삭제할 수 없습니다');
      }
      
      categories[index] = categories[index].copyWith(
        isActive: false,
        updatedAt: DateTime.now(),
      );
      
      await _saveCategories(categories);
      return true;
    } catch (e) {
      print('카테고리 삭제 실패: $e');
      return false;
    }
  }

  /// 즐겨찾기 토글
  static Future<bool> toggleFavorite(String categoryId) async {
    try {
      final categories = await getCategories();
      final index = categories.indexWhere((c) => c.id == categoryId);
      
      if (index == -1) {
        throw Exception('카테고리를 찾을 수 없습니다');
      }
      
      categories[index] = categories[index].copyWith(
        isFavorite: !categories[index].isFavorite,
        updatedAt: DateTime.now(),
      );
      
      await _saveCategories(categories);
      return true;
    } catch (e) {
      print('즐겨찾기 토글 실패: $e');
      return false;
    }
  }

  /// 즐겨찾기 카테고리만 조회
  static Future<List<FocusCategoryModel>> getFavoriteCategories() async {
    final categories = await getCategories();
    return categories.where((category) => category.isFavorite).toList();
  }

  /// 카테고리 순서 변경
  static Future<bool> reorderCategories(List<FocusCategoryModel> reorderedCategories) async {
    try {
      // 새로운 order 값 할당
      for (int i = 0; i < reorderedCategories.length; i++) {
        reorderedCategories[i] = reorderedCategories[i].copyWith(
          order: i,
          updatedAt: DateTime.now(),
        );
      }
      
      await _saveCategories(reorderedCategories);
      return true;
    } catch (e) {
      print('카테고리 순서 변경 실패: $e');
      return false;
    }
  }

  /// 카테고리 데이터 저장
  static Future<void> _saveCategories(List<FocusCategoryModel> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categoriesJson = categories
          .map((category) => jsonEncode(category.toMap()))
          .toList();
      
      await prefs.setStringList(_categoriesKey, categoriesJson);
    } catch (e) {
      print('카테고리 저장 실패: $e');
      rethrow;
    }
  }

  /// 카테고리 사용 통계 (임시 데이터)
  static Future<Map<String, int>> getCategoryUsageStats() async {
    // 실제로는 세션 데이터에서 계산해야 하지만, 임시로 더미 데이터 반환
    return {
      'work': 15,
      'study': 12,
      'exercise': 8,
      'reading': 6,
      'creative': 4,
      'meditation': 3,
      'hobby': 2,
      'other': 1,
    };
  }

  /// 모든 데이터 초기화 (개발용)
  static Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_categoriesKey);
      await prefs.remove(_defaultsInitializedKey);
      print('카테고리 데이터 초기화 완료');
    } catch (e) {
      print('카테고리 데이터 초기화 실패: $e');
    }
  }

  /// 문제가 있는 카테고리 데이터 복구
  static Future<void> resetToDefault() async {
    try {
      await clearAllData();
      await _initializeDefaultCategories();
      print('카테고리 데이터 기본값으로 복구 완료');
    } catch (e) {
      print('카테고리 데이터 복구 실패: $e');
    }
  }
} 