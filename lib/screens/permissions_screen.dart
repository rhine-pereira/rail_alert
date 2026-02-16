import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class PermissionsScreen extends StatelessWidget {
  const PermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(
                Icons.train,
                size: 80,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 24),
              const Text(
                'Rail Alert',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Get alerted when you\'re approaching your station',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              const _PermissionTile(
                icon: Icons.location_on,
                title: 'Location (Always)',
                description:
                    'Required to track your position in the background and trigger the alarm.',
              ),
              const SizedBox(height: 16),
              const _PermissionTile(
                icon: Icons.notifications_active,
                title: 'Notifications',
                description:
                    'Required to alert you with a full-screen notification when near your station.',
              ),
              const SizedBox(height: 16),
              const _PermissionTile(
                icon: Icons.battery_saver,
                title: 'Battery Optimization',
                description:
                    'Prevents Android from killing the app in the background.',
              ),
              const Spacer(),
              Consumer<AppState>(
                builder: (context, state, _) {
                  return FilledButton.icon(
                    onPressed: () async {
                      final granted = await state.requestPermissions();
                      if (granted && context.mounted) {
                        Navigator.of(context).pushReplacementNamed('/home');
                      }
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Grant Permissions'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/home');
                },
                child: const Text('Skip for now'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.blueAccent, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 4),
              Text(description,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            ],
          ),
        ),
      ],
    );
  }
}
