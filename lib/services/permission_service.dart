import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Returns true if ALL required permissions are granted.
  Future<bool> checkAllPermissions() async {
    final location = await Permission.location.isGranted;
    final locationAlways = await Permission.locationAlways.isGranted;
    final notification = await Permission.notification.isGranted;
    return location && locationAlways && notification;
  }

  /// Requests permissions sequentially, returns true if all granted.
  Future<bool> requestAllPermissions() async {
    // Step 1: Fine location (when in use)
    var locationStatus = await Permission.locationWhenInUse.request();
    if (!locationStatus.isGranted) return false;

    // Step 2: Background location (always)
    var alwaysStatus = await Permission.locationAlways.request();
    if (!alwaysStatus.isGranted) return false;

    // Step 3: Notifications
    var notifStatus = await Permission.notification.request();
    if (!notifStatus.isGranted) return false;

    // Step 4: Battery optimization (Android only, best-effort)
    await Permission.ignoreBatteryOptimizations.request();

    return true;
  }

  Future<bool> get isLocationGranted => Permission.location.isGranted;
  Future<bool> get isLocationAlwaysGranted =>
      Permission.locationAlways.isGranted;
  Future<bool> get isNotificationGranted => Permission.notification.isGranted;
  Future<bool> get isBatteryOptimizationIgnored =>
      Permission.ignoreBatteryOptimizations.isGranted;
}
