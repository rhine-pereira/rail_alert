import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import '../models/station.dart';
import '../models/geofence_config.dart';
import '../models/app_settings.dart';
import '../services/station_data_service.dart';
import '../services/location_service.dart';
import '../services/audio_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/permission_service.dart';
import '../services/background_location_service.dart';

class AppState extends ChangeNotifier {
  final StationDataService stationDataService;
  final LocationService locationService;
  final AudioService audioService;
  final NotificationService notificationService;
  final StorageService storageService;
  final PermissionService permissionService;
  final BackgroundLocationService backgroundLocationService;

  AppState({
    required this.stationDataService,
    required this.locationService,
    required this.audioService,
    required this.notificationService,
    required this.storageService,
    required this.permissionService,
    required this.backgroundLocationService,
  });

  // --- State Fields ---
  List<Station> _stations = [];
  Station? _selectedStation;
  double _radiusKm = 2.0;
  TrackingStatus _trackingStatus = TrackingStatus.idle;
  AppSettings _settings = const AppSettings();
  bool _permissionsGranted = false;
  Position? _currentPosition;
  Position? _lastPosition;
  DateTime? _lastPositionTime;
  double? _distanceToStation;
  double _currentSpeed = 0.0; // m/s
  double? _estimatedTimeArrival; // seconds
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
  double get currentSpeed => _currentSpeed;
  double? get estimatedTimeArrival => _estimatedTimeArrival;
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
      await backgroundLocationService.initialize();
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

    // Start background service for continuous tracking
    await backgroundLocationService.startBackgroundTracking(
      stationLat: _selectedStation!.latitude,
      stationLng: _selectedStation!.longitude,
      stationName: _selectedStation!.name,
      radiusMeters: _radiusKm * 1000,
    );

    // Also keep foreground tracking for when app is in use
    locationService.startListening();
    _positionSub = locationService.positionStream.listen(_onPositionUpdate);

    // Set up a periodic check every 15 seconds as fallback
    _checkTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _fetchAndCheck(),
    );

    // Listen for background service alarm triggers
    final service = FlutterBackgroundService();
    service.on('alarm_triggered').listen((event) {
      _triggerAlarm();
    });

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

    // Calculate speed if we have previous position
    if (_lastPosition != null && _lastPositionTime != null) {
      final currentTime = DateTime.now();
      final timeDiff = currentTime.difference(_lastPositionTime!).inSeconds;
      if (timeDiff > 0) {
        final distanceMoved = locationService.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        _currentSpeed = distanceMoved / timeDiff; // m/s
      }
    }

    _lastPosition = position;
    _lastPositionTime = DateTime.now();

    _distanceToStation = locationService.distanceBetween(
      position.latitude,
      position.longitude,
      _selectedStation!.latitude,
      _selectedStation!.longitude,
    );

    // Calculate ETA if moving
    if (_currentSpeed > 0.5) {
      // Only if moving (> 0.5 m/s = 1.8 km/h)
      _estimatedTimeArrival = _distanceToStation! / _currentSpeed;
    } else {
      _estimatedTimeArrival = null;
    }

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
    _lastPosition = null;
    _lastPositionTime = null;
    _currentSpeed = 0.0;
    _estimatedTimeArrival = null;

    _positionSub?.cancel();
    _positionSub = null;
    _checkTimer?.cancel();
    _checkTimer = null;

    locationService.stopListening();
    await backgroundLocationService.stopBackgroundTracking();
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
