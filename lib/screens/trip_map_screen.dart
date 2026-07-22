// trip_map_screen.dart
// Screen displaying trip memory photos mapped to their corresponding physical coordinates on an interactive Google Map.

import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../models/models.dart';
import '../services/firestore_service.dart';
import '../widgets/memory_image_widget.dart';

class TripMapScreen extends StatefulWidget {
  const TripMapScreen({super.key});

  @override
  State<TripMapScreen> createState() => _TripMapScreenState();
}

class _TripMapScreenState extends State<TripMapScreen> {
  late String _tripId;
  bool _initialized = false;
  LatLng? _fallbackDeviceLocation;
  bool _loadingFallback = false;
  GoogleMapController? _mapController;
  bool _showListView = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      _tripId = (args is String && args.isNotEmpty) ? args : '';
      _initialized = true;
      _loadFallbackLocation();
    }
  }

  /// Tries to resolve user's last known or current coordinates to center map if no memories are tagged.
  Future<void> _loadFallbackLocation() async {
    if (_fallbackDeviceLocation != null || _loadingFallback) return;
    setState(() {
      _loadingFallback = true;
    });

    try {
      Position? position;
      if (!kIsWeb) {
        try {
          position = await Geolocator.getLastKnownPosition();
        } catch (_) {}
      }

      position ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 4),
        ),
      );

      if (mounted) {
        setState(() {
          _fallbackDeviceLocation = LatLng(position!.latitude, position.longitude);
          _loadingFallback = false;
        });
      }
    } catch (e) {
      debugPrint('Trip Map: Using default coordinates (location fallback): $e');
      if (mounted) {
        setState(() {
          _fallbackDeviceLocation = const LatLng(33.9070, 73.3903); // standard default fallback
          _loadingFallback = false;
        });
      }
    }
  }

  /// Calculates center of the map based on the average coordinates of all tagged memories.
  LatLng _calculateCenter(List<Memory> mapMemories) {
    if (mapMemories.isEmpty) {
      return _fallbackDeviceLocation ?? const LatLng(33.9070, 73.3903);
    }
    double sumLat = 0.0;
    double sumLng = 0.0;
    for (var m in mapMemories) {
      sumLat += m.latitude!;
      sumLng += m.longitude!;
    }
    return LatLng(sumLat / mapMemories.length, sumLng / mapMemories.length);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Memory>>(
      stream: _tripId.isNotEmpty
          ? FirestoreService.instance.getMemoriesStream(_tripId)
          : Stream.value(<Memory>[]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F0F1A),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F0F1A),
            appBar: AppBar(
              backgroundColor: const Color(0xFF0F0F1A),
              title: const Text('Trip Map', style: TextStyle(fontWeight: FontWeight.bold)),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Failed to load memories: ${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final memories = snapshot.data ?? [];
        final mapMemories = memories.where((m) => m.latitude != null && m.longitude != null).toList();

        // Map memories to markers
        final Set<Marker> markers = mapMemories.map((memory) {
          return Marker(
            markerId: MarkerId(memory.id),
            position: LatLng(memory.latitude!, memory.longitude!),
            infoWindow: InfoWindow(
              title: memory.caption,
              snippet: 'Tap to view details',
              onTap: () => _showMemoryDetailsSheet(context, memory),
            ),
            onTap: () => _showMemoryDetailsSheet(context, memory),
          );
        }).toSet();

        final centerLatLng = _calculateCenter(mapMemories);

        // Adjust zoom level depending on markers count
        final double initialZoom = mapMemories.isEmpty ? (centerLatLng.latitude == 0.0 && centerLatLng.longitude == 0.0 ? 2.0 : 12.0) : 10.0;

        return Scaffold(
          backgroundColor: const Color(0xFF0F0F1A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F0F1A),
            title: const Text('Trip Map', style: TextStyle(fontWeight: FontWeight.bold)),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(_showListView ? Icons.map_rounded : Icons.view_list_rounded, color: const Color(0xFF818CF8)),
                tooltip: _showListView ? 'Switch to Map View' : 'Switch to Location List',
                onPressed: () {
                  setState(() {
                    _showListView = !_showListView;
                  });
                },
              ),
            ],
          ),
          body: _showListView
              ? (mapMemories.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.location_off_rounded, size: 64, color: Colors.white24),
                            SizedBox(height: 16),
                            Text(
                              'No geotagged memories available.',
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: mapMemories.length,
                      itemBuilder: (context, index) {
                        final memory = mapMemories[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          color: const Color(0xFF1E1E2E),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: InkWell(
                            onTap: () => _showMemoryDetailsSheet(context, memory),
                            borderRadius: BorderRadius.circular(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                  child: AspectRatio(
                                    aspectRatio: 16 / 9,
                                    child: MemoryImageWidget(
                                      imageUrl: memory.imageUrl,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        memory.caption,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 16),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${memory.latitude!.toStringAsFixed(4)}, ${memory.longitude!.toStringAsFixed(4)}',
                                            style: const TextStyle(color: Colors.white60, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ))
              : Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: centerLatLng,
                        zoom: initialZoom,
                      ),
                      markers: markers,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      zoomControlsEnabled: true,
                      mapToolbarEnabled: true,
                      onMapCreated: (controller) {
                        _mapController = controller;
                      },
                    ),
                    if (mapMemories.isEmpty)
                      Positioned(
                        bottom: 24,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E2E).withOpacity(0.95),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, color: Color(0xFF818CF8)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  memories.isEmpty
                                      ? 'No photo memories found. Go to Trip Details -> Memories to upload a photo and tag it with GPS.'
                                      : 'None of your photo memories have location tags saved. Try uploading a new memory with location permission enabled.',
                                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }

  /// Renders a beautiful modal card overlay on marker click showing memory details.
  void _showMemoryDetailsSheet(BuildContext context, Memory memory) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: MemoryImageWidget(
                      imageUrl: memory.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memory.caption,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, color: Colors.white38, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Captured on: ${DateFormat('yyyy-MM-dd HH:mm').format(memory.dateAdded)}',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: Color(0xFF818CF8), size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Coordinates: ${memory.latitude!.toStringAsFixed(6)}, ${memory.longitude!.toStringAsFixed(6)}',
                          style: const TextStyle(color: Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
