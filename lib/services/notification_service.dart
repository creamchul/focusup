import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';

/// 로컬 알림을 위한 서비스
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  
  /// 서비스 초기화
  static Future<void> init() async {
    // 웹에서는 알림 초기화 건너뛰기
    if (kIsWeb) {
      print('웹 환경: 알림 기능이 제한됩니다');
      return;
    }
    
    if (_isInitialized) return;
    
    // Android 초기화 설정
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS 초기화 설정
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
      macOS: initializationSettingsIOS,
    );
    
    await _notifications.initialize(initializationSettings);
    await _requestPermissions();
    
    _isInitialized = true;
  }
  
  /// 알림 권한 요청
  static Future<void> _requestPermissions() async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      await Permission.notification.request();
    }
  }
  
  /// 집중 완료 알림
  static Future<void> showFocusCompleteNotification({
    required int focusMinutes,
    required int totalTrees,
  }) async {
    if (!await _isPermissionGranted()) return;

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'focus_complete',
        '집중 완료',
        channelDescription: '집중 세션 완료 알림',
        importance: Importance.high,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification_sound.aiff',
      ),
    );

    await _notifications.show(
      1001,
      '🎉 집중 완료!',
      '$focusMinutes분 집중을 완료했습니다! 🌳 총 ${totalTrees}그루의 나무가 자랐어요.',
      notificationDetails,
    );
  }
  
  /// 휴식 시간 알림
  static Future<void> showBreakNotification({
    required int breakMinutes,
  }) async {
    if (!await _isPermissionGranted()) return;

    final notificationDetails = NotificationDetails(
      android: const AndroidNotificationDetails(
        'break_reminder',
        '휴식 알림',
        channelDescription: '휴식 시간 알림',
        importance: Importance.high,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound('break_sound'),
        enableVibration: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'break_sound.aiff',
      ),
    );

    await _notifications.show(
      1002,
      '☕ 휴식 시간!',
      '${breakMinutes}분간 휴식을 취하세요. 잠시 휴식 후 다시 집중해보세요!',
      notificationDetails,
    );
  }
  
  /// 휴식 완료 알림
  static Future<void> showBreakCompleteNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'break_complete',
      'Break Complete',
      channelDescription: '휴식 완료 알림',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: false,
      icon: '@mipmap/ic_launcher',
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      sound: 'default',
    );
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );
    
    await _notifications.show(
      3,
      '💪 휴식 완료!',
      '다시 집중할 준비가 되었습니다!',
      details,
    );
  }
  
  /// 일일 목표 달성 알림
  static Future<void> showDailyGoalNotification({
    required int totalMinutes,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_goal',
      'Daily Goal',
      channelDescription: '일일 목표 달성 알림',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: false,
      icon: '@mipmap/ic_launcher',
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      sound: 'default',
      badgeNumber: 1,
    );
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );
    
    await _notifications.show(
      4,
      '🏆 일일 목표 달성!',
      '오늘 총 ${totalMinutes}분 집중했습니다! 축하해요!',
      details,
    );
  }
  
  /// 집중 리마인더 알림 (간단한 형태)
  static Future<void> showFocusReminderNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'focus_reminder',
      'Focus Reminder',
      channelDescription: '집중 리마인더 알림',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: false,
      icon: '@mipmap/ic_launcher',
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      sound: 'default',
    );
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );
    
    await _notifications.show(
      5,
      '🌱 집중할 시간입니다',
      '오늘도 작은 습관으로 큰 변화를 만들어보세요!',
      details,
    );
  }
  
  /// 모든 알림 취소
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
  
  /// 특정 알림 취소
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
  
  /// 알림 권한 확인
  static Future<bool> hasPermission() async {
    // 웹에서는 권한 체크 건너뛰기
    if (kIsWeb) {
      return false;
    }

    try {
      final status = await Permission.notification.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      print('알림 권한 확인 오류: $e');
      return false;
    }
  }

  static Future<bool> _isPermissionGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  static Future<bool> requestPermission() async {
    // 웹에서는 권한 요청 건너뛰기
    if (kIsWeb) {
      return false;
    }

    try {
      final status = await Permission.notification.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      print('알림 권한 요청 오류: $e');
      return false;
    }
  }
} 