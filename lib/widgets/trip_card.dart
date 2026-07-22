import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../data/dummy_data.dart';
import '../services/firestore_service.dart';
import '../services/currency_service.dart';

class TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;

  const TripCard({
    super.key,
    required this.trip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final dateFormat = DateFormat('MMM dd, yyyy');
    final dateRangeText = '${dateFormat.format(trip.startDate)} - ${dateFormat.format(trip.endDate)}';
    
    final totalSpent = trip.totalSpent;
    final percentSpent = trip.budget > 0 ? (totalSpent / trip.budget).clamp(0.0, 1.0) : 0.0;
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirestoreService.instance.getUserStream(user?.uid ?? ''),
      builder: (context, snapshot) {
        final userData = (snapshot.hasData && snapshot.data!.data() != null)
            ? snapshot.data!.data()!
            : {};
        final targetCurrency = userData['homeCurrency'] as String? ?? DummyData.userProfile['homeCurrency'] ?? 'USD';

        final convertedSpent = CurrencyService.instance.convert(totalSpent, 'USD', targetCurrency);
        final convertedBudget = CurrencyService.instance.convert(trip.budget, 'USD', targetCurrency);
        final formattedSpent = CurrencyService.instance.format(convertedSpent, targetCurrency);
        final formattedBudget = CurrencyService.instance.format(convertedBudget, targetCurrency);

        return Card(
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.only(bottom: 16),
          elevation: isDark ? 4 : 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 200,
              child: Stack(
                children: [
                  // 1. Cover Image (Stack background)
                  Positioned.fill(
                    child: Image.network(
                      trip.coverImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF3F51B5), Color(0xFF303F9F)],
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.image_not_supported_rounded, color: Colors.white60, size: 48),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                    ),
                  ),

                  // 2. Dark Gradient Overlay (for text readability)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.1),
                            Colors.black.withOpacity(0.85),
                          ],
                          stops: const [0.3, 0.95],
                        ),
                      ),
                    ),
                  ),

                  // 3. Trip Meta Content
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge for active/upcoming trip status
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: trip.startDate.isBefore(DateTime.now()) && trip.endDate.isAfter(DateTime.now())
                                ? Colors.green.withOpacity(0.85)
                                : (trip.startDate.isAfter(DateTime.now()) 
                                    ? const Color(0xFF6366F1).withOpacity(0.85)
                                    : Colors.grey.withOpacity(0.85)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            trip.startDate.isBefore(DateTime.now()) && trip.endDate.isAfter(DateTime.now())
                                ? 'ONGOING'
                                : (trip.startDate.isAfter(DateTime.now()) ? 'UPCOMING' : 'COMPLETED'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Trip Name & Route (Starting Point to Destination)
                        Text(
                          trip.startingPoint.isNotEmpty
                              ? '${trip.startingPoint} ➔ ${trip.name}'
                              : trip.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 4.0,
                                color: Colors.black54,
                                offset: Offset(1.0, 1.0),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Trip Date
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined, size: 14, color: Colors.white70),
                            const SizedBox(width: 6),
                            Text(
                              dateRangeText,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Budget Progress Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Spent: $formattedSpent / $formattedBudget',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        Text(
                          '${(percentSpent * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: percentSpent > 0.9 ? Colors.redAccent : Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentSpent,
                        minHeight: 6,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          percentSpent > 0.9 ? Colors.redAccent : const Color(0xFF818CF8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  },
);
}
}
