import 'package:flutter/material.dart';

/// Focus Forest 앱의 토스 스타일 색상 시스템
/// 에메랄드 그린을 메인 컬러로 하는 깔끔하고 모던한 디자인
class AppColors {
  AppColors._();

  // ============================================================================
  // 메인 브랜드 컬러 (에메랄드 그린)
  // ============================================================================
  
  /// 메인 브랜드 컬러 - 에메랄드 그린
  static const Color primary = Color(0xFF10B981);
  static const Color primaryLight = Color(0xFF34D399);
  static const Color primaryDark = Color(0xFF059669);
  static const Color primarySurface = Color(0xFFECFDF5);
  
  // ============================================================================
  // 토스 스타일 그레이 스케일
  // ============================================================================
  
  /// 텍스트 컬러
  static const Color textPrimary = Color(0xFF191F28);
  static const Color textSecondary = Color(0xFF8B95A1);
  static const Color textTertiary = Color(0xFFB0B8C1);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  
  /// 배경 컬러
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundSecondary = Color(0xFFF9FAFB);
  static const Color backgroundTertiary = Color(0xFFF1F3F4);
  
  /// 카드 및 서피스
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E8EB);
  static const Color borderLight = Color(0xFFF1F3F4);
  
  // ============================================================================
  // 기능별 컬러
  // ============================================================================
  
  /// 집중 관련 컬러
  static const Color focusActive = Color(0xFF10B981);
  static const Color focusPaused = Color(0xFFF59E0B);
  static const Color focusCompleted = Color(0xFF059669);
  static const Color focusBackground = Color(0xFFECFDF5);
  
  /// 나무/자연 관련 컬러
  static const Color treeGreen = Color(0xFF059669);
  static const Color treeLight = Color(0xFF4ADE80);
  static const Color treeDark = Color(0xFF15803D);
  static const Color forestBackground = Color(0xFFF0FDF4);
  
  /// 성공/완료 컬러
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color successDark = Color(0xFF059669);
  
  /// 경고/일시정지 컬러
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFFD97706);
  
  /// 에러/실패 컬러
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFFDC2626);
  
  /// 정보 컬러
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoDark = Color(0xFF1D4ED8);
  
  // ============================================================================
  // 다크 모드 컬러
  // ============================================================================
  
  /// 다크 모드 텍스트
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0B8C1);
  static const Color darkTextTertiary = Color(0xFF8B95A1);
  
  /// 다크 모드 배경
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkBackgroundSecondary = Color(0xFF1E293B);
  static const Color darkBackgroundTertiary = Color(0xFF334155);
  
  /// 다크 모드 서피스
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceElevated = Color(0xFF334155);
  static const Color darkBorder = Color(0xFF475569);
  
  // ============================================================================
  // 그라데이션
  // ============================================================================
  
  /// 메인 그라데이션
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF10B981),
      Color(0xFF059669),
    ],
  );
  
  /// 성공 그라데이션
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF22C55E),
      Color(0xFF15803D),
    ],
  );
  
  /// 배경 그라데이션
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF9FAFB),
    ],
  );
  
  // ============================================================================
  // 유틸리티 메서드
  // ============================================================================
  
  /// 테마에 따른 텍스트 컬러 반환
  static Color getTextPrimary(bool isDark) {
    return isDark ? darkTextPrimary : textPrimary;
  }
  
  /// 테마에 따른 보조 텍스트 컬러 반환
  static Color getTextSecondary(bool isDark) {
    return isDark ? darkTextSecondary : textSecondary;
  }
  
  /// 테마에 따른 배경 컬러 반환
  static Color getBackground(bool isDark) {
    return isDark ? darkBackground : background;
  }
  
  /// 테마에 따른 서피스 컬러 반환
  static Color getSurface(bool isDark) {
    return isDark ? darkSurface : surface;
  }
  
  /// 테마에 따른 보더 컬러 반환
  static Color getBorder(bool isDark) {
    return isDark ? darkBorder : border;
  }

  // 추가 컬러
  static const Color coral = Color(0xFFEF4444);
} 