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
  pomodoro,
  freeTimer,
  stopwatch,
}

class PrecisionTimerService extends ChangeNotifier {
  static final PrecisionTimerService _instance = PrecisionTimerService._internal();
  factory PrecisionTimerService() => _instance;
  PrecisionTimerService._internal();

  // 타이머 상태
  PrecisionTimerStatus _status = PrecisionTimerStatus.stopped;
  TimerMode _mode = TimerMode.pomodoro;
  
  // 시간 관련
  DateTime? _startTime;
  DateTime? _pausedTime;
  Duration _pausedDuration = Duration.zero;
  Duration _targetDuration = const Duration(minutes: 25);
  
  // 세션 정보
  String? _categoryId;
  Map<String, dynamic>? _sessionData;
  
  // 타이머
  Timer? _timer;
  
  // Getters
  PrecisionTimerStatus get status => _status;
  TimerMode get mode => _mode;
  Duration get targetDuration => _targetDuration;
  String? get categoryId => _categoryId;
  
  /// 현재 경과 시간 계산 (정밀)
  Duration get elapsedTime {
    if (_status == PrecisionTimerStatus.stopped || _startTime == null) {
      return Duration.zero;
    }
    
    final now = DateTime.now();
    Duration elapsed;
    
    if (_status == PrecisionTimerStatus.paused && _pausedTime != null) {
      elapsed = _pausedTime!.difference(_startTime!) + _pausedDuration;
    } else {
      elapsed = now.difference(_startTime!) + _pausedDuration;
    }
    
    return elapsed;
  }
  
  /// 남은 시간 계산
  Duration get remainingTime {
    if (_mode == TimerMode.stopwatch) {
      return Duration.zero; // 스톱워치는 남은 시간이 없음
    }
    
    final remaining = _targetDuration - elapsedTime;
    return remaining.isNegative ? Duration.zero : remaining;
  }
  
  /// 진행률 (0.0 ~ 1.0)
  double get progress {
    if (_mode == TimerMode.stopwatch || _targetDuration.inMicroseconds == 0) {
      return 0.0;
    }
    
    final elapsed = elapsedTime.inMicroseconds;
    final target = _targetDuration.inMicroseconds;
    final progress = elapsed / target;
    
    return progress.clamp(0.0, 1.0);
  }
  
  /// 포모도로 타이머 시작
  void startPomodoro({
    int minutes = 25,
    String? categoryId,
  }) {
    _mode = TimerMode.pomodoro;
    _targetDuration = Duration(minutes: minutes);
    _categoryId = categoryId;
    _startTimer();
  }
  
  /// 자유 타이머 시작
  void startFreeTimer({
    required int minutes,
    String? categoryId,
  }) {
    _mode = TimerMode.freeTimer;
    _targetDuration = Duration(minutes: minutes);
    _categoryId = categoryId;
    _startTimer();
  }
  
  /// 스톱워치 시작
  void startStopwatch({
    String? categoryId,
  }) {
    _mode = TimerMode.stopwatch;
    _targetDuration = Duration.zero;
    _categoryId = categoryId;
    _startTimer();
  }
  
  /// 타이머 시작
  void _startTimer() {
    if (_status == PrecisionTimerStatus.paused) {
      // 일시정지에서 재개
      _pausedDuration += DateTime.now().difference(_pausedTime ?? DateTime.now());
      _pausedTime = null;
    } else {
      // 새로 시작
      _startTime = DateTime.now();
      _pausedDuration = Duration.zero;
      _saveSessionData();
    }
    
    _status = PrecisionTimerStatus.running;
    _startPeriodicUpdates();
    
    dev.log('타이머 시작: $_mode, 목표: $_targetDuration');
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
    _timer?.cancel();
    _clearSessionData();
    
    dev.log('타이머 정지');
    notifyListeners();
  }
  
  /// 주기적 업데이트 시작
  void _startPeriodicUpdates() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      // 완료 체크 (스톱워치 제외)
      if (_mode != TimerMode.stopwatch && remainingTime.inMicroseconds <= 0) {
        _status = PrecisionTimerStatus.completed;
        timer.cancel();
        dev.log('타이머 완료');
        notifyListeners();
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
        orElse: () => TimerMode.pomodoro,
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
