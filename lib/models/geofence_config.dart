import 'station.dart';

enum TrackingStatus { idle, tracking, triggered }

class GeofenceConfig {
  final Station station;
  final double radiusMeters;
  final TrackingStatus status;
  final DateTime? activatedAt;

  const GeofenceConfig({
    required this.station,
    required this.radiusMeters,
    this.status = TrackingStatus.idle,
    this.activatedAt,
  });

  GeofenceConfig copyWith({
    Station? station,
    double? radiusMeters,
    TrackingStatus? status,
    DateTime? activatedAt,
  }) {
    return GeofenceConfig(
      station: station ?? this.station,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      status: status ?? this.status,
      activatedAt: activatedAt ?? this.activatedAt,
    );
  }
}
