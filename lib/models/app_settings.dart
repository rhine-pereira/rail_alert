class AppSettings {
  final double defaultRadiusKm;
  final bool vibrationEnabled;
  final double alarmVolume;

  const AppSettings({
    this.defaultRadiusKm = 2.0,
    this.vibrationEnabled = true,
    this.alarmVolume = 1.0,
  });

  AppSettings copyWith({
    double? defaultRadiusKm,
    bool? vibrationEnabled,
    double? alarmVolume,
  }) {
    return AppSettings(
      defaultRadiusKm: defaultRadiusKm ?? this.defaultRadiusKm,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      alarmVolume: alarmVolume ?? this.alarmVolume,
    );
  }
}
