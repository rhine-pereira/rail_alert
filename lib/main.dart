import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_state.dart';
import 'services/station_data_service.dart';
import 'services/location_service.dart';
import 'services/audio_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'services/permission_service.dart';
import 'services/background_location_service.dart';
import 'screens/permissions_screen.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RailAlertApp());
}

class RailAlertApp extends StatelessWidget {
  const RailAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(
        stationDataService: StationDataService(),
        locationService: LocationService(),
        audioService: AudioService(),
        notificationService: NotificationService(),
        storageService: StorageService(),
        permissionService: PermissionService(),
        backgroundLocationService: BackgroundLocationService(),
      )..initialize(),
      child: MaterialApp(
        title: 'Rail Alert',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blueAccent,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blueAccent,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const _InitScreen(),
          '/permissions': (context) => const PermissionsScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}

/// Splash / loading screen that checks state and routes accordingly.
class _InitScreen extends StatefulWidget {
  const _InitScreen();

  @override
  State<_InitScreen> createState() => _InitScreenState();
}

class _InitScreenState extends State<_InitScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _navigate();
  }

  void _navigate() {
    final state = context.read<AppState>();

    // Wait for initialization to complete
    if (state.isLoading) {
      state.addListener(_onStateChanged);
      return;
    }

    _routeBasedOnState(state);
  }

  void _onStateChanged() {
    final state = context.read<AppState>();
    if (!state.isLoading) {
      state.removeListener(_onStateChanged);
      _routeBasedOnState(state);
    }
  }

  void _routeBasedOnState(AppState state) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (state.permissionsGranted) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/permissions');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.train, size: 64, color: Colors.blueAccent),
            SizedBox(height: 24),
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading Rail Alert...'),
          ],
        ),
      ),
    );
  }
}
