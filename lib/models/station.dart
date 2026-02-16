class Station {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? line;

  const Station({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.line,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lng'] as num).toDouble(),
      line: json['line'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lat': latitude,
        'lng': longitude,
        if (line != null) 'line': line,
      };

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Station && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
