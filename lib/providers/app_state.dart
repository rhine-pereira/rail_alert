import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/station.dart';
import '../models/geofence_config.dart';
import '../models/app_settings.dart';
import '../services/station_data_service.dart';
import '../services/location_service.dart';
import '../services/audio_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/permission_service.dart';

class AppState extends ChangeNotifier {
  final StationDataService stationDataService;
  final LocationService locationService;
  final AudioService audioService;
  final NotificationService notificationService;
  final StorageService storageService;
  final PermissionService permissionService;

  AppState({
    required this.stationDataService,
    required this.locationService,
    required this.audioService,
    required this.notificationService,
    required this.storageService,
    required this.permissionService,
  });

  // --- State Fields ---
  List<Station> _stations = [];
  Station? _selectedStation;
  double _radiusKm = 2.0;
  TrackingStatus _trackingStatus = TrackingStatus.idle;
  AppSettings _settings = const AppSettings();
  bool _permissionsGranted = false;
  Position? _currentPosition;
  double? _distanceToStation;
  String? _errorMessage;
  bool _isLoading = true;

  // --- Getters ---
  List<Station> get stations => _stations;
  Station? get selectedStation => _selectedStation;
  double get radiusKm => _radiusKm;
  TrackingStatus get trackingStatus => _trackingStatus;
  AppSettings get settings => _settings;
  bool get permissionsGranted => _permissionsGranted;
  Position? get currentPosition => _currentPosition;
  double? get distanceToStation => _distanceToStation;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isTracking => _trackingStatus == TrackingStatus.tracking;
  bool get isTriggered => _trackingStatus == TrackingStatus.triggered;

  StreamSubscription<Position>? _positionSub;
  Timer? _checkTimer;

  // --- Initialization ---
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await storageService.initialize();
      await notificationService.initialize();
      _settings = await storageService.loadSettings();
      _radiusKm = _settings.defaultRadiusKm;
      _stations = await stationDataService.loadStations();
      _permissionsGranted = await permissionService.checkAllPermissions();

      // Restore previous station selection
      final lastId = storageService.getLastStationId();
      if (lastId != null) {
        _selectedStation = _stations.cast<Station?>().firstWhere(
              (s) => s?.id == lastId,
              orElse: () => null,
            );
      }
    } catch (e) {
      _errorMessage = 'Failed to initialize: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // --- Permissions ---
  Future<bool> requestPermissions() async {
    _permissionsGranted = await permissionService.requestAllPermissions();
    notifyListeners();
    return _permissionsGranted;
  }

  // --- Station Selection ---
  void selectStation(Station station) {
    _selectedStation = station;
    storageService.saveLastStationId(station.id);
    notifyListeners();
  }

  void setRadius(double km) {
    _radiusKm = km.clamp(0.5, 10.0);
    notifyListeners();
  }

  // --- Tracking ---
  Future<void> startTracking() async {
    if (_selectedStation == null) {
      _errorMessage = 'Please select a station first.';
      notifyListeners();
      return;
    }

    if (!_permissionsGranted) {
      _errorMessage =
          'Permissions not granted. Please enable them in settings.';
      notifyListeners();
      return;
    }

    _trackingStatus = TrackingStatus.tracking;
    _errorMessage = null;
    await storageService.setTrackingActive(true);

    // Show persistent tracking notification
    await notificationService.showTrackingNotification(_selectedStation!.name);

    // Start location monitoring
    locationService.startListening();

    _positionSub = locationService.positionStream.listen(_onPositionUpdate);

    // Also set up a periodic check every 15 seconds as fallback
    _checkTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _fetchAndCheck(),
    );

    // Immediate first check
    await _fetchAndCheck();

    notifyListeners();
  }

  Future<void> _fetchAndCheck() async {
    final pos = await locationService.getCurrentPosition();
    if (pos != null) {
      _onPositionUpdate(pos);
    }
  }

  void _onPositionUpdate(Position position) {
    _currentPosition = position;

    if (_selectedStation == null ||
        _trackingStatus != TrackingStatus.tracking) {
      return;
    }

    _distanceToStation = locationService.distanceBetween(
      position.latitude,
      position.longitude,
      _selectedStation!.latitude,
      _selectedStation!.longitude,
    );

    final radiusMeters = _radiusKm * 1000;

    if (_distanceToStation! <= radiusMeters) {
      _triggerAlarm();
    }

    notifyListeners();
  }

  Future<void> _triggerAlarm() async {
    if (_trackingStatus == TrackingStatus.triggered) return;

    _trackingStatus = TrackingStatus.triggered;
    notifyListeners();

    // Play alarm sound
    await audioService.playAlarm();

    // Show full-screen alarm notification
    await notificationService.showAlarmNotification(_selectedStation!.name);
  }

  // --- Dismiss ---
  Future<void> dismissAlarm() async {
    await audioService.stopAlarm();
    await notificationService.cancelAlarmNotification();
    await stopTracking();
  }

  Future<void> stopTracking() async {
    _trackingStatus = TrackingStatus.idle;
    _distanceToStation = null;
    _currentPosition = null;

    _positionSub?.cancel();
    _positionSub = null;
    _checkTimer?.cancel();
    _checkTimer = null;

    locationService.stopListening();
    await notificationService.cancelAll();
    await storageService.setTrackingActive(false);

    notifyListeners();
  }

  // --- Settings ---
  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    await storageService.saveSettings(newSettings);
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _checkTimer?.cancel();
    locationService.dispose();
    audioService.dispose();
    super.dispose();
  }
}
