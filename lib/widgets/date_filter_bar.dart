import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';

class DateFilterBar extends StatelessWidget {
  final DateTime fromDate;
  final DateTime toDate;
  final Function(DateTime from, DateTime to) onDateChanged;

  const DateFilterBar({
    super.key,
    required this.fromDate,
    required this.toDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Quick filters
          _QuickChip(
            label: 'Today',
            isActive: _isToday(),
            onTap: () {
              final now = DateTime.now();
              onDateChanged(now, now);
            },
          ),
          const SizedBox(width: 6),
          _QuickChip(
            label: '7 Days',
            isActive: _is7Days(),
            onTap: () {
              final now = DateTime.now();
              onDateChanged(now.subtract(const Duration(days: 6)), now);
            },
          ),
          const SizedBox(width: 6),
          _QuickChip(
            label: '30 Days',
            isActive: _is30Days(),
            onTap: () {
              final now = DateTime.now();
              onDateChanged(now.subtract(const Duration(days: 29)), now);
            },
          ),
          const Spacer(),
          // Custom date picker
          InkWell(
            onTap: () => _pickDateRange(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${fmt.format(fromDate)} - ${fmt.format(toDate)}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday() {
    final now = DateTime.now();
    return _sameDay(fromDate, now) && _sameDay(toDate, now);
  }

  bool _is7Days() {
    final now = DateTime.now();
    final sevenAgo = now.subtract(const Duration(days: 6));
    return _sameDay(fromDate, sevenAgo) && _sameDay(toDate, now);
  }

  bool _is30Days() {
    final now = DateTime.now();
    final thirtyAgo = now.subtract(const Duration(days: 29));
    return _sameDay(fromDate, thirtyAgo) && _sameDay(toDate, now);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _pickDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: fromDate, end: toDate),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      onDateChanged(picked.start, picked.end);
    }
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _QuickChip({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppTheme.primary : AppTheme.textSecondary.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
