import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/pump_switcher.dart';
import '../widgets/empty_state.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _data;
  bool _loading = true;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getLoans();
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  String _money(dynamic val) => 'Rs ${NumberFormat('#,##0.00').format(double.tryParse(val?.toString() ?? '0') ?? 0)}';

  @override
  Widget build(BuildContext context) {
    final loans = List<Map<String, dynamic>>.from(_data?['loans'] ?? []);
    final summary = _data?['summary'] as Map<String, dynamic>?;
    final givenLoans = loans.where((l) => l['type'] == 'given').toList();
    final takenLoans = loans.where((l) => l['type'] == 'taken').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loans'),
        actions: [PumpSwitcher(onPumpChanged: _loadData)],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Given'),
            Tab(text: 'Taken'),
          ],
        ),
      ),
      drawer: const AppDrawer(currentRoute: 'loans'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (summary != null)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(children: [
                          Text(_money(summary['given_balance']), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.success)),
                          const SizedBox(height: 2),
                          const Text('To Receive', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        ]),
                        Container(width: 1, height: 30, color: Colors.grey.shade200),
                        Column(children: [
                          Text(_money(summary['taken_balance']), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.danger)),
                          const SizedBox(height: 2),
                          const Text('To Pay', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        ]),
                      ],
                    ),
                  ),
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildLoanList(givenLoans, 'given'),
                      _buildLoanList(takenLoans, 'taken'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLoanList(List<Map<String, dynamic>> loans, String type) {
    if (loans.isEmpty) {
      return EmptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: 'No ${type == 'given' ? 'Given' : 'Taken'} Loans',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: loans.length,
        itemBuilder: (_, i) {
          final l = loans[i];
          final isActive = l['status'] == 'active';
          final color = type == 'given' ? AppTheme.success : AppTheme.danger;
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
                      Text(l['person_name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isActive ? AppTheme.success : AppTheme.textSecondary).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(isActive ? 'ACTIVE' : 'CLOSED',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isActive ? AppTheme.success : AppTheme.textSecondary)),
                      ),
                    ]),
                    Text(_money(l['balance']), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(children: [
                  Text('Loan: ${_money(l['amount'])}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  const SizedBox(width: 12),
                  Text(l['date'] ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ]),
                if ((l['description'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(l['description'], style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
