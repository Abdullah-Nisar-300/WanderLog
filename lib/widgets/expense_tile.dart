// expense_tile.dart
// A custom widget displaying expense details with dedicated icons, color codes, and formatted amounts.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

class ExpenseTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTap;

  const ExpenseTile({
    super.key,
    required this.expense,
    this.onTap,
  });

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return Icons.restaurant_rounded;
      case ExpenseCategory.stay:
        return Icons.hotel_rounded;
      case ExpenseCategory.transport:
        return Icons.directions_transit_filled_rounded;
      case ExpenseCategory.other:
        return Icons.local_mall_rounded;
    }
  }

  Color _getCategoryColor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return const Color(0xFFF59E0B); // Amber
      case ExpenseCategory.stay:
        return const Color(0xFF3B82F6); // Blue
      case ExpenseCategory.transport:
        return const Color(0xFF10B981); // Emerald
      case ExpenseCategory.other:
        return const Color(0xFF8B5CF6); // Purple
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(expense.category);
    final categoryIcon = _getCategoryIcon(expense.category);
    final dateFormat = DateFormat('MMM dd');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: categoryColor.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: categoryColor.withOpacity(0.3), width: 1),
          ),
          child: Icon(
            categoryIcon,
            color: categoryColor,
            size: 22,
          ),
        ),
        title: Text(
          expense.description.isNotEmpty ? expense.description : expense.category.displayName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              expense.category.displayName,
              style: TextStyle(
                color: categoryColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            const Text('•', style: TextStyle(color: Colors.white24)),
            const SizedBox(width: 8),
            Text(
              dateFormat.format(expense.date),
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Text(
          '${expense.currency} ${expense.amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
