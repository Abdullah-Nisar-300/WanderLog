// routes.dart
// Defines the complete list of named routes and screen mappings for the application.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/create_trip_screen.dart';
import '../screens/trip_details_screen.dart';
import '../screens/explorer_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/packing_list_screen.dart';
import '../screens/trip_map_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Wait for auth initialization state to resolve
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F0F1A),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6366F1),
              ),
            ),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const DashboardScreen();
        } else {
          return const SplashScreen();
        }
      },
    );
  }
}

class Routes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String dashboard = '/dashboard';
  static const String createTrip = '/createTrip';
  static const String tripDetails = '/tripDetails';
  static const String explorer = '/explorer';
  static const String profile = '/profile';
  static const String packingList = '/packingList';
  static const String tripMap = '/tripMap';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => const AuthWrapper(),
      login: (context) => const LoginScreen(),
      signup: (context) => const SignupScreen(),
      dashboard: (context) => const DashboardScreen(),
      createTrip: (context) => const CreateTripScreen(),
      tripDetails: (context) => const TripDetailsScreen(),
      explorer: (context) => const ExplorerScreen(),
      profile: (context) => const ProfileScreen(),
      packingList: (context) => const PackingListScreen(),
      tripMap: (context) => const TripMapScreen(),
    };
  }
}
