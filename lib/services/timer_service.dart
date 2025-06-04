import 'dart:async';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';
import 'notification_service.dart';

/// 타이머 상태 enum
enum TimerStatus {
  initial,
  running,
  paused,
  completed,
  stopped,
}

/// 타이머 모드 enum  
enum TimerMode {
  pomodoro,
  freeTimer,
  stopwatch,
}

/// 타이머 서비스
class TimerService extends ChangeNotifier {
  static final TimerService _instance = TimerService._internal();
  factory TimerService() => _instance;
  TimerService._internal();

  Timer? _timer;
  TimerStatus _status = TimerStatus.initial;
  TimerMode _mode = TimerMode.pomodoro;
  int _remainingSeconds = 0;
  int _initialSeconds = 0;
  int _elapsedSeconds = 0;
  DateTime? _startTime;
  DateTime? _pauseTime;
  
  // 카테고리 정보 추가
  String? _categoryId;

  // Getters
  TimerStatus get status => _status;
  TimerMode get mode => _mode;
  int get remainingSeconds => _remainingSeconds;
  int get initialSeconds => _initialSeconds;
  int get elapsedSeconds => _elapsedSeconds;
  double get progress => _initialSeconds > 0 ? (_initialSeconds - _remainingSeconds) / _initialSeconds : 0.0;
  String? get categoryId => _categoryId;
  
  String get formattedTime {
    if (_mode == TimerMode.stopwatch) {
      return _formatTime(_elapsedSeconds);
    }
    return _formatTime(_remainingSeconds);
  }

  /// 포모도로 타이머 시작 (기본 25분)
  void startPomodoro({int minutes = 25, String? categoryId}) {
    _mode = TimerMode.pomodoro;
    _initialSeconds = minutes * 60;
    _remainingSeconds = _initialSeconds;
    _elapsedSeconds = 0;
    _categoryId = categoryId;
    _startTimer();
  }

  /// 자유 타이머 시작
  void startFreeTimer(int minutes, {String? categoryId}) {
    _mode = TimerMode.freeTimer;
    _initialSeconds = minutes * 60;
    _remainingSeconds = _initialSeconds;
    _elapsedSeconds = 0;
    _categoryId = categoryId;
    _startTimer();
  }

  /// 스톱워치 시작
  void startStopwatch({String? categoryId}) {
    _mode = TimerMode.stopwatch;
    _initialSeconds = 0;
    _remainingSeconds = 0;
    _elapsedSeconds = 0;
    _categoryId = categoryId;
    _startTimer();
  }

  /// 타이머 시작
  void _startTimer() {
    _status = TimerStatus.running;
    _startTime = DateTime.now();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_mode == TimerMode.stopwatch) {
        _elapsedSeconds++;
      } else {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          _elapsedSeconds++;
        } else {
          _completeTimer();
          return;
        }
      }
      notifyListeners();
    });
    
    notifyListeners();
  }

  /// 타이머 일시정지
  void pauseTimer() {
    if (_status == TimerStatus.running) {
      _timer?.cancel();
      _status = TimerStatus.paused;
      _pauseTime = DateTime.now();
      notifyListeners();
    }
  }

  /// 타이머 재개
  void resumeTimer() {
    if (_status == TimerStatus.paused) {
      _startTimer();
    }
  }

  /// 타이머 정지
  void stopTimer() {
    _timer?.cancel();
    _status = TimerStatus.stopped;
    notifyListeners();
  }

  /// 타이머 완료
  void _completeTimer() {
    _timer?.cancel();
    _status = TimerStatus.completed;
    
    // 완료 알림 표시
    _showCompletionNotification();
    
    // 세션 데이터 저장
    _saveSession();
    
    notifyListeners();
  }

  /// 세션 데이터 저장
  Future<void> _saveSession() async {
    try {
      final focusMinutes = _mode == TimerMode.stopwatch 
          ? (_elapsedSeconds / 60).round()
          : _initialSeconds ~/ 60;
      
      // StorageService의 새로운 메서드 사용
      await StorageService.saveFocusSession(
        minutes: focusMinutes,
        categoryId: _categoryId,
      );
      
      if (kDebugMode) {
        print('세션 저장 완료: $focusMinutes분 (카테고리: $_categoryId)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('세션 저장 실패: $e');
      }
    }
  }

  /// 완료 알림 표시
  Future<void> _showCompletionNotification() async {
    final focusMinutes = _mode == TimerMode.stopwatch 
        ? (_elapsedSeconds / 60).round()
        : _initialSeconds ~/ 60;
    final totalTrees = StorageService.getTotalTrees();
    
    await NotificationService.showFocusCompleteNotification(
      focusMinutes: focusMinutes,
      totalTrees: totalTrees,
    );
  }

  /// 타이머 리셋
  void resetTimer() {
    _timer?.cancel();
    _status = TimerStatus.initial;
    _remainingSeconds = _initialSeconds;
    _elapsedSeconds = 0;
    _startTime = null;
    _pauseTime = null;
    _categoryId = null;
    notifyListeners();
  }

  /// 시간 포맷팅 (MM:SS)
  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// 서비스 정리
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
} 