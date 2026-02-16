import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'rail_alert_alarm';
  static const String _channelName = 'Rail Alert Alarm';
  static const String _channelDesc =
      'High priority alarm for station proximity';

  static const int alarmNotificationId = 1;
  static const int trackingNotificationId = 2;

  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
  }

  void _onNotificationResponse(NotificationResponse response) {
    // Handled by the app's navigation logic via callback
  }

  Future<void> showAlarmNotification(String stationName) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
      playSound: false, // We handle sound via audioplayers
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      alarmNotificationId,
      '🚉 Approaching Station!',
      'You are near $stationName. Tap to dismiss alarm.',
      details,
    );
  }

  Future<void> showTrackingNotification(String stationName) async {
    const androidDetails = AndroidNotificationDetails(
      'rail_alert_tracking',
      'Tracking Status',
      channelDescription: 'Shows active tracking status',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      playSound: false,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      trackingNotificationId,
      'Rail Alert Active',
      'Tracking proximity to $stationName',
      details,
    );
  }

  Future<void> cancelAlarmNotification() async {
    await _plugin.cancel(alarmNotificationId);
  }

  Future<void> cancelTrackingNotification() async {
    await _plugin.cancel(trackingNotificationId);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
