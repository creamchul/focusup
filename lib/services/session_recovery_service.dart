import 'dart:convert';
import 'dart:developer' as dev;
import 'package:shared_preferences/shared_preferences.dart';
import 'precision_timer_service.dart';

class SessionRecoveryService {
  static const String _sessionKey = 'focus_forest_active_session';
  static const String _sessionTimestampKey = 'focus_forest_session_timestamp';
  
  /// 현재 활성 세션 저장
  static Future<void> saveActiveSession(PrecisionTimerService timerService) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 세션 데이터 구성
      final sessionData = {
        'mode': timerService.mode.toString(),
        'status': timerService.status.toString(),
        'targetDuration': timerService.targetDuration.inMicroseconds,
        'categoryId': timerService.categoryId,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // 시간 정보는 별도로 정밀하게 저장
      if (timerService.status == PrecisionTimerStatus.running ||
          timerService.status == PrecisionTimerStatus.paused) {
        sessionData['elapsedTime'] = timerService.elapsedTime.inMicroseconds;
      }
      
      await prefs.setString(_sessionKey, jsonEncode(sessionData));
      await prefs.setInt(_sessionTimestampKey, DateTime.now().millisecondsSinceEpoch);
      
      dev.log('세션 저장 완료: ${sessionData['mode']}');
    } catch (e) {
      dev.log('세션 저장 실패: $e');
    }
  }
  
  /// 저장된 세션 복구 시도
  static Future<bool> tryRecoverSession(PrecisionTimerService timerService) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = prefs.getString(_sessionKey);
      final sessionTimestamp = prefs.getInt(_sessionTimestampKey);
      
      if (sessionJson == null || sessionTimestamp == null) {
        dev.log('복구할 세션이 없습니다');
        return false;
      }
      
      // 세션이 너무 오래되었는지 확인 (24시간 초과 시 무시)
      final sessionTime = DateTime.fromMillisecondsSinceEpoch(sessionTimestamp);
      final now = DateTime.now();
      if (now.difference(sessionTime).inHours > 24) {
        dev.log('세션이 너무 오래되어 복구하지 않습니다');
        await clearSavedSession();
        return false;
      }
      
      final sessionData = jsonDecode(sessionJson) as Map<String, dynamic>;
      
      // 세션 상태 확인
      final statusString = sessionData['status'] as String?;
      if (statusString == null || 
          statusString == 'PrecisionTimerStatus.stopped' ||
          statusString == 'PrecisionTimerStatus.completed') {
        dev.log('복구 불가능한 세션 상태: $statusString');
        await clearSavedSession();
        return false;
      }
      
      // 타이머 모드 파싱
      final modeString = sessionData['mode'] as String?;
      TimerMode mode;
      try {
        mode = TimerMode.values.firstWhere(
          (e) => e.toString() == modeString,
          orElse: () => TimerMode.timer,
        );
      } catch (e) {
        dev.log('알 수 없는 타이머 모드: $modeString');
        return false;
      }
      
      // 세션 복구 시작
      final targetDuration = Duration(microseconds: sessionData['targetDuration'] ?? 0);
      final elapsedTime = Duration(microseconds: sessionData['elapsedTime'] ?? 0);
      final categoryId = sessionData['categoryId'] as String?;
      
      // 시간 계산: 현재 시간에서 역으로 시작 시간 계산
      final startTime = now.subtract(elapsedTime);
      
      // PrecisionTimerService에 복구 데이터 전달
      final recoveryData = {
        'mode': modeString,
        'startTime': startTime.toIso8601String(),
        'targetDuration': targetDuration.inMicroseconds,
        'categoryId': categoryId,
        'pausedDuration': 0, // 기본값
        'isDeveloperMode': false,
        'speedMultiplier': 1.0,
      };
      
      final success = timerService.tryRecoverSession(recoveryData);
      
      if (success) {
        dev.log('세션 복구 성공: $mode, 경과시간: ${elapsedTime.inMinutes}분');
        return true;
      } else {
        dev.log('세션 복구 실패');
        await clearSavedSession();
        return false;
      }
      
    } catch (e) {
      dev.log('세션 복구 중 오류: $e');
      await clearSavedSession();
      return false;
    }
  }
  
  /// 저장된 세션 정보 삭제
  static Future<void> clearSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
      await prefs.remove(_sessionTimestampKey);
      dev.log('저장된 세션 정보 삭제');
    } catch (e) {
      dev.log('세션 정보 삭제 실패: $e');
    }
  }
  
  /// 저장된 세션이 있는지 확인
  static Future<bool> hasSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_sessionKey) && prefs.containsKey(_sessionTimestampKey);
    } catch (e) {
      dev.log('세션 확인 실패: $e');
      return false;
    }
  }
  
  /// 저장된 세션 정보 조회 (미리보기용)
  static Future<Map<String, dynamic>?> getSavedSessionInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = prefs.getString(_sessionKey);
      final sessionTimestamp = prefs.getInt(_sessionTimestampKey);
      
      if (sessionJson == null || sessionTimestamp == null) return null;
      
      final sessionData = jsonDecode(sessionJson) as Map<String, dynamic>;
      final sessionTime = DateTime.fromMillisecondsSinceEpoch(sessionTimestamp);
      
      return {
        ...sessionData,
        'savedAt': sessionTime.toIso8601String(),
        'isExpired': DateTime.now().difference(sessionTime).inHours > 24,
      };
    } catch (e) {
      dev.log('세션 정보 조회 실패: $e');
      return null;
    }
  }
  
  /// 백그라운드에서 주기적으로 세션 저장
  static Future<void> startAutoSave(PrecisionTimerService timerService) async {
    // 타이머가 실행 중일 때만 주기적으로 저장
    if (timerService.status == PrecisionTimerStatus.running) {
      await saveActiveSession(timerService);
    }
  }
} 