import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/pump_switcher.dart';
import '../widgets/date_filter_bar.dart';
import '../widgets/empty_state.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
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
      final data = await ApiService.getExpenses(from: fmt.format(_from), to: fmt.format(_to));
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  String _money(dynamic val) => 'Rs ${NumberFormat('#,##0.00').format(double.tryParse(val?.toString() ?? '0') ?? 0)}';

  @override
  Widget build(BuildContext context) {
    final expenses = List<Map<String, dynamic>>.from(_data?['expenses'] ?? []);
    final summary = _data?['summary'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [PumpSwitcher(onPumpChanged: _loadData)],
      ),
      drawer: const AppDrawer(currentRoute: 'expenses'),
      body: Column(
        children: [
          DateFilterBar(fromDate: _from, toDate: _to, onDateChanged: (f, t) {
            setState(() { _from = f; _to = t; });
            _loadData();
          }),
          if (summary != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(children: [
                    Text(_money(summary['total']), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.danger)),
                    const SizedBox(height: 2),
                    const Text('Total Expenses', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ]),
                  Column(children: [
                    Text('${summary['count']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.info)),
                    const SizedBox(height: 2),
                    const Text('Entries', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ]),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : expenses.isEmpty
                    ? const EmptyState(icon: Icons.receipt_long_outlined, title: 'No Expenses')
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: expenses.length,
                          itemBuilder: (_, i) {
                            final e = expenses[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.danger.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.receipt_long, size: 20, color: AppTheme.danger),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(e['category_name'] ?? 'Uncategorized', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${e['date']}${(e['description'] ?? '').isNotEmpty ? '  |  ${e['description']}' : ''}',
                                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(_money(e['amount']), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.danger)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
