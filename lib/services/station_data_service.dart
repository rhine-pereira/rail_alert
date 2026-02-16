import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/station.dart';

class StationDataService {
  List<Station>? _cachedStations;

  Future<List<Station>> loadStations() async {
    if (_cachedStations != null) return _cachedStations!;

    final jsonString = await rootBundle.loadString('assets/stations.json');
    final Map<String, dynamic> data = json.decode(jsonString);
    final List<dynamic> stationsJson = data['stations'];

    _cachedStations = stationsJson
        .map((s) => Station.fromJson(s as Map<String, dynamic>))
        .toList();
    return _cachedStations!;
  }

  List<Station> searchStations(String query) {
    if (_cachedStations == null) return [];
    final lowerQuery = query.toLowerCase();
    return _cachedStations!
        .where((s) => s.name.toLowerCase().contains(lowerQuery))
        .toList();
  }
}
