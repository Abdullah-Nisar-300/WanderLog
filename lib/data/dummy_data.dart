// dummy_data.dart
// Provides high-quality dummy data and mock state management for WanderLog.

import '../models/models.dart';

class DummyData {
  // Current active user (falls back to default if not set)
  static Map<String, String> get userProfile => _currentUser ?? _defaultUser;

  static final Map<String, String> _defaultUser = {
    'name': 'Alex Wanderer',
    'email': 'alex@wanderlog.com',
    'avatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200&auto=format&fit=crop',
    'homeCurrency': 'USD',
  };

  static Map<String, String>? _currentUser;

  // Mock list of registered users in static memory
  static final List<Map<String, String>> registeredUsers = [
    {
      'name': 'Alex Wanderer',
      'email': 'alex@wanderlog.com',
      'password': 'password123',
      'avatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200&auto=format&fit=crop',
      'homeCurrency': 'USD',
    }
  ];

  static void setCurrentUser(Map<String, String>? user) {
    _currentUser = user;
  }

  // Attempt login using email and password
  static bool login(String email, String password) {
    final cleanEmail = email.trim().toLowerCase();
    for (var user in registeredUsers) {
      if (user['email']?.toLowerCase() == cleanEmail && user['password'] == password) {
        _currentUser = user;
        return true;
      }
    }
    return false;
  }

  // Attempt user registration
  static bool register(String name, String email, String password, {String? avatar}) {
    final cleanEmail = email.trim().toLowerCase();
    for (var user in registeredUsers) {
      if (user['email']?.toLowerCase() == cleanEmail) {
        return false; // Email already taken
      }
    }
    final newUser = {
      'name': name.trim(),
      'email': cleanEmail,
      'password': password,
      'avatar': avatar ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200&auto=format&fit=crop',
      'homeCurrency': 'USD',
    };
    registeredUsers.add(newUser);
    _currentUser = newUser;
    return true;
  }

