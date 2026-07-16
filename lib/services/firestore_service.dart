// firestore_service.dart
// Centralized service handling all CRUD interactions with Firestore collections and subcollections.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Static shared instance
  static final FirestoreService instance = FirestoreService._internal();
  FirestoreService._internal();

  // ==========================================
  // USER PROFILE METHODS
  // ==========================================

  // Create a user document upon signup
  Future<void> createUserDocument({
    required String uid,
    required String name,
    required String email,
    required String avatar,
  }) async {
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'avatar': avatar,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Stream current user profile data
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  // Update user profile properties (like name or avatar)
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  // ==========================================
  // TRIP CRUD METHODS
  // ==========================================

  // Create a new Trip
  Future<void> addTrip(Trip trip, String ownerId) async {
    await _db.collection('trips').add(trip.toFirestore(ownerId));
  }

  // Read Trips for a specific owner ordered by creation date descending (in-memory sort to avoid requiring composite indexes)
  Stream<List<Trip>> getTripsStream(String ownerId) {
    return _db
        .collection('trips')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
      final trips = snapshot.docs.map((doc) {
        return _TripWithCreatedAt(
          trip: Trip.fromFirestore(doc.id, doc.data()),
          createdAt: doc.data()['createdAt'],
        );
      }).toList();

      trips.sort((a, b) {
        final aTime = _parseCreatedAt(a.createdAt);
        final bTime = _parseCreatedAt(b.createdAt);
        return bTime.compareTo(aTime);
      });

      return trips.map((t) => t.trip).toList();
    });
  }

  DateTime _parseCreatedAt(dynamic createdAt) {
    if (createdAt == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (createdAt is String) {
      return DateTime.tryParse(createdAt) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    if (createdAt is Timestamp) {
      return createdAt.toDate();
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  // Read a single Trip document
  Stream<Trip> getTripDocStream(String tripId) {
    return _db.collection('trips').doc(tripId).snapshots().map((doc) {
      return Trip.fromFirestore(doc.id, doc.data() ?? {});
    });
  }

  // Update a Trip
  Future<void> updateTrip(String tripId, Map<String, dynamic> data) async {
    await _db.collection('trips').doc(tripId).update(data);
  }

  // Delete a Trip with cascade deletion (removes subcollections of expenses and memories)
  Future<void> deleteTrip(String tripId) async {
    final expenses = await _db.collection('trips').doc(tripId).collection('expenses').get();
    final memories = await _db.collection('trips').doc(tripId).collection('memories').get();

    final batch = _db.batch();

    // Loop and stage deletions of subcollection items in the batch
    for (var doc in expenses.docs) {
      batch.delete(doc.reference);
    }
    for (var doc in memories.docs) {
      batch.delete(doc.reference);
    }

    // Delete the root trip document
    batch.delete(_db.collection('trips').doc(tripId));

    await batch.commit();
  }

  // ==========================================
  // EXPENSE SUBCOLLECTION CRUD METHODS
  // ==========================================

  // Add expense to trip
  Future<void> addExpense(String tripId, Expense expense) async {
    await _db
        .collection('trips')
        .doc(tripId)
        .collection('expenses')
        .add(expense.toFirestore());
  }

  // Read expenses in real time ordered by date/createdAt descending
  Stream<List<Expense>> getExpensesStream(String tripId) {
    return _db
        .collection('trips')
        .doc(tripId)
        .collection('expenses')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Expense.fromFirestore(doc.id, doc.data());
      }).toList();
    });
  }

  // Delete an expense
  Future<void> deleteExpense(String tripId, String expenseId) async {
    await _db
        .collection('trips')
        .doc(tripId)
        .collection('expenses')
        .doc(expenseId)
        .delete();
  }

  // ==========================================
  // MEMORY SUBCOLLECTION CRUD METHODS
  // ==========================================

  // Add photo memory to trip
  Future<void> addMemory(String tripId, Memory memory) async {
    await _db
        .collection('trips')
        .doc(tripId)
        .collection('memories')
        .add(memory.toFirestore());
  }

  // Read memories in real time
  Stream<List<Memory>> getMemoriesStream(String tripId) {
    return _db
        .collection('trips')
        .doc(tripId)
        .collection('memories')
        .orderBy('dateAdded', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Memory.fromFirestore(doc.id, doc.data());
      }).toList();
    });
  }

  // Delete a memory
  Future<void> deleteMemory(String tripId, String memoryId) async {
    await _db
        .collection('trips')
        .doc(tripId)
        .collection('memories')
        .doc(memoryId)
        .delete();
  }
}

class _TripWithCreatedAt {
  final Trip trip;
  final dynamic createdAt;

  _TripWithCreatedAt({
    required this.trip,
    required this.createdAt,
  });
}
