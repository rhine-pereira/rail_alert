import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

class StorageService {
  static const _keyDefaultRadius = 'default_radius_km';
  static const _keyVibrationEnabled = 'vibration_enabled';
  static const _keyAlarmVolume = 'alarm_volume';
  static const _keyLastStationId = 'last_station_id';
  static const _keyIsTracking = 'is_tracking';

  late SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- App Settings ---

  Future<AppSettings> loadSettings() async {
    return AppSettings(
      defaultRadiusKm: _prefs.getDouble(_keyDefaultRadius) ?? 2.0,
      vibrationEnabled: _prefs.getBool(_keyVibrationEnabled) ?? true,
      alarmVolume: _prefs.getDouble(_keyAlarmVolume) ?? 1.0,
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _prefs.setDouble(_keyDefaultRadius, settings.defaultRadiusKm);
    await _prefs.setBool(_keyVibrationEnabled, settings.vibrationEnabled);
    await _prefs.setDouble(_keyAlarmVolume, settings.alarmVolume);
  }

  // --- Tracking State ---

  Future<void> saveLastStationId(String stationId) async {
    await _prefs.setString(_keyLastStationId, stationId);
  }

  String? getLastStationId() => _prefs.getString(_keyLastStationId);

  Future<void> setTrackingActive(bool active) async {
    await _prefs.setBool(_keyIsTracking, active);
  }

  bool get isTrackingActive => _prefs.getBool(_keyIsTracking) ?? false;

  Future<void> clearTrackingState() async {
    await _prefs.remove(_keyLastStationId);
    await _prefs.setBool(_keyIsTracking, false);
  }
}
