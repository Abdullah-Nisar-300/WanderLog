import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/dummy_data.dart';
import '../models/models.dart';
import '../routes/routes.dart';
import '../widgets/expense_tile.dart';
import '../widgets/memory_image_widget.dart';
import '../services/firestore_service.dart';
import '../services/currency_service.dart';
import '../utils/image_picker.dart';
import '../services/location_service.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../services/storage_service.dart';
import '../services/permission_service.dart';

class TripDetailsScreen extends StatefulWidget {
  const TripDetailsScreen({super.key});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  late String _tripId;
  bool _initialized = false;
  double _budgetAlertThreshold = 0.85; // Default alert when 85% of budget is spent

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      // Phase 2 Demo: Retrieving passed named route argument
      _tripId = ModalRoute.of(context)!.settings.arguments as String;
      _initialized = true;
    }
  }

  void _refreshState() {
    setState(() {});
  }

  void _showDeleteTripConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          title: const Text('Delete Adventure?', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Are you sure you want to delete this trip and all its associated expenses and memories? This cannot be undone.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(context); // close dialog
                try {
                  await FirestoreService.instance.deleteTrip(_tripId);
                  if (mounted) {
                    Navigator.pop(context); // close trip details page
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Trip deleted successfully.')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete trip: $e'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteExpenseConfirmation(Expense expense) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          title: const Text('Delete Expense?', style: TextStyle(color: Colors.white)),
          content: Text(
            'Are you sure you want to delete this expense of ${expense.currency} ${expense.amount.toStringAsFixed(2)}? This cannot be undone.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(context); // close dialog
                try {
                  await FirestoreService.instance.deleteExpense(_tripId, expense.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Expense deleted successfully.')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete expense: $e'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                'Error loading trip details: ${snapshot.error}',
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

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  if (trip.startingPoint.isNotEmpty)
                    Text(
                      'From ${trip.startingPoint}',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                ],
              ),
              actions: [
                // Trip Map action button
                IconButton(
                  tooltip: 'Trip Map',
                  icon: const Icon(Icons.map_rounded, color: Color(0xFF818CF8)),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      Routes.tripMap,
                      arguments: _tripId,
                    );
                  },
                ),
                // Packing list action button
                IconButton(
                  tooltip: 'Packing List',
                  icon: const Icon(Icons.backpack_rounded, color: Color(0xFF818CF8)),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      Routes.packingList,
                      arguments: _tripId,
                    ).then((_) => _refreshState());
                  },
                ),
                // Delete trip action button
                IconButton(
                  tooltip: 'Delete Trip',
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  onPressed: () => _showDeleteTripConfirmation(context),
                ),
              ],
              bottom: const TabBar(
                indicatorColor: Color(0xFF818CF8),
                labelColor: Color(0xFF818CF8),
                unselectedLabelColor: Colors.white60,
                tabs: [
                  Tab(icon: Icon(Icons.calendar_today_rounded), text: 'Itinerary'),
                  Tab(icon: Icon(Icons.attach_money_rounded), text: 'Expenses'),
                  Tab(icon: Icon(Icons.photo_library_rounded), text: 'Memories'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildItineraryTab(trip),
                _buildExpensesTab(trip),
                _buildMemoriesTab(trip),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // ITINERARY TAB
  // ==========================================
  Widget _buildItineraryTab(Trip trip) {
    final activities = trip.activities;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_activity_fab',
        onPressed: () => _showAddActivityDialog(trip),
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.add_task_rounded, color: Colors.white),
      ),
      body: activities.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.event_note_rounded, size: 64, color: Colors.white24),
                  const SizedBox(height: 12),
                  const Text('No plans logged yet', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                  const SizedBox(height: 6),
                  ElevatedButton.icon(
                    onPressed: () => _showAddActivityDialog(trip),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Activity'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1).withOpacity(0.2),
                      foregroundColor: const Color(0xFF818CF8),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];
                final timeFormat = DateFormat('jm');

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.2),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.white10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              timeFormat.format(activity.time),
                              style: const TextStyle(
                                color: Color(0xFF818CF8),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Day ${activity.time.difference(trip.startDate).inDays + 1}',
                                style: const TextStyle(fontSize: 10, color: Colors.white60),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          activity.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (activity.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            activity.description,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white54,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showAddActivityDialog(Trip trip) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    TimeOfDay? selectedTime = TimeOfDay.now();
    DateTime selectedDate = trip.startDate;

    final dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Activity'),
              content: SingleChildScrollView(
                child: Form(
                  key: dialogFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Date Picker Button inside dialog
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_month, color: Color(0xFF818CF8)),
                        title: const Text('Select Activity Day', style: TextStyle(fontSize: 13, color: Colors.white60)),
                        subtitle: Text(
                          DateFormat('yyyy-MM-dd').format(selectedDate),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: trip.startDate,
                            lastDate: trip.endDate,
                          );
                          if (picked != null) {
                            setDialogState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                      ),
                      const Divider(color: Colors.white10),

                      // Time Picker Button inside dialog
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.access_time_rounded, color: Color(0xFF818CF8)),
                        title: const Text('Select Time', style: TextStyle(fontSize: 13, color: Colors.white60)),
                        subtitle: Text(
                          selectedTime!.format(context),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        onTap: () async {
                          // Time Picker used here for Itinerary
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: selectedTime!,
                          );
                          if (picked != null) {
                            setDialogState(() {
                              selectedTime = picked;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: titleController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Activity Title',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF818CF8))),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: descController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Description (Optional)',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF818CF8))),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (dialogFormKey.currentState!.validate()) {
                      final timeDateTime = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTime!.hour,
                        selectedTime!.minute,
                      );

                      final newActivity = Activity(
                        id: 'act_${DateTime.now().millisecondsSinceEpoch}',
                        time: timeDateTime,
                        title: titleController.text.trim(),
                        description: descController.text.trim(),
                      );

                      try {
                        final updatedActivities = List<Activity>.from(trip.activities)..add(newActivity);
                        final serializedActivities = updatedActivities.map((a) => a.toFirestore()).toList();
                        await FirestoreService.instance.updateTrip(trip.id, {'activities': serializedActivities});
                        
                        if (context.mounted) {
                          Navigator.pop(context); // Close Dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Activity added to itinerary!')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to add activity: $e'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==========================================
  // EXPENSES TAB
  // ==========================================
  Widget _buildExpensesTab(Trip trip) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirestoreService.instance.getUserStream(user?.uid ?? ''),
      builder: (context, userSnapshot) {
        final userData = (userSnapshot.hasData && userSnapshot.data!.data() != null)
            ? userSnapshot.data!.data()!
            : {};
        final targetCurrency = userData['homeCurrency'] as String? ?? DummyData.userProfile['homeCurrency'] ?? 'USD';

        return StreamBuilder<List<Expense>>(
          stream: FirestoreService.instance.getExpensesStream(trip.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF6366F1),
                ),
              );
            }

            final expensesList = snapshot.data ?? [];
            final totalSpent = expensesList.fold(0.0, (sum, item) {
              return sum + CurrencyService.instance.convert(item.amount, item.currency, targetCurrency);
            });
            final convertedBudget = CurrencyService.instance.convert(trip.budget, 'USD', targetCurrency);
            final budgetFraction = convertedBudget > 0 ? (totalSpent / convertedBudget).clamp(0.0, 1.0) : 0.0;
            final isBudgetExceeded = totalSpent >= (convertedBudget * _budgetAlertThreshold);

            final formattedSpent = CurrencyService.instance.format(totalSpent, targetCurrency, decimals: 2);
            final formattedBudget = CurrencyService.instance.format(convertedBudget, targetCurrency, decimals: 0);

            return Scaffold(
              floatingActionButton: FloatingActionButton(
                heroTag: 'add_expense_fab',
                onPressed: () => _showAddExpenseBottomSheet(trip),
                backgroundColor: const Color(0xFF6366F1),
                child: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
              ),
              body: Column(
                children: [
                  // Budget Health Panel
                  Card(
                    margin: const EdgeInsets.all(16.0),
                    elevation: 0,
                    color: isBudgetExceeded ? Colors.redAccent.withOpacity(0.1) : const Color(0xFF6366F1).withOpacity(0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isBudgetExceeded ? Colors.redAccent.withOpacity(0.3) : const Color(0xFF6366F1).withOpacity(0.2),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Total Expenses Logged', style: TextStyle(fontSize: 12, color: Colors.white60)),
                                  const SizedBox(height: 4),
                                  Text(
                                    formattedSpent,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: isBudgetExceeded ? Colors.redAccent : Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Limit / Budget', style: TextStyle(fontSize: 12, color: Colors.white60)),
                                  const SizedBox(height: 4),
                                  Text(
                                    formattedBudget,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                      const SizedBox(height: 16),
                      
                      // LinearProgressIndicator used to show budget depletion
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: budgetFraction,
                          minHeight: 8,
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            budgetFraction > _budgetAlertThreshold ? Colors.redAccent : const Color(0xFF818CF8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Alert threshold control slider
                      Row(
                        children: [
                          const Icon(Icons.notification_important_outlined, size: 14, color: Colors.white60),
                          const SizedBox(width: 6),
                          Text(
                            'Budget Warning Alert at: ${(_budgetAlertThreshold * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(fontSize: 11, color: Colors.white60),
                          ),
                          Expanded(
                            child: Slider(
                              value: _budgetAlertThreshold,
                              min: 0.5,
                              max: 1.0,
                              divisions: 10,
                              activeColor: const Color(0xFF818CF8),
                              inactiveColor: Colors.white12,
                              onChanged: (value) {
                                setState(() {
                                  _budgetAlertThreshold = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Expenses List
              Expanded(
                child: expensesList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.receipt_long_rounded, size: 48, color: Colors.white24),
                            const SizedBox(height: 12),
                            const Text('No expenditures recorded yet', style: TextStyle(color: Colors.white54)),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () => _showAddExpenseBottomSheet(trip),
                              icon: const Icon(Icons.add_card_rounded),
                              label: const Text('Add Expense'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: expensesList.length,
                        itemBuilder: (context, index) {
                          final expense = expensesList[index];
                          return ExpenseTile(
                            expense: expense,
                            onTap: () => _showDeleteExpenseConfirmation(expense),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  },
);
}

  void _showAddExpenseBottomSheet(Trip trip) {
    final amountController = TextEditingController();
    final descController = TextEditingController();
    String selectedCurrency = DummyData.userProfile['homeCurrency'] ?? 'USD';
    ExpenseCategory selectedCategory = ExpenseCategory.food;

    final sheetFormKey = GlobalKey<FormState>();

    // Bottom Sheet Quick Add Expense
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            String sheetPrefixText = '\$ ';
            if (selectedCurrency == 'PKR') {
              sheetPrefixText = 'Rs ';
            } else if (selectedCurrency == 'EUR') {
              sheetPrefixText = '€ ';
            } else if (selectedCurrency == 'JPY') {
              sheetPrefixText = '¥ ';
            } else if (selectedCurrency == 'CHF') {
              sheetPrefixText = 'Fr ';
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 24,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: sheetFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Quick Add Expense',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(context),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Amount and Currency Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Amount',
                                prefixText: sheetPrefixText,
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF818CF8))),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Invalid amount';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: selectedCurrency,
                              dropdownColor: const Color(0xFF1E1E2E),
                              decoration: InputDecoration(
                                labelText: 'Currency',
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF818CF8))),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'USD', child: Text('USD (\$)', style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: 'EUR', child: Text('EUR (€)', style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: 'JPY', child: Text('JPY (¥)', style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: 'CHF', child: Text('CHF (Fr)', style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: 'PKR', child: Text('PKR (Rs)', style: TextStyle(fontSize: 13))),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setSheetState(() {
                                    selectedCurrency = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Radio buttons for category
                      const Text('Category', style: TextStyle(fontSize: 13, color: Colors.white60)),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Radio<ExpenseCategory>(
                                  value: ExpenseCategory.food,
                                  groupValue: selectedCategory,
                                  activeColor: const Color(0xFF818CF8),
                                  onChanged: (value) {
                                    setSheetState(() => selectedCategory = value!);
                                  },
                                ),
                                const Text('Food', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Radio<ExpenseCategory>(
                                  value: ExpenseCategory.stay,
                                  groupValue: selectedCategory,
                                  activeColor: const Color(0xFF818CF8),
                                  onChanged: (value) {
                                    setSheetState(() => selectedCategory = value!);
                                  },
                                ),
                                const Text('Stay', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Radio<ExpenseCategory>(
                                  value: ExpenseCategory.transport,
                                  groupValue: selectedCategory,
                                  activeColor: const Color(0xFF818CF8),
                                  onChanged: (value) {
                                    setSheetState(() => selectedCategory = value!);
                                  },
                                ),
                                const Text('Transit', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: descController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Description / Location',
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF818CF8))),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 28),

                      ElevatedButton(
                        onPressed: () async {
                          if (sheetFormKey.currentState!.validate()) {
                            final newExpense = Expense(
                              id: '', // Generated by Firestore
                              amount: double.parse(amountController.text.trim()),
                              currency: selectedCurrency,
                              category: selectedCategory,
                              description: descController.text.trim(),
                              date: DateTime.now(),
                            );

                            try {
                              await FirestoreService.instance.addExpense(trip.id, newExpense);
                              if (context.mounted) {
                                Navigator.pop(context); // Pop Bottom Sheet
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Logged expense: $selectedCurrency ${newExpense.amount.toStringAsFixed(2)}',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to save expense: $e'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        child: const Text('Save Expense', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // MEMORIES TAB
  // ==========================================
  Widget _buildMemoriesTab(Trip trip) {
    return StreamBuilder<List<Memory>>(
      stream: FirestoreService.instance.getMemoriesStream(trip.id),
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
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  Text(
                    'Error loading memories: ${snapshot.error}',
                    style: const TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final memories = snapshot.data ?? [];

        return Scaffold(
          floatingActionButton: FloatingActionButton(
            heroTag: 'add_memory_fab',
            onPressed: () => _selectImageSourceAndPick(trip),
            backgroundColor: const Color(0xFF6366F1),
            child: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
          ),
          body: memories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.no_photography_rounded, size: 64, color: Colors.white24),
                      const SizedBox(height: 12),
                      const Text('No photos in this log yet', style: TextStyle(color: Colors.white54)),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _selectImageSourceAndPick(trip),
                        icon: const Icon(Icons.add_a_photo_rounded),
                        label: const Text('Add Memory Photo'),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: memories.length,
                  itemBuilder: (context, index) {
                    final memory = memories[index];

                    return InkWell(
                      onTap: () => _previewMemoryDialog(trip, memory),
                      borderRadius: BorderRadius.circular(16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: MemoryImageWidget(
                          imageUrl: memory.imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  void _selectImageSourceAndPick(Trip trip) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E2E),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Select Photo Source',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF818CF8)),
                title: const Text('Take Photo', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickMemoryImage(trip, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF818CF8)),
                title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickMemoryImage(trip, ImageSource.gallery);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickMemoryImage(Trip trip, ImageSource source) async {
    if (source == ImageSource.camera) {
      final hasPermission = await PermissionService.instance.requestCameraPermission(context);
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera permission was denied. Cannot capture photo.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }

    try {
      final XFile? file = await ImagePicker().pickImage(source: source);
      if (file == null) return; // cancelled gracefully

      if (mounted) {
        _showAddMemoryDialog(trip, file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking photo: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAddMemoryDialog(Trip trip, XFile initialFile) {
    final captionController = TextEditingController();
    XFile? selectedFile = initialFile;
    
    double? latitude;
    double? longitude;
    bool fetchingLocation = false;
    String locationStatus = 'Waiting to fetch location...';
    bool locationFetched = false;
    bool locationFailed = false;
    bool hasInitiatedLocation = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (!hasInitiatedLocation) {
              hasInitiatedLocation = true;
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                setDialogState(() {
                  fetchingLocation = true;
                  locationStatus = 'Fetching location...';
                });
                final position = await LocationService.instance.getCurrentLocation(context);
                if (position != null) {
                  setDialogState(() {
                    latitude = position.latitude;
                    longitude = position.longitude;
                    fetchingLocation = false;
                    locationFetched = true;
                    locationStatus = 'Location: (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
                  });
                } else {
                  setDialogState(() {
                    fetchingLocation = false;
                    locationFailed = true;
                    locationStatus = 'Failed to acquire location';
                  });
                }
              });
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E2E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Add Memory Photo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Photo Preview
                    if (selectedFile != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AspectRatio(
                              aspectRatio: 16 / 10,
                              child: kIsWeb
                                  ? Image.network(selectedFile!.path, fit: BoxFit.cover)
                                  : Image.file(File(selectedFile!.path), fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                                tooltip: 'Reselect photo',
                                onPressed: () async {
                                  // Reselect flow
                                  final XFile? file = await ImagePicker().pickImage(source: ImageSource.gallery);
                                  if (file != null) {
                                    setDialogState(() {
                                      selectedFile = file;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: captionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Caption description',
                        labelStyle: const TextStyle(color: Colors.white60),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF818CF8))),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Location status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151522),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: fetchingLocation
                              ? const Color(0xFF818CF8).withOpacity(0.3)
                              : locationFetched
                                  ? Colors.green.withOpacity(0.3)
                                  : locationFailed
                                      ? Colors.redAccent.withOpacity(0.3)
                                      : Colors.white12,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (fetchingLocation)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF818CF8),
                              ),
                            )
                          else if (locationFetched)
                            const Icon(Icons.location_on_rounded, color: Colors.green, size: 18)
                          else if (locationFailed)
                            const Icon(Icons.location_off_rounded, color: Colors.redAccent, size: 18)
                          else
                            const Icon(Icons.location_on_outlined, color: Colors.white30, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              locationStatus,
                              style: TextStyle(
                                color: fetchingLocation
                                    ? const Color(0xFF818CF8)
                                    : locationFetched
                                        ? Colors.greenAccent
                                        : locationFailed
                                            ? Colors.redAccent
                                            : Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedFile == null) return;
                    Navigator.pop(context);

                    // Show SnackBar Progress Indicator
                    final messenger = ScaffoldMessenger.of(context);
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 16),
                            Text('Uploading and saving memory photo...'),
                          ],
                        ),
                        duration: Duration(seconds: 15),
                      ),
                    );

                    try {
                      // 1. Upload to Firebase Storage
                      final downloadUrl = await StorageService.instance.uploadTripImage(trip.id, selectedFile!);

                      // 2. Save Memory document to Firestore (with location fallback)
                      final newMemory = Memory(
                        id: '',
                        imageUrl: downloadUrl,
                        caption: captionController.text.trim().isNotEmpty
                            ? captionController.text.trim()
                            : 'Scenic vacation memory',
                        dateAdded: DateTime.now(),
                        latitude: latitude ?? 33.9070,
                        longitude: longitude ?? 73.3903,
                      );

                      await FirestoreService.instance.addMemory(trip.id, newMemory);

                      if (mounted) {
                        messenger.hideCurrentSnackBar();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Memory photo added successfully!'),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        messenger.hideCurrentSnackBar();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Failed to save memory: $e'),
                            backgroundColor: Colors.redAccent,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Upload Photo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _previewMemoryDialog(Trip trip, Memory memory) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: MemoryImageWidget(
                  imageUrl: memory.imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memory.caption,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Added on: ${DateFormat('yyyy-MM-dd HH:mm').format(memory.dateAdded)}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close', style: TextStyle(color: Colors.white38)),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context); // Close preview dialog
                            _showDeleteConfirmation(trip, memory);
                          },
                          icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 18),
                          label: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(Trip trip, Memory memory) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          title: const Text('Delete Photo?', style: TextStyle(color: Colors.white)),
          content: const Text('Are you sure you want to delete this memory? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              onPressed: () async {
                try {
                  await FirestoreService.instance.deleteMemory(trip.id, memory.id);
                  if (context.mounted) {
                    Navigator.pop(context); // Close confirm dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Memory deleted.')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete memory: $e'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
