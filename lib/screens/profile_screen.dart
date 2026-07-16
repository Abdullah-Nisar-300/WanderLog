// profile_screen.dart
// User account settings page containing app preferences, notifications toggles, name editing, and logout actions.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../routes/routes.dart';
import '../utils/image_picker.dart';
import '../utils/avatar_helper.dart';
import '../main.dart';
import '../services/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  final bool isEmbedded;

  const ProfileScreen({
    super.key,
    this.isEmbedded = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;
  late bool _darkModeEnabled;
  String _selectedCurrency = 'USD';

  @override
  void initState() {
    super.initState();
    _darkModeEnabled = themeNotifier.value == ThemeMode.dark;
  }

  void _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, Routes.login, (route) => false);
    }
  }

  Future<void> _updateProfilePhoto(String uid, String dataUrl) async {
    // Show a loading Snackbar while uploading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Text('Uploading profile picture...'),
          ],
        ),
        duration: Duration(seconds: 4),
      ),
    );

    try {
      final filename = 'profile_$uid.jpg';
      final storageRef = FirebaseStorage.instance.ref().child('profile_photos/$filename');
      final uploadTask = await storageRef.putString(dataUrl, format: PutStringFormat.dataUrl);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      await FirestoreService.instance.updateUserProfile(uid, {'avatar': downloadUrl});

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload picture: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showEditNameDialog(String currentName, String uid) {
    final nameController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          title: const Text('Edit Name', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Name',
              labelStyle: TextStyle(color: Colors.white70),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF818CF8))),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isEmpty) return;
                try {
                  await FirestoreService.instance.updateUserProfile(uid, {'name': newName});
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Name updated successfully!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update name: $e'),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isTablet = mediaQuery.size.width > 600;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirestoreService.instance.getUserStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F0F1A),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)),
            ),
          );
        }

        final userData = (snapshot.hasData && snapshot.data!.data() != null)
            ? snapshot.data!.data()!
            : {};
        final name = userData['name'] as String? ?? 'Wanderer';
        final email = userData['email'] as String? ?? '';
        final avatar = userData['avatar'] as String? ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200&auto=format&fit=crop';
        final homeCurrency = userData['homeCurrency'] as String? ?? 'USD';
        _selectedCurrency = homeCurrency;

        final bodyContent = ListView(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? mediaQuery.size.width * 0.15 : 16.0,
            vertical: 16.0,
          ),
          children: [
            // 1. Profile Header
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 104,
                            height: 104,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                              ),
                            ),
                          ),
                          CircleAvatar(
                            radius: 48,
                            backgroundImage: getAvatarProvider(avatar),
                            backgroundColor: Colors.transparent,
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () async {
                          final picked = await pickUserImage();
                          if (picked != null) {
                            await _updateProfilePhoto(uid, picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF6366F1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 18, color: Color(0xFF818CF8)),
                        onPressed: () => _showEditNameDialog(name, uid),
                        tooltip: 'Edit Name',
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white54
                          : Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 2. Preferences Card
            Text(
              'App Preferences',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white60
                    : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(
                    Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.6,
                  ),
              child: Column(
                children: [
                  // Notification Toggle Switch
                  ListTile(
                    leading: const Icon(Icons.notifications_active_rounded, color: Color(0xFF818CF8)),
                    title: const Text('Push Notifications'),
                    subtitle: const Text('Receive alerts on budget thresholds'),
                    trailing: Switch(
                      value: _notificationsEnabled,
                      activeColor: const Color(0xFF6366F1),
                      onChanged: (bool value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                      },
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white10
                        : Colors.black12,
                  ),

                  // Dark Mode Toggle Switch
                  ListTile(
                    leading: const Icon(Icons.dark_mode_rounded, color: Color(0xFF818CF8)),
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Toggle high contrast dark skin'),
                    trailing: Switch(
                      value: _darkModeEnabled,
                      activeThumbColor: const Color(0xFF6366F1),
                      onChanged: (bool value) {
                        setState(() {
                          _darkModeEnabled = value;
                        });
                        themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
                      },
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white10
                        : Colors.black12,
                  ),

                  // Currency Dropdown
                  ListTile(
                    leading: const Icon(Icons.currency_exchange_rounded, color: Color(0xFF818CF8)),
                    title: const Text('Preferred Currency'),
                    subtitle: const Text('Standard symbol for mock entries'),
                    trailing: DropdownButton<String>(
                      value: _selectedCurrency,
                      dropdownColor: const Color(0xFF1E1E2E),
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'USD', child: Text('USD (\$)', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 'EUR', child: Text('EUR (€)', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 'JPY', child: Text('JPY (¥)', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 'CHF', child: Text('CHF (Fr)', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 'PKR', child: Text('PKR (Rs)', style: TextStyle(fontSize: 13))),
                      ],
                      onChanged: (value) async {
                        if (value != null) {
                          try {
                            await FirestoreService.instance.updateUserProfile(uid, {'homeCurrency': value});
                          } catch (e) {
                            debugPrint('Failed to update currency: $e');
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. Logout Button
            ElevatedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout Session', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withOpacity(0.15),
                foregroundColor: Colors.redAccent,
                side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 32),
          ],
        );

        if (widget.isEmbedded) {
          return bodyContent;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile Settings'),
            centerTitle: true,
          ),
          body: SafeArea(child: bodyContent),
        );
      },
    );
  }
}
