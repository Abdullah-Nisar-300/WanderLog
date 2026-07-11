// packing_list_screen.dart
// Interactive checklist tracking trip essentials with item creation textfields connected to Firestore.

import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/firestore_service.dart';

class PackingListScreen extends StatefulWidget {
  const PackingListScreen({super.key});

  @override
  State<PackingListScreen> createState() => _PackingListScreenState();
}

class _PackingListScreenState extends State<PackingListScreen> {
  late String _tripId;
  bool _initialized = false;
  final _inputController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _tripId = ModalRoute.of(context)!.settings.arguments as String;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _addNewItem(Trip trip) async {
    final name = _inputController.text.trim();
    if (name.isEmpty) return;

    final newItem = PackingItem(
      id: 'pack_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      isPacked: false,
    );

    try {
      final updatedList = List<PackingItem>.from(trip.packingList)..add(newItem);
      final serializedList = updatedList.map((item) => item.toFirestore()).toList();
      await FirestoreService.instance.updateTrip(trip.id, {'packingList': serializedList});
      _inputController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "$name" to checklist'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add item: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _toggleItem(Trip trip, String itemId, bool currentStatus) async {
    try {
      final updatedList = trip.packingList.map((item) {
        if (item.id == itemId) {
          return PackingItem(id: item.id, name: item.name, isPacked: !currentStatus);
        }
        return item;
      }).toList();
      final serializedList = updatedList.map((item) => item.toFirestore()).toList();
      await FirestoreService.instance.updateTrip(trip.id, {'packingList': serializedList});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update item: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isTablet = mediaQuery.size.width > 600;

    return StreamBuilder<Trip>(
      stream: FirestoreService.instance.getTripDocStream(_tripId),
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
            body: Center(
              child: Text(
                'Error loading checklist: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: Text('Trip not found')),
          );
        }

        final trip = snapshot.data!;
        final packingList = trip.packingList;

        // Calculate packing progress metrics
        final totalItems = packingList.length;
        final packedItems = packingList.where((item) => item.isPacked).length;
        final packedFraction = totalItems > 0 ? (packedItems / totalItems) : 0.0;

        return Scaffold(
          appBar: AppBar(
            title: Text('Checklist: ${trip.name}'),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Packing Progress Card
                Card(
                  margin: const EdgeInsets.all(16.0),
                  elevation: 0,
                  color: const Color(0xFF6366F1).withOpacity(0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: const Color(0xFF6366F1).withOpacity(0.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Packing Progress',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              '$packedItems of $totalItems packed',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF818CF8),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: packedFraction,
                            minHeight: 8,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF818CF8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Checklist list items
                Expanded(
                  child: packingList.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.checklist_rtl_rounded, size: 64, color: Colors.white24),
                              SizedBox(height: 12),
                              Text('Your packing list is empty', style: TextStyle(color: Colors.white54)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? mediaQuery.size.width * 0.15 : 16.0,
                          ),
                          itemCount: packingList.length,
                          itemBuilder: (context, index) {
                            final item = packingList[index];

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              elevation: 0,
                              color: item.isPacked
                                  ? Colors.white.withOpacity(0.02)
                                  : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                              child: CheckboxListTile(
                                title: Text(
                                  item.name,
                                  style: TextStyle(
                                    decoration: item.isPacked ? TextDecoration.lineThrough : null,
                                    color: item.isPacked ? Colors.white30 : Colors.white,
                                    fontWeight: item.isPacked ? FontWeight.normal : FontWeight.bold,
                                  ),
                                ),
                                value: item.isPacked,
                                activeColor: const Color(0xFF6366F1),
                                checkColor: Colors.white,
                                onChanged: (bool? checked) {
                                  _toggleItem(trip, item.id, item.isPacked);
                                },
                              ),
                            );
                          },
                        ),
                ),

                // Bottom Input Panel to add items
                Padding(
                  padding: EdgeInsets.only(
                    bottom: mediaQuery.viewInsets.bottom + 16,
                    top: 8,
                    left: 16,
                    right: 16,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _inputController,
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                            decoration: const InputDecoration(
                              hintText: 'Add packing item...',
                              hintStyle: TextStyle(color: Colors.white38),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _addNewItem(trip),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_rounded, color: Color(0xFF818CF8), size: 28),
                          onPressed: () => _addNewItem(trip),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
