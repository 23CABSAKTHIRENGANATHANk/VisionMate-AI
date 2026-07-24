// Main home screen for the VisionMate AI experience.
import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../widgets/custom_button.dart';
import '../camera/camera_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.homeTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppConstants.homeTitle,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Start Navigation',
              icon: Icons.navigation_outlined,
              onPressed: () {
                Navigator.of(context).pushNamed('/navigation');
              },
            ),
            const SizedBox(height: 12),
            CustomButton(
              label: 'Camera',
              icon: Icons.camera_alt_outlined,
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const CameraScreen()));
              },
            ),
            const SizedBox(height: 12),
            CustomButton(
              label: 'Settings',
              icon: Icons.settings_outlined,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            CustomButton(
              label: 'Help',
              icon: Icons.help_outline,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Help content will be added soon.'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
