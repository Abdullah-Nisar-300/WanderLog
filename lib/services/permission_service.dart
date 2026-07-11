// permission_service.dart
// Centralized permission service managing application request flows for GPS and Camera permissions.

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  // Singleton instance
  static final PermissionService instance = PermissionService._internal();
  PermissionService._internal();

  /// Requests the user's location permission.
  /// Returns [true] if permission is granted, otherwise [false].
  Future<bool> requestLocationPermission(BuildContext context) async {
    PermissionStatus status = await Permission.location.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      // Show explanation dialog first before requesting
      final bool userAgreed = await _showRationaleDialog(
        context,
        title: 'Location Access Needed',
        message: 'WanderLog uses your device location to automatically tag your photo memories and show them on the map. This helps you remember exactly where you captured each moment.',
        icon: Icons.location_on_rounded,
      );

      if (userAgreed) {
        status = await Permission.location.request();
        return status.isGranted;
      }
      return false;
    }

    if (status.isPermanentlyDenied) {
      // Let the user know the permission is permanently disabled and prompt them to open settings
      await _showSettingsDialog(
        context,
        title: 'Enable Location Services',
        message: 'You have permanently disabled location access for WanderLog. Please open App Settings, enable location permissions, and try again.',
      );
      return false;
    }

    // Attempt request for other edge statuses (like limited or restricted)
    status = await Permission.location.request();
    return status.isGranted;
  }

  /// Requests the user's camera permission.
  /// Returns [true] if permission is granted, otherwise [false].
  Future<bool> requestCameraPermission(BuildContext context) async {
    PermissionStatus status = await Permission.camera.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      // Show explanation dialog first before requesting
      final bool userAgreed = await _showRationaleDialog(
        context,
        title: 'Camera Access Needed',
        message: 'WanderLog needs camera permission to capture photo memories directly from the app and save them to your journal.',
        icon: Icons.camera_alt_rounded,
      );

      if (userAgreed) {
        status = await Permission.camera.request();
        return status.isGranted;
      }
      return false;
    }

    if (status.isPermanentlyDenied) {
      // Prompt user to open settings to enable permission
      await _showSettingsDialog(
        context,
        title: 'Enable Camera Permission',
        message: 'You have permanently disabled camera access for WanderLog. Please open App Settings, enable camera permissions, and try again.',
      );
      return false;
    }

    status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Helper dialog explaining why permission is required
  Future<bool> _showRationaleDialog(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E2E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(icon, color: const Color(0xFF818CF8), size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: Text(
                message,
                style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Not Now', style: TextStyle(color: Colors.white38)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Continue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// Helper dialog prompting the user to open system app settings
  Future<void> _showSettingsDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.settings_suggest_rounded, color: Colors.orangeAccent, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Open Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
