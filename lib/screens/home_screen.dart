import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/station.dart';
import '../models/geofence_config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _StationSelectionTab(),
          _TrackingTab(),
          _SettingsTab(),
        ],
      ),
      bottomNavigationBar: Consumer<AppState>(
        builder: (context, state, _) {
          return NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) => setState(() => _currentIndex = i),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.train),
                selectedIcon: Icon(Icons.train, color: Colors.blueAccent),
                label: 'Station',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: state.isTracking || state.isTriggered,
                  backgroundColor:
                      state.isTriggered ? Colors.red : Colors.green,
                  child: const Icon(Icons.gps_fixed),
                ),
                label: 'Tracking',
              ),
              const NavigationDestination(
                icon: Icon(Icons.settings),
                selectedIcon: Icon(Icons.settings, color: Colors.blueAccent),
                label: 'Settings',
              ),
            ],
          );
        },
      ),
    );
  }
}

// ===== STATION SELECTION TAB =====
class _StationSelectionTab extends StatefulWidget {
  const _StationSelectionTab();

  @override
  State<_StationSelectionTab> createState() => _StationSelectionTabState();
}

class _StationSelectionTabState extends State<_StationSelectionTab> {
  final TextEditingController _searchController = TextEditingController();
  List<Station> _filteredStations = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearch);
  }

  void _onSearch() {
    final state = context.read<AppState>();
    final query = _searchController.text;
    setState(() {
      if (query.isEmpty) {
        _filteredStations = state.stations;
      } else {
        _filteredStations = state.stations
            .where((s) => s.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        if (_filteredStations.isEmpty && _searchController.text.isEmpty) {
          _filteredStations = state.stations;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Select Station'),
            centerTitle: true,
          ),
          body: Column(
            children: [
              // Active tracking banner
              if (state.isTracking || state.isTriggered)
                _TrackingBanner(state: state),

              // Search bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Search stations...',
                  leading: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.search),
                  ),
                  trailing: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      ),
                  ],
                ),
              ),

              // Radius slider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.radar, size: 20, color: Colors.blueAccent),
                    const SizedBox(width: 8),
                    Text(
                      'Alert radius: ${state.radiusKm.toStringAsFixed(1)} km',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Expanded(
                      child: Slider(
                        value: state.radiusKm,
                        min: 0.5,
                        max: 10.0,
                        divisions: 19,
                        label: '${state.radiusKm.toStringAsFixed(1)} km',
                        onChanged:
                            state.isTracking ? null : (v) => state.setRadius(v),
                      ),
                    ),
                  ],
                ),
              ),

              // Station list
              Expanded(
                child: _filteredStations.isEmpty
                    ? const Center(child: Text('No stations found'))
                    : ListView.builder(
                        itemCount: _filteredStations.length,
                        itemBuilder: (context, index) {
                          final station = _filteredStations[index];
                          final isSelected =
                              state.selectedStation?.id == station.id;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isSelected
                                  ? Colors.blueAccent
                                  : Colors.grey[300],
                              child: Icon(
                                Icons.train,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[600],
                                size: 20,
                              ),
                            ),
                            title: Text(
                              station.name,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: station.line != null
                                ? Text(station.line!)
                                : null,
                            trailing: isSelected
                                ? const Icon(Icons.check_circle,
                                    color: Colors.blueAccent)
                                : null,
                            selected: isSelected,
                            onTap: state.isTracking
                                ? null
                                : () => state.selectStation(station),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ===== TRACKING TAB =====
class _TrackingTab extends StatelessWidget {
  const _TrackingTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Tracking'),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Error banner
                if (state.errorMessage != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(state.errorMessage!,
                                style: const TextStyle(color: Colors.red))),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: state.clearError,
                        ),
                      ],
                    ),
                  ),

                // Permission warning
                if (!state.permissionsGranted)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Some permissions are missing. Tracking may not work in the background.',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ),
                        TextButton(
                          onPressed: () => state.requestPermissions(),
                          child: const Text('Fix'),
                        ),
                      ],
                    ),
                  ),

                const Spacer(),

                // Status indicator
                _StatusCircle(status: state.trackingStatus),
                const SizedBox(height: 24),

                Text(
                  _statusLabel(state.trackingStatus),
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                if (state.selectedStation != null) ...[
                  Text(
                    'Destination: ${state.selectedStation!.name}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Alert radius: ${state.radiusKm.toStringAsFixed(1)} km',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ] else
                  Text(
                    'No station selected',
                    style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                  ),

                if (state.distanceToStation != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text('Distance to station',
                            style: TextStyle(fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          _formatDistance(state.distanceToStation!),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const Spacer(),

                // Action button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: _buildActionButton(context, state),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(BuildContext context, AppState state) {
    switch (state.trackingStatus) {
      case TrackingStatus.idle:
        return FilledButton.icon(
          onPressed: state.selectedStation == null
              ? null
              : () => state.startTracking(),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Tracking', style: TextStyle(fontSize: 16)),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green,
          ),
        );
      case TrackingStatus.tracking:
        return FilledButton.icon(
          onPressed: () => state.stopTracking(),
          icon: const Icon(Icons.stop),
          label: const Text('Stop Tracking', style: TextStyle(fontSize: 16)),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
          ),
        );
      case TrackingStatus.triggered:
        return FilledButton.icon(
          onPressed: () => state.dismissAlarm(),
          icon: const Icon(Icons.alarm_off),
          label: const Text('DISMISS ALARM', style: TextStyle(fontSize: 18)),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        );
    }
  }

  String _statusLabel(TrackingStatus status) {
    switch (status) {
      case TrackingStatus.idle:
        return 'Idle';
      case TrackingStatus.tracking:
        return 'Tracking Active';
      case TrackingStatus.triggered:
        return '⚠ ALARM ⚠';
    }
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toInt()} m';
  }
}

