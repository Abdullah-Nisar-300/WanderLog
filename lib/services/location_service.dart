// location_service.dart
// Location service utilizing geolocator to query GPS coordinates and verify system level availability.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'permission_service.dart';

class LocationService {
  // Singleton instance
  static final LocationService instance = LocationService._internal();
  LocationService._internal();

  /// Fetches the current location if permissions and services are enabled.
  /// Returns a [Position] object, or [null] if any check fails, services are disabled, or a timeout occurs.
  Future<Position?> getCurrentLocation(BuildContext context) async {
    try {
      // 1. Request location permission
      final bool hasPermission = await PermissionService.instance.requestLocationPermission(context);
      if (!hasPermission) {
        debugPrint('Location Service: Permission was denied.');
        return null;
      }

      // 2. Check if location services (GPS) are enabled on the device
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location Service: Device location services are disabled.');
        if (context.mounted) {
          await _showEnableLocationServicesDialog(context);
        }
        return null;
      }

      // 3. Retrieve the current position with a timeout
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } on TimeoutException catch (e) {
      debugPrint('Location Service: Timeout fetching coordinates: $e');
      return null;
    } catch (e) {
      debugPrint('Location Service: Exception caught: $e');
      return null;
    }
  }

  /// Dialog prompting the user to open system location settings
  Future<void> _showEnableLocationServicesDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.gps_off_rounded, color: Colors.orangeAccent, size: 24),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'GPS Service Disabled',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: const Text(
            'Your device\'s location services are currently turned off. Please turn on location services in your system settings to tag your memories.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await Geolocator.openLocationSettings();
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
