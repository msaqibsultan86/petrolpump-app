import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/pump_switcher.dart';
import '../widgets/date_filter_bar.dart';
import '../widgets/empty_state.dart';

class DaybookScreen extends StatefulWidget {
  const DaybookScreen({super.key});

  @override
  State<DaybookScreen> createState() => _DaybookScreenState();
}

class _DaybookScreenState extends State<DaybookScreen> {
  DateTime _from = DateTime.now();
  DateTime _to = DateTime.now();
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final fmt = DateFormat('yyyy-MM-dd');
      final data = await ApiService.getDaybook(from: fmt.format(_from), to: fmt.format(_to));
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  String _money(dynamic val) => 'Rs ${NumberFormat('#,##0.00').format(double.tryParse(val?.toString() ?? '0') ?? 0)}';

  @override
  Widget build(BuildContext context) {
    final entries = List<Map<String, dynamic>>.from(_data?['entries'] ?? []);
    final summary = _data?['summary'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Day Book'),
        actions: [PumpSwitcher(onPumpChanged: _loadData)],
      ),
      drawer: const AppDrawer(currentRoute: 'daybook'),
      body: Column(
        children: [
          DateFilterBar(fromDate: _from, toDate: _to, onDateChanged: (f, t) {
            setState(() { _from = f; _to = t; });
            _loadData();
          }),
          // Summary cards
          if (summary != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Expanded(child: _SummaryCol(label: 'Income', value: _money(summary['total_income']), color: AppTheme.success)),
                  Container(width: 1, height: 36, color: Colors.grey.shade200),
                  Expanded(child: _SummaryCol(label: 'Expense', value: _money(summary['total_expense']), color: AppTheme.danger)),
                  Container(width: 1, height: 36, color: Colors.grey.shade200),
                  Expanded(child: _SummaryCol(
                    label: 'Net',
                    value: _money(summary['net']),
                    color: (double.tryParse(summary['net'] ?? '0') ?? 0) >= 0 ? AppTheme.success : AppTheme.danger,
                  )),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : entries.isEmpty
                    ? const EmptyState(icon: Icons.menu_book_outlined, title: 'No Entries')
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: entries.length,
                          itemBuilder: (_, i) => _EntryCard(entry: entries[i], money: _money),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCol extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SummaryCol({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FittedBox(child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color))),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
      ],
    );
  }
}

class _EntryCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  final String Function(dynamic) money;
  const _EntryCard({required this.entry, required this.money});

  IconData _icon(String type) {
    switch (type) {
      case 'Sale': return Icons.shopping_cart;
      case 'Purchase': return Icons.inventory;
      case 'Expense': return Icons.receipt_long;
      case 'Customer Payment': return Icons.arrow_downward;
      case 'Supplier Payment': return Icons.arrow_upward;
      default: return Icons.swap_horiz;
    }
  }

  Color _color(String type) {
    switch (type) {
      case 'Sale': return AppTheme.success;
      case 'Purchase': return AppTheme.accent;
      case 'Expense': return AppTheme.danger;
      case 'Customer Payment': return AppTheme.info;
      case 'Supplier Payment': return AppTheme.warning;
      default: return AppTheme.textSecondary;
    }
  }

  bool _isIncome(String type) => type == 'Sale' || type == 'Customer Payment';

  @override
  Widget build(BuildContext context) {
    final type = entry['type'] ?? '';
    final color = _color(type);
    final isIncome = _isIncome(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_icon(type), size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(type, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
                  ),
                  const SizedBox(width: 6),
                  Text(entry['date'] ?? '', style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                ]),
                const SizedBox(height: 4),
                Text(entry['description'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                if ((entry['party_name'] ?? '').isNotEmpty)
                  Text(entry['party_name'], style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'} ${money(entry['amount'])}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isIncome ? AppTheme.success : AppTheme.danger,
            ),
          ),
        ],
      ),
    );
  }
}