class _StatusCircle extends StatelessWidget {
  final TrackingStatus status;
  const _StatusCircle({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (status) {
      case TrackingStatus.idle:
        color = Colors.grey;
        icon = Icons.gps_off;
      case TrackingStatus.tracking:
        color = Colors.green;
        icon = Icons.gps_fixed;
      case TrackingStatus.triggered:
        color = Colors.red;
        icon = Icons.alarm;
    }

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.15),
        border: Border.all(color: color, width: 4),
      ),
      child: Icon(icon, size: 56, color: color),
    );
  }
}

class _TrackingBanner extends StatelessWidget {
  final AppState state;
  const _TrackingBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final isTriggered = state.isTriggered;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: isTriggered ? Colors.red : Colors.green,
      child: Row(
        children: [
          Icon(
            isTriggered ? Icons.alarm : Icons.gps_fixed,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isTriggered
                  ? 'ALARM: Approaching ${state.selectedStation?.name}'
                  : 'Tracking: ${state.selectedStation?.name}',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
          if (state.distanceToStation != null)
            Text(
              state.distanceToStation! >= 1000
                  ? '${(state.distanceToStation! / 1000).toStringAsFixed(1)} km'
                  : '${state.distanceToStation!.toInt()} m',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}

// ===== SETTINGS TAB =====
class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final settings = state.settings;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
            centerTitle: true,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _SectionHeader(title: 'Default Alert Radius'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        '${settings.defaultRadiusKm.toStringAsFixed(1)} km',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Slider(
                        value: settings.defaultRadiusKm,
                        min: 0.5,
                        max: 10.0,
                        divisions: 19,
                        label:
                            '${settings.defaultRadiusKm.toStringAsFixed(1)} km',
                        onChanged: (v) {
                          state.updateSettings(
                              settings.copyWith(defaultRadiusKm: v));
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const _SectionHeader(title: 'Alarm'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.volume_up),
                      title: const Text('Alarm Volume'),
                      subtitle: Slider(
                        value: settings.alarmVolume,
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                        label: '${(settings.alarmVolume * 100).toInt()}%',
                        onChanged: (v) {
                          state.updateSettings(
                              settings.copyWith(alarmVolume: v));
                        },
                      ),
                    ),
                    SwitchListTile(
                      secondary: const Icon(Icons.vibration),
                      title: const Text('Vibration'),
                      value: settings.vibrationEnabled,
                      onChanged: (v) {
                        state.updateSettings(
                            settings.copyWith(vibrationEnabled: v));
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.alarm),
                      title: const Text('Test Alarm'),
                      subtitle: const Text('Play alarm sound for 3 seconds'),
                      trailing: const Icon(Icons.play_circle_outline),
                      onTap: () async {
                        await state.audioService.playAlarm();
                        await Future.delayed(const Duration(seconds: 3));
                        await state.audioService.stopAlarm();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const _SectionHeader(title: 'Permissions'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        state.permissionsGranted
                            ? Icons.check_circle
                            : Icons.error,
                        color: state.permissionsGranted
                            ? Colors.green
                            : Colors.red,
                      ),
                      title: const Text('Permission Status'),
                      subtitle: Text(state.permissionsGranted
                          ? 'All permissions granted'
                          : 'Some permissions missing'),
                      trailing: state.permissionsGranted
                          ? null
                          : TextButton(
                              onPressed: () => state.requestPermissions(),
                              child: const Text('Grant'),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const _SectionHeader(title: 'About'),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Rail Alert'),
                  subtitle: Text('v1.0.0 — Never miss your stop again.'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