  // Mock Trips list
  static List<Trip> trips = [
    Trip(
      id: 'trip_1',
      name: 'Parisian Spring Getaway',
      coverImageUrl: 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=800&auto=format&fit=crop',
      startDate: DateTime.now().add(const Duration(days: 10)),
      endDate: DateTime.now().add(const Duration(days: 15)),
      budget: 3500.0,
      activities: [
        Activity(
          id: 'act_1',
          time: DateTime(2026, 5, 10, 10, 00),
          title: 'Eiffel Tower Summit Tour',
          description: 'Guided tour to the peak of Eiffel Tower. View the scenic Parisian skyline.',
        ),
        Activity(
          id: 'act_2',
          time: DateTime(2026, 5, 11, 14, 30),
          title: 'Louvre Museum Walkthrough',
          description: 'See the Mona Lisa, Winged Victory, and ancient relics.',
        ),
        Activity(
          id: 'act_3',
          time: DateTime(2026, 5, 12, 19, 00),
          title: 'Seine River Dinner Cruise',
          description: 'A 3-course dinner cruise floating past illuminated monuments.',
        ),
      ],
      expenses: [
        Expense(
          id: 'exp_1',
          amount: 1200.0,
          currency: 'EUR',
          category: ExpenseCategory.stay,
          description: 'Boutique Hotel in Marais (5 Nights)',
          date: DateTime.now().add(const Duration(days: 10)),
        ),
        Expense(
          id: 'exp_2',
          amount: 250.0,
          currency: 'EUR',
          category: ExpenseCategory.transport,
          description: 'TGV Train from London to Paris',
          date: DateTime.now().add(const Duration(days: 10)),
        ),
        Expense(
          id: 'exp_3',
          amount: 85.0,
          currency: 'EUR',
          category: ExpenseCategory.food,
          description: 'Dinner at Le Comptoir du Relais',
          date: DateTime.now().add(const Duration(days: 11)),
        ),
        Expense(
          id: 'exp_4',
          amount: 45.0,
          currency: 'EUR',
          category: ExpenseCategory.other,
          description: 'Eiffel Tower Tickets',
          date: DateTime.now().add(const Duration(days: 10)),
        ),
      ],
      memories: [
        Memory(
          id: 'mem_1',
          imageUrl: 'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?w=600&auto=format&fit=crop',
          caption: 'Strolling around the Louvre under the golden afternoon sun.',
          dateAdded: DateTime.now().add(const Duration(days: 11)),
        ),
        Memory(
          id: 'mem_2',
          imageUrl: 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=600&auto=format&fit=crop',
          caption: 'Waking up to Eiffel views from our tiny balcony.',
          dateAdded: DateTime.now().add(const Duration(days: 12)),
        ),
      ],
      packingList: [
        PackingItem(id: 'pack_1', name: 'Passport & Travel Documents', isPacked: true),
        PackingItem(id: 'pack_2', name: 'Euro Adapter Plug', isPacked: true),
        PackingItem(id: 'pack_3', name: 'Comfortable Walking Shoes', isPacked: false),
        PackingItem(id: 'pack_4', name: 'Rain Jacket / Umbrella', isPacked: false),
        PackingItem(id: 'pack_5', name: 'French Phrase Book', isPacked: false),
      ],
    ),
    Trip(
      id: 'trip_2',
      name: 'Tokyo Neon & Temples',
      coverImageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=800&auto=format&fit=crop',
      startDate: DateTime.now().add(const Duration(days: 45)),
      endDate: DateTime.now().add(const Duration(days: 52)),
      budget: 5000.0,
      activities: [
        Activity(
          id: 'act_4',
          time: DateTime(2026, 6, 15, 9, 30),
          title: 'Senso-ji Temple Visit',
          description: 'Exploring Tokyo’s oldest and most iconic Buddhist temple in Asakusa.',
        ),
        Activity(
          id: 'act_5',
          time: DateTime(2026, 6, 16, 18, 00),
          title: 'Shinjuku Robot & Neon Tour',
          description: 'Walking the narrow alleys of Omoide Yokocho and Golden Gai.',
        ),
      ],
      expenses: [
        Expense(
          id: 'exp_5',
          amount: 1800.0,
          currency: 'JPY',
          category: ExpenseCategory.stay,
          description: 'Capsule & Luxury Ryokan Mix',
          date: DateTime.now().add(const Duration(days: 45)),
        ),
        Expense(
          id: 'exp_6',
          amount: 120.0,
          currency: 'JPY',
          category: ExpenseCategory.food,
          description: 'Sushi dinner in Tsukiji Outer Market',
          date: DateTime.now().add(const Duration(days: 46)),
        ),
      ],
      memories: [
        Memory(
          id: 'mem_3',
          imageUrl: 'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?w=600&auto=format&fit=crop',
          caption: 'Neon lights flashing at Shinjuku Crossing.',
          dateAdded: DateTime.now().add(const Duration(days: 46)),
        ),
      ],
      packingList: [
        PackingItem(id: 'pack_6', name: 'Japan Rail Pass (Digital)', isPacked: true),
        PackingItem(id: 'pack_7', name: 'Pocket Wi-Fi Booking', isPacked: true),
        PackingItem(id: 'pack_8', name: 'Slip-on Shoes (for shrines)', isPacked: false),
      ],
    ),
    Trip(
      id: 'trip_3',
      name: 'Swiss Alps Hiking Adventure',
      coverImageUrl: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&auto=format&fit=crop',
      startDate: DateTime.now().subtract(const Duration(days: 5)),
      endDate: DateTime.now().add(const Duration(days: 2)),
      budget: 4000.0,
      activities: [
        Activity(
          id: 'act_6',
          time: DateTime(2026, 6, 27, 8, 00),
          title: 'Matterhorn Glacier Trail',
          description: 'Scenic hiking trail starting at Trockener Steg down to Zermatt.',
        ),
      ],
      expenses: [
        Expense(
          id: 'exp_7',
          amount: 1500.0,
          currency: 'CHF',
          category: ExpenseCategory.stay,
          description: 'Alpine Lodge in Zermatt',
          date: DateTime.now().subtract(const Duration(days: 4)),
        ),
        Expense(
          id: 'exp_8',
          amount: 90.0,
          currency: 'CHF',
          category: ExpenseCategory.food,
          description: 'Traditional cheese fondue feast',
          date: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ],
      memories: [
        Memory(
          id: 'mem_4',
          imageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=600&auto=format&fit=crop',
          caption: 'Incredible vistas looking out over Zermatt.',
          dateAdded: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ],
      packingList: [
        PackingItem(id: 'pack_9', name: 'Hiking Poles & Sturdy Boots', isPacked: true),
        PackingItem(id: 'pack_10', name: 'Thermal Base Layers', isPacked: true),
        PackingItem(id: 'pack_11', name: 'Swiss Travel Pass', isPacked: true),
        PackingItem(id: 'pack_12', name: 'Sunscreen & Lip Balm', isPacked: false),
      ],
    ),
  ];

  // Helper methods to simulate CRUD ops in static memory
  static void addTrip(Trip trip) {
    trips.add(trip);
  }

  static Trip getTripById(String id) {
    return trips.firstWhere((t) => t.id == id, orElse: () => trips[0]);
  }

  static void addExpense(String tripId, Expense expense) {
    int index = trips.indexWhere((t) => t.id == tripId);
    if (index != -1) {
      List<Expense> updatedExpenses = List.from(trips[index].expenses)..add(expense);
      trips[index] = trips[index].copyWith(expenses: updatedExpenses);
    }
  }

  static void addActivity(String tripId, Activity activity) {
    int index = trips.indexWhere((t) => t.id == tripId);
    if (index != -1) {
      List<Activity> updatedActivities = List.from(trips[index].activities)..add(activity);
      // Sort activities by time
      updatedActivities.sort((a, b) => a.time.compareTo(b.time));
      trips[index] = trips[index].copyWith(activities: updatedActivities);
    }
  }

  static void deleteMemory(String tripId, String memoryId) {
    int index = trips.indexWhere((t) => t.id == tripId);
    if (index != -1) {
      List<Memory> updatedMemories = List.from(trips[index].memories)
        ..removeWhere((m) => m.id == memoryId);
      trips[index] = trips[index].copyWith(memories: updatedMemories);
    }
  }

  static void addMemory(String tripId, Memory memory) {
    int index = trips.indexWhere((t) => t.id == tripId);
    if (index != -1) {
      List<Memory> updatedMemories = List.from(trips[index].memories)..add(memory);
      trips[index] = trips[index].copyWith(memories: updatedMemories);
    }
  }

  static void addPackingItem(String tripId, PackingItem item) {
    int index = trips.indexWhere((t) => t.id == tripId);
    if (index != -1) {
      List<PackingItem> updatedPackingList = List.from(trips[index].packingList)..add(item);
      trips[index] = trips[index].copyWith(packingList: updatedPackingList);
    }
  }

  static void togglePackingItem(String tripId, String itemId) {
    int index = trips.indexWhere((t) => t.id == tripId);
    if (index != -1) {
      List<PackingItem> updatedPackingList = trips[index].packingList.map((item) {
        if (item.id == itemId) {
          return item.copyWith(isPacked: !item.isPacked);
        }
        return item;
      }).toList();
      trips[index] = trips[index].copyWith(packingList: updatedPackingList);
    }
  }
}
