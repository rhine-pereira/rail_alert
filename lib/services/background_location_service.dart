import 'dart:async';
import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundLocationService {
  static const String _trackingKey = 'is_tracking';
  static const String _stationLatKey = 'station_lat';
  static const String _stationLngKey = 'station_lng';
  static const String _stationNameKey = 'station_name';
  static const String _radiusKey = 'radius_meters';

  Future<void> initialize() async {
    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'rail_alert_foreground',
      'Rail Alert Tracking Service',
      description: 'Keeps location tracking active in background',
      importance: Importance.low,
      enableVibration: false,
      playSound: false,
      showBadge: false,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'rail_alert_foreground',
        initialNotificationTitle: 'Rail Alert',
        initialNotificationContent: 'Monitoring location...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  Future<void> startBackgroundTracking({
    required double stationLat,
    required double stationLng,
    required String stationName,
    required double radiusMeters,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_stationLatKey, stationLat);
    await prefs.setDouble(_stationLngKey, stationLng);
    await prefs.setString(_stationNameKey, stationName);
    await prefs.setDouble(_radiusKey, radiusMeters);
    await prefs.setBool(_trackingKey, true);

    final service = FlutterBackgroundService();
    await service.startService();
  }

  Future<void> stopBackgroundTracking() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_trackingKey, false);

    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Initialize plugins for background isolate
    final prefs = await SharedPreferences.getInstance();
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    final audioPlayer = AudioPlayer();

    // Set up notification channels
    const AndroidNotificationChannel alarmChannel = AndroidNotificationChannel(
      'rail_alert_alarm_bg',
      'Rail Alert Alarm',
      description: 'High priority alarm notifications',
      importance: Importance.max,
      playSound: false,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(alarmChannel);

    bool hasTriggered = false;
    Position? lastPosition;
    DateTime? lastPositionTime;
    double averageSpeed = 0.0; // m/s
    final List<double> speedReadings = [];

    String formatDistance(double meters) {
      if (meters < 1000) {
        return '${meters.round()} m';
      } else {
        return '${(meters / 1000).toStringAsFixed(1)} km';
      }
    }

    String formatETA(double seconds) {
      if (seconds.isInfinite || seconds.isNaN || seconds <= 0) {
        return 'Calculating...';
      }

      final minutes = (seconds / 60).round();
      if (minutes < 1) {
        return 'Less than 1 min';
      } else if (minutes == 1) {
        return '1 min';
      } else if (minutes < 60) {
        return '$minutes mins';
      } else {
        final hours = (minutes / 60).floor();
        final remainingMins = minutes % 60;
        if (remainingMins == 0) {
          return '$hours hr';
        }
        return '$hours hr $remainingMins min';
      }
    }

    Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          final isTracking = prefs.getBool(_trackingKey) ?? false;

          if (!isTracking) {
            timer.cancel();
            await audioPlayer.stop();
            await audioPlayer.dispose();
            service.stopSelf();
            return;
          }

          final stationLat = prefs.getDouble(_stationLatKey);
          final stationLng = prefs.getDouble(_stationLngKey);
          final stationName = prefs.getString(_stationNameKey);
          final radiusMeters = prefs.getDouble(_radiusKey);

          if (stationLat == null ||
              stationLng == null ||
              stationName == null ||
              radiusMeters == null) {
            return;
          }

          try {
            // Check location permissions
            final permission = await Geolocator.checkPermission();
            if (permission == LocationPermission.denied ||
                permission == LocationPermission.deniedForever) {
              return;
            }

            // Get current position
            final position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            ).timeout(const Duration(seconds: 30));

            final currentTime = DateTime.now();
            final distance = Geolocator.distanceBetween(
              position.latitude,
              position.longitude,
              stationLat,
              stationLng,
            );

            // Calculate speed if we have previous position
            if (lastPosition != null && lastPositionTime != null) {
              final timeDiff =
                  currentTime.difference(lastPositionTime!).inSeconds;
              if (timeDiff > 0) {
                final distanceMoved = Geolocator.distanceBetween(
                  lastPosition!.latitude,
                  lastPosition!.longitude,
                  position.latitude,
                  position.longitude,
                );
                final currentSpeed = distanceMoved / timeDiff; // m/s

                // Keep last 5 speed readings for smoothing
                speedReadings.add(currentSpeed);
                if (speedReadings.length > 5) {
                  speedReadings.removeAt(0);
                }

                // Calculate average speed
                if (speedReadings.isNotEmpty) {
                  averageSpeed = speedReadings.reduce((a, b) => a + b) /
                      speedReadings.length;
                }
              }
            }

            lastPosition = position;
            lastPositionTime = currentTime;

            // Format distance and ETA
            final distanceStr = formatDistance(distance);
            String notificationContent;

            if (averageSpeed > 0.5) {
              // Only show ETA if moving (> 0.5 m/s = 1.8 km/h)
              final etaSeconds = distance / averageSpeed;
              final etaStr = formatETA(etaSeconds);
              final speedKmh = (averageSpeed * 3.6).toStringAsFixed(0);
              notificationContent =
                  '📍 $distanceStr away • ⏱️ $etaStr • 🚄 $speedKmh km/h\n$stationName';
            } else {
              notificationContent =
                  '📍 $distanceStr from $stationName\nMove to see ETA';
            }

            // Update foreground notification with live info
            service.setForegroundNotificationInfo(
              title: '🚆 Rail Alert Tracking',
              content: notificationContent,
            );

            // Trigger alarm if within radius and haven't triggered yet
            if (distance <= radiusMeters && !hasTriggered) {
              hasTriggered = true;

              // Play alarm sound
              await audioPlayer.play(AssetSource('alarm.mp3'));
              await audioPlayer.setReleaseMode(ReleaseMode.loop);

              // Show high-priority notification
              final androidDetails = AndroidNotificationDetails(
                'rail_alert_alarm_bg',
                'Rail Alert Alarm',
                channelDescription: 'High priority alarm notifications',
                importance: Importance.max,
                priority: Priority.max,
                fullScreenIntent: true,
                ongoing: true,
                autoCancel: false,
                playSound: false,
                category: AndroidNotificationCategory.alarm,
                visibility: NotificationVisibility.public,
                enableVibration: true,
                vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
                styleInformation: BigTextStyleInformation(
                  'You have reached your destination station. Please prepare to alight.\n\nDistance: $distanceStr',
                  contentTitle: '🚉 Approaching $stationName!',
                ),
              );

              final details = NotificationDetails(android: androidDetails);

              await flutterLocalNotificationsPlugin.show(
                999,
                '🚉 Approaching $stationName!',
                'You are near your station ($distanceStr). Tap to dismiss.',
                details,
              );

              // Send event to main app
              service.invoke('alarm_triggered', {
                'stationName': stationName,
                'distance': distance,
              });
            }
          } catch (e) {
            // Location fetch failed - service will retry on next cycle
          }
        }
      }
    });
  }
}
