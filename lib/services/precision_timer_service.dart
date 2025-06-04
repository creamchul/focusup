import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

enum PrecisionTimerStatus {
  stopped,
  running,
  paused,
  completed,
}

enum TimerMode {
  timer,
  stopwatch,
}

enum TimerPhase {
  focus,
  rest,
}

class PrecisionTimerService extends ChangeNotifier {
  static final PrecisionTimerService _instance = PrecisionTimerService._internal();
  factory PrecisionTimerService() => _instance;
  PrecisionTimerService._internal();

  // 타이머 상태
  PrecisionTimerStatus _status = PrecisionTimerStatus.stopped;
  TimerMode _mode = TimerMode.timer;
  TimerPhase _phase = TimerPhase.focus;
  
  // 시간 관련
  DateTime? _startTime;
  DateTime? _pausedTime;
  Duration _pausedDuration = Duration.zero;
  Duration _targetDuration = const Duration(minutes: 25);
  
  // 브레이크 관련
  Duration? _breakDuration;
  bool _hasBreak = false;
  int _completedCycles = 0;
  
  // 세션 정보
  String? _categoryId;
  Map<String, dynamic>? _sessionData;
  
  // 타이머
  Timer? _timer;
  
  // Getters
  PrecisionTimerStatus get status => _status;
  TimerMode get mode => _mode;
  TimerPhase get phase => _phase;
  Duration get targetDuration => _targetDuration;
  String? get categoryId => _categoryId;
  Duration? get breakDuration => _breakDuration;
  bool get hasBreak => _hasBreak;
  int get completedCycles => _completedCycles;
  
  /// 현재 경과 시간 계산 (정밀)
  Duration get elapsedTime {
    if (_status == PrecisionTimerStatus.stopped || _startTime == null) {
      return Duration.zero;
    }
    
    if (_status == PrecisionTimerStatus.paused && _pausedTime != null) {
      return _pausedTime!.difference(_startTime!) + _pausedDuration;
    }
    
    return DateTime.now().difference(_startTime!) + _pausedDuration;
  }
  
  /// 남은 시간 계산
  Duration get remainingTime {
    if (_mode == TimerMode.stopwatch) {
      return Duration.zero; // 스톱워치는 남은 시간이 없음
    }
    
    final currentTarget = _getCurrentTargetDuration();
    final remaining = currentTarget - elapsedTime;
    return remaining.isNegative ? Duration.zero : remaining;
  }
  
  /// 현재 페이즈의 목표 시간 반환
  Duration _getCurrentTargetDuration() {
    if (_phase == TimerPhase.focus) {
      return _targetDuration;
    } else {
      return _breakDuration ?? Duration.zero;
    }
  }
  
  /// 진행률 (0.0 ~ 1.0)
  double get progress {
    if (_mode == TimerMode.stopwatch) {
      return 0.0;
    }
    
    final currentTarget = _getCurrentTargetDuration();
    if (currentTarget.inMicroseconds == 0) {
      return 0.0;
    }
    
    final elapsed = elapsedTime.inMicroseconds;
    final target = currentTarget.inMicroseconds;
    final progress = elapsed / target;
    
    return progress.clamp(0.0, 1.0);
  }
  
  /// 타이머 시작 전에 목표 시간 설정
  void setTargetDuration({
    required int minutes,
    int? breakMinutes,
    TimerMode? mode,
    String? categoryId,
  }) {
    if (_status != PrecisionTimerStatus.stopped) return;
    
    _mode = mode ?? TimerMode.timer;
    _targetDuration = Duration(minutes: minutes);
    _breakDuration = breakMinutes != null ? Duration(minutes: breakMinutes) : null;
    _hasBreak = breakMinutes != null && breakMinutes > 0;
    _categoryId = categoryId;
    _phase = TimerPhase.focus;
    _completedCycles = 0;
    
    dev.log('목표 시간 설정: $minutes분, 브레이크: ${breakMinutes ?? "없음"}분');
    notifyListeners();
  }
  
  /// 자유 타이머 시작
  void startFreeTimer({
    required int minutes,
    int? breakMinutes,
    String? categoryId,
  }) {
    _mode = TimerMode.timer;
    _targetDuration = Duration(minutes: minutes);
    _breakDuration = breakMinutes != null ? Duration(minutes: breakMinutes) : null;
    _hasBreak = breakMinutes != null && breakMinutes > 0;
    _categoryId = categoryId;
    _phase = TimerPhase.focus;
    _completedCycles = 0;
    _startTimer();
  }
  
  /// 스톱워치 시작
  void startStopwatch({
    String? categoryId,
  }) {
    _mode = TimerMode.stopwatch;
    _targetDuration = Duration.zero;
    _breakDuration = null;
    _hasBreak = false;
    _categoryId = categoryId;
    _phase = TimerPhase.focus;
    _completedCycles = 0;
    _startTimer();
  }
  
  /// 타이머 시작
  void _startTimer() {
    if (_status == PrecisionTimerStatus.paused) {
      // 일시정지에서 재개할 때 시작 시간 조정
      final pauseDuration = DateTime.now().difference(_pausedTime!);
      _startTime = _startTime!.add(pauseDuration);
      _pausedTime = null;
    } else {
      // 새로 시작
      _startTime = DateTime.now();
      _pausedDuration = Duration.zero;
      _saveSessionData();
    }
    
    _status = PrecisionTimerStatus.running;
    _startPeriodicUpdates();
    
    dev.log('타이머 시작: $_mode, 페이즈: $_phase, 목표: ${_getCurrentTargetDuration()}');
    notifyListeners();
  }
  
