import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/pump_switcher.dart';
import '../widgets/date_filter_bar.dart';
import '../widgets/empty_state.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
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
      final data = await ApiService.getPurchases(from: fmt.format(_from), to: fmt.format(_to));
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
    final purchases = List<Map<String, dynamic>>.from(_data?['purchases'] ?? []);
    final summary = _data?['summary'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchases'),
        actions: [PumpSwitcher(onPumpChanged: _loadData)],
      ),
      drawer: const AppDrawer(currentRoute: 'purchases'),
      body: Column(
        children: [
          DateFilterBar(fromDate: _from, toDate: _to, onDateChanged: (f, t) {
            setState(() { _from = f; _to = t; });
            _loadData();
          }),
          if (summary != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SumItem(label: 'Total', value: _money(summary['total']), color: AppTheme.primary),
                  _SumItem(label: 'Cash', value: _money(summary['cash_total']), color: AppTheme.success),
                  _SumItem(label: 'Credit', value: _money(summary['credit_total']), color: AppTheme.warning),
                  _SumItem(label: 'Qty', value: '${summary['total_qty']} L', color: AppTheme.info),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : purchases.isEmpty
                    ? const EmptyState(icon: Icons.inventory_2_outlined, title: 'No Purchases')
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: purchases.length,
                          itemBuilder: (_, i) {
                            final p = purchases[i];
                            final isCash = p['payment_type'] == 'cash';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: (isCash ? AppTheme.success : AppTheme.warning).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(isCash ? 'CASH' : 'CREDIT',
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isCash ? AppTheme.success : AppTheme.warning)),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(p['date'] ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                      ]),
                                      Text(_money(p['total_amount']), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(children: [
                                    const Icon(Icons.local_gas_station, size: 14, color: AppTheme.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(p['product_name'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    const Spacer(),
                                    Text('${p['quantity']} L', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                  ]),
                                  if ((p['supplier_name'] ?? '').isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(children: [
                                      const Icon(Icons.business, size: 13, color: AppTheme.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(p['supplier_name'], style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                      if ((p['invoice_no'] ?? '').isNotEmpty) ...[
                                        const Spacer(),
                                        Text('Inv: ${p['invoice_no']}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                      ],
                                    ]),
                                  ],
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

class _SumItem extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SumItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      FittedBox(child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color))),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
    ]);
  }
}
