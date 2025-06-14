import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarHeader extends StatelessWidget {
  final DateTime selectedDay;
  final VoidCallback onPreviousPressed;
  final VoidCallback onNextPressed;
  final VoidCallback onTodayPressed;

  const CalendarHeader({
    super.key,
    required this.selectedDay,
    required this.onPreviousPressed,
    required this.onNextPressed,
    required this.onTodayPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[800]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          IconButton(
            onPressed: onPreviousPressed,
            icon: const Icon(Icons.chevron_left, color: Colors.green),
            splashRadius: 24,
          ),
          
          // Current month/year
          Text(
            DateFormat('MMMM yyyy').format(selectedDay),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          // Next button
          IconButton(
            onPressed: onNextPressed,
            icon: const Icon(Icons.chevron_right, color: Colors.green),
            splashRadius: 24,
          ),
          
          // Today button
          TextButton(
            onPressed: onTodayPressed,
            style: TextButton.styleFrom(
              foregroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Today'),
          ),
        ],
      ),
    );
  }
} 