// dashboard_screen.dart
// Main app interface containing navigation options, a list of trips, and reactive callbacks.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/dummy_data.dart';
import '../models/models.dart';
import '../routes/routes.dart';
import '../widgets/trip_card.dart';
import '../utils/avatar_helper.dart';
import '../services/firestore_service.dart';
import 'explorer_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  // Triggered when FAB is pressed or create trip is called
  Future<void> _navigateToCreateTrip() async {
    final result = await Navigator.pushNamed(context, Routes.createTrip);
    if (!mounted) return;
    
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Trip created successfully!'),
            ],
          ),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isTablet = mediaQuery.size.width > 600;

    // Body widgets corresponding to BottomNavigationBar
    final List<Widget> tabs = [
      _buildTripsTab(isTablet, mediaQuery),
      const ExplorerScreen(isEmbedded: true),
      const ProfileScreen(isEmbedded: true),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'WanderLog',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirestoreService.instance.getUserStream(FirebaseAuth.instance.currentUser?.uid ?? ''),
            builder: (context, snapshot) {
              final userData = (snapshot.hasData && snapshot.data!.data() != null)
                  ? snapshot.data!.data()!
                  : {};
              final avatarUrl = userData['avatar'] as String?;
              return IconButton(
                icon: CircleAvatar(
                  radius: 16,
                  backgroundImage: getAvatarProvider(avatarUrl ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200&auto=format&fit=crop'),
                  backgroundColor: const Color(0xFF6366F1),
                ),
                onPressed: () {
                  // Switch to Profile Tab
                  setState(() {
                    _currentIndex = 2;
                  });
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            // Drawer Header
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirestoreService.instance.getUserStream(FirebaseAuth.instance.currentUser?.uid ?? ''),
              builder: (context, snapshot) {
                final userData = (snapshot.hasData && snapshot.data!.data() != null)
                    ? snapshot.data!.data()!
                    : {};
                final avatarUrl = userData['avatar'] as String?;
                final name = userData['name'] as String? ?? 'Wanderer';
                final email = userData['email'] as String? ?? '';
                
                return UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF1E1E3F)],
                    ),
                  ),
                  currentAccountPicture: CircleAvatar(
                    backgroundImage: getAvatarProvider(avatarUrl ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200&auto=format&fit=crop'),
                  ),
                  accountName: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  accountEmail: Text(email),
                );
              },
            ),
            // Profile Link
            ListTile(
              leading: const Icon(Icons.person_rounded),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context); // Close Drawer
                setState(() {
                  _currentIndex = 2; // Jump to Profile
                });
              },
            ),
            // Settings Link
            ListTile(
              leading: const Icon(Icons.settings_rounded),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _currentIndex = 2; // Jump to Profile/Settings
                });
              },
            ),
            // Explorer Link
            ListTile(
              leading: const Icon(Icons.explore_rounded),
              title: const Text('Explorer Tool'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _currentIndex = 1; // Jump to Explorer
                });
              },
            ),
            const Divider(),
            const Spacer(),
            // Logout
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context); // Close Drawer
                Navigator.pushReplacementNamed(context, Routes.login);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF818CF8)
            : const Color(0xFF4F46E5),
        unselectedItemColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white54
            : Colors.black45,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E2E)
            : Colors.white,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.flight_takeoff_rounded),
            activeIcon: Icon(Icons.flight_takeoff_rounded),
            label: 'Trips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore_rounded),
            label: 'Explorer',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
      // FAB displays only on Trips tab
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _navigateToCreateTrip,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Trip'),
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  // Helper widget to construct the Trips Tab
  Widget _buildTripsTab(bool isTablet, MediaQueryData mediaQuery) {
    final user = FirebaseAuth.instance.currentUser;
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<List<Trip>>(
      stream: FirestoreService.instance.getTripsStream(user?.uid ?? ''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF6366F1),
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Error loading adventures: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          );
        }

        final tripsList = snapshot.data ?? [];

        if (tripsList.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.landscape_rounded,
                    size: 72,
                    color: isDarkTheme ? Colors.white24 : Colors.black12,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No trips planned yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkTheme ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the "New Trip" button to create an adventure.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDarkTheme ? Colors.white38 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'My Adventures',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Keep track of your destinations, schedules, and budgets',
                style: TextStyle(
                  color: isDarkTheme ? Colors.white54 : Colors.black54,
                  fontSize: 13,
                ),
              ),
          const SizedBox(height: 16),

          // Responsive grid layout for tablets, single-column for mobile
          Expanded(
            child: isTablet
                ? GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: tripsList.length,
                    itemBuilder: (context, index) {
                      final trip = tripsList[index];
                      return TripCard(
                        trip: trip,
                        onTap: () => _navigateToTripDetails(trip),
                      );
                    },
                  )
                : ListView.builder(
                    itemCount: tripsList.length,
                    itemBuilder: (context, index) {
                      final trip = tripsList[index];
                      return TripCard(
                        trip: trip,
                        onTap: () => _navigateToTripDetails(trip),
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

  void _navigateToTripDetails(Trip trip) {
    // Phase 2 Demo: Passing arguments to route
    Navigator.pushNamed(
      context,
      Routes.tripDetails,
      arguments: trip.id,
    ).then((_) {
      // Re-render dashboard when returning in case trips were modified inside details
      setState(() {});
    });
  }
}
