// models.dart
// Holds typed representations of WanderLog entities: Trip, Activity, Expense, Memory, and PackingItem.

enum ExpenseCategory {
  food,
  stay,
  transport,
  other,
}

extension ExpenseCategoryExtension on ExpenseCategory {
  String get displayName {
    switch (this) {
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.stay:
        return 'Stay';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.other:
        return 'Other';
    }
  }
}

class Activity {
  final String id;
  final DateTime time; // Represents the time (hour/minute) of the activity
  final String title;
  final String description;

  Activity({
    required this.id,
    required this.time,
    required this.title,
    required this.description,
  });

  Activity copyWith({
    String? id,
    DateTime? time,
    String? title,
    String? description,
  }) {
    return Activity(
      id: id ?? this.id,
      time: time ?? this.time,
      title: title ?? this.title,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'time': time.toIso8601String(),
      'title': title,
      'description': description,
    };
  }

  factory Activity.fromFirestore(Map<String, dynamic> map) {
    return Activity(
      id: map['id'] ?? '',
      time: DateTime.tryParse(map['time'] ?? '') ?? DateTime.now(),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
    );
  }
}

class Expense {
  final String id;
  final double amount;
  final String currency;
  final ExpenseCategory category;
  final String description;
  final DateTime date;

  Expense({
    required this.id,
    required this.amount,
    required this.currency,
    required this.category,
    required this.description,
    required this.date,
  });

  Expense copyWith({
    String? id,
    double? amount,
    String? currency,
    ExpenseCategory? category,
    String? description,
    DateTime? date,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'amount': amount,
      'currency': currency,
      'category': category.name,
      'description': description,
      'date': date.toIso8601String(),
    };
  }

  factory Expense.fromFirestore(String docId, Map<String, dynamic> map) {
    return Expense(
      id: docId,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'USD',
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ExpenseCategory.other,
      ),
      description: map['description'] ?? '',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
    );
  }
}

class Memory {
  final String id;
  final String imageUrl;
  final String caption;
  final DateTime dateAdded;
  final double? latitude;
  final double? longitude;

  Memory({
    required this.id,
    required this.imageUrl,
    required this.caption,
    required this.dateAdded,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'imageUrl': imageUrl,
      'caption': caption,
      'dateAdded': dateAdded.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Memory.fromFirestore(String docId, Map<String, dynamic> map) {
    return Memory(
      id: docId,
      imageUrl: map['imageUrl'] ?? '',
      caption: map['caption'] ?? '',
      dateAdded: DateTime.tryParse(map['dateAdded'] ?? '') ?? DateTime.now(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }
}

class PackingItem {
  final String id;
  final String name;
  final bool isPacked;

  PackingItem({
    required this.id,
    required this.name,
    required this.isPacked,
  });

  PackingItem copyWith({
    String? id,
    String? name,
    bool? isPacked,
  }) {
    return PackingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      isPacked: isPacked ?? this.isPacked,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'isPacked': isPacked,
    };
  }

  factory PackingItem.fromFirestore(Map<String, dynamic> map) {
    return PackingItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      isPacked: map['isPacked'] ?? false,
    );
  }
}

class Trip {
  final String id;
  final String name;
  final String coverImageUrl;
  final DateTime startDate;
  final DateTime endDate;
  final double budget;
  final List<Activity> activities;
  final List<Expense> expenses;
  final List<Memory> memories;
  final List<PackingItem> packingList;

  Trip({
    required this.id,
    required this.name,
    required this.coverImageUrl,
    required this.startDate,
    required this.endDate,
    required this.budget,
    this.activities = const [],
    this.expenses = const [],
    this.memories = const [],
    this.packingList = const [],
  });

  double get totalSpent {
    return expenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  Trip copyWith({
    String? id,
    String? name,
    String? coverImageUrl,
    DateTime? startDate,
    DateTime? endDate,
    double? budget,
    List<Activity>? activities,
    List<Expense>? expenses,
    List<Memory>? memories,
    List<PackingItem>? packingList,
  }) {
    return Trip(
      id: id ?? this.id,
      name: name ?? this.name,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      budget: budget ?? this.budget,
      activities: activities ?? this.activities,
      expenses: expenses ?? this.expenses,
      memories: memories ?? this.memories,
      packingList: packingList ?? this.packingList,
    );
  }

  Map<String, dynamic> toFirestore(String ownerId) {
    return {
      'ownerId': ownerId,
      'name': name,
      'coverImageUrl': coverImageUrl,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'budget': budget,
      'activities': activities.map((a) => a.toFirestore()).toList(),
      'packingList': packingList.map((p) => p.toFirestore()).toList(),
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  factory Trip.fromFirestore(String docId, Map<String, dynamic> map, {List<Expense> expenses = const [], List<Memory> memories = const []}) {
    return Trip(
      id: docId,
      name: map['name'] ?? '',
      coverImageUrl: map['coverImageUrl'] ?? '',
      startDate: DateTime.tryParse(map['startDate'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(map['endDate'] ?? '') ?? DateTime.now(),
      budget: (map['budget'] as num?)?.toDouble() ?? 0.0,
      activities: (map['activities'] as List?)
              ?.map((a) => Activity.fromFirestore(Map<String, dynamic>.from(a)))
              .toList() ??
          [],
      packingList: (map['packingList'] as List?)
              ?.map((p) => PackingItem.fromFirestore(Map<String, dynamic>.from(p)))
              .toList() ??
          [],
      expenses: expenses,
      memories: memories,
    );
  }
}