  /// 타이머 일시정지
  void pauseTimer() {
    if (_status != PrecisionTimerStatus.running) return;
    
    _status = PrecisionTimerStatus.paused;
    _pausedTime = DateTime.now();
    _timer?.cancel();
    
    dev.log('타이머 일시정지');
    notifyListeners();
  }
  
  /// 타이머 정지
  void stopTimer() {
    _status = PrecisionTimerStatus.stopped;
    _startTime = null;
    _pausedTime = null;
    _pausedDuration = Duration.zero;
    _phase = TimerPhase.focus;
    _completedCycles = 0;
    _timer?.cancel();
    _clearSessionData();
    
    dev.log('타이머 정지');
    notifyListeners();
  }
  
  /// 다음 페이즈로 전환 (포커스 -> 브레이크 -> 포커스)
  void _switchToNextPhase() {
    if (_phase == TimerPhase.focus) {
      _completedCycles++;
      if (_hasBreak && _breakDuration != null) {
        // 브레이크 시작
        _phase = TimerPhase.rest;
        dev.log('브레이크 시작: ${_breakDuration!.inMinutes}분');
      } else {
        // 브레이크가 없으면 완료
        _status = PrecisionTimerStatus.completed;
        _timer?.cancel();
        dev.log('세션 완료 (브레이크 없음)');
        notifyListeners();
        return;
      }
    } else {
      // 브레이크 완료, 포커스로 돌아가기
      _phase = TimerPhase.focus;
      dev.log('브레이크 완료, 포커스로 전환');
    }
    
    // 타이머 재시작
    _startTime = DateTime.now();
    _pausedDuration = Duration.zero;
    _pausedTime = null;
    _status = PrecisionTimerStatus.running;
    
    notifyListeners();
  }
  
  /// 브레이크 건너뛰기
  void skipBreak() {
    if (_phase == TimerPhase.rest && _status == PrecisionTimerStatus.running) {
      _switchToNextPhase();
    }
  }
  
  /// 테스트용 5분 빨리가기
  void skipFiveMinutes() {
    if (_status == PrecisionTimerStatus.running) {
      _pausedDuration += const Duration(minutes: 5);
      dev.log('5분 빨리가기 적용');
      notifyListeners();
    }
  }
  
  /// 주기적 업데이트 시작
  void _startPeriodicUpdates() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      // 완료 체크 (스톱워치 제외)
      if (_mode != TimerMode.stopwatch && remainingTime.inMicroseconds <= 0) {
        if (_phase == TimerPhase.focus && _hasBreak) {
          // 포커스 완료, 브레이크로 전환
          _switchToNextPhase();
        } else if (_phase == TimerPhase.rest) {
          // 브레이크 완료, 포커스로 전환
          _switchToNextPhase();
        } else {
          // 완전히 완료
          _status = PrecisionTimerStatus.completed;
          timer.cancel();
          dev.log('타이머 완료');
          notifyListeners();
        }
        return;
      }
      
      notifyListeners();
    });
  }
  
  /// 세션 데이터 저장 (복구용)
  void _saveSessionData() {
    _sessionData = {
      'mode': _mode.toString(),
      'startTime': _startTime?.toIso8601String(),
      'targetDuration': _targetDuration.inMicroseconds,
      'categoryId': _categoryId,
      'pausedDuration': _pausedDuration.inMicroseconds,
    };
    
    // SharedPreferences 등에 저장 (추후 구현)
    dev.log('세션 데이터 저장');
  }
  
  /// 세션 데이터 복구
  bool tryRecoverSession(Map<String, dynamic>? data) {
    if (data == null) return false;
    
    try {
      final modeString = data['mode'] as String?;
      final startTimeString = data['startTime'] as String?;
      
      if (modeString == null || startTimeString == null) return false;
      
      _mode = TimerMode.values.firstWhere(
        (e) => e.toString() == modeString,
        orElse: () => TimerMode.timer,
      );
      
      _startTime = DateTime.parse(startTimeString);
      _targetDuration = Duration(microseconds: data['targetDuration'] ?? 0);
      _categoryId = data['categoryId'];
      _pausedDuration = Duration(microseconds: data['pausedDuration'] ?? 0);
      
      // 현재 시간으로 상태 판단
      if (_mode != TimerMode.stopwatch && remainingTime.inMicroseconds <= 0) {
        _status = PrecisionTimerStatus.completed;
      } else {
        _status = PrecisionTimerStatus.running;
        _startPeriodicUpdates();
      }
      
      dev.log('세션 복구 성공');
      notifyListeners();
      return true;
    } catch (e) {
      dev.log('세션 복구 실패: $e');
      return false;
    }
  }
  
  /// 세션 데이터 삭제
  void _clearSessionData() {
    _sessionData = null;
    // SharedPreferences에서도 삭제 (추후 구현)
  }
  
  /// 5분 스킵 (시간 빨리감기)
  void fastForward5Minutes() {
    if (_startTime == null || _status != PrecisionTimerStatus.running) return;
    
    _startTime = _startTime!.subtract(const Duration(minutes: 5));
    dev.log('5분 스킵');
    notifyListeners();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
