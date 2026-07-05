import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/kpi_card.dart';
import '../widgets/pump_switcher.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  String _pumpName = '';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getDashboard(
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      );
      final pumpName = await AuthService.getCurrentPumpName();
      setState(() {
        _data = data;
        _pumpName = pumpName;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  String _money(String? val) => 'Rs ${NumberFormat('#,##0.00').format(double.tryParse(val ?? '0') ?? 0)}';

  bool get _isToday {
    final t = DateTime.now();
    return _selectedDate.year == t.year && _selectedDate.month == t.month && _selectedDate.day == t.day;
  }

  Future<void> _changeDate(int deltaDays) async {
    final t = DateTime.now();
    final todayOnly = DateTime(t.year, t.month, t.day);
    final next = _selectedDate.add(Duration(days: deltaDays));
    if (next.isAfter(todayOnly)) return;
    setState(() => _selectedDate = next);
    await _loadData();
  }

  Future<void> _pickDate() async {
    final t = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(t.year, t.month, t.day),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
      await _loadData();
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pumpName.isEmpty ? 'Dashboard' : _pumpName),
        actions: [
          PumpSwitcher(onPumpChanged: _loadData),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          IconButton(icon: const Icon(Icons.logout), tooltip: 'Logout', onPressed: _logout),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: AppTheme.danger.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: AppTheme.danger)),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
                  ],
                ))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: _buildContent(),
                ),
    );
  }

  Widget _buildContent() {
    final kpi = _data!['kpi'] as Map<String, dynamic>;
    final tanks = List<Map<String, dynamic>>.from(_data!['tanks'] ?? []);
    final chartData = List<Map<String, dynamic>>.from(_data!['chart_data'] ?? []);
    final recentSales = List<Map<String, dynamic>>.from(_data!['recent_sales'] ?? []);
    final unrecorded = List<Map<String, dynamic>>.from(_data!['unrecorded'] ?? []);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Greeting ────────────────────────────────────────
        Text(
          _getGreeting(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
        ),
        Text(
          DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 12),

        // ── Date Selector ───────────────────────────────────
        _buildDateBar(),
        const SizedBox(height: 16),

        // ── KPI Cards ───────────────────────────────────────
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.45,
          children: [
            KpiCard(title: "REVENUE", value: _money(kpi['today_revenue']), icon: Icons.trending_up, gradient: AppTheme.salesGradient),
            KpiCard(title: "CASH SALE", value: _money(kpi['today_cash']), icon: Icons.payments, gradient: AppTheme.cashGradient),
            KpiCard(title: "CREDIT SALE", value: _money(kpi['today_credit']), icon: Icons.credit_card, gradient: AppTheme.creditGradient),
            KpiCard(title: "PURCHASES", value: _money(kpi['today_purchases']), icon: Icons.shopping_bag, gradient: AppTheme.purchaseGradient),
            KpiCard(title: "PROFIT (SALE − COGS)", value: _money(kpi['today_profit']), icon: Icons.account_balance, gradient: AppTheme.netGradient),
            KpiCard(title: "DEALER MARGIN", value: _money(kpi['today_margin']), icon: Icons.percent, gradient: AppTheme.marginGradient),
            KpiCard(title: "EXPENSES", value: _money(kpi['today_expenses']), icon: Icons.receipt_long, gradient: AppTheme.expenseGradient),
          ],
        ),
        const SizedBox(height: 16),

        // ── Financial Summary Row ────────────────────────────
        Row(
          children: [
            Expanded(child: _FinSummaryCard(title: 'Receivable', value: _money(kpi['customer_receivable']), icon: Icons.arrow_downward, color: AppTheme.success)),
            const SizedBox(width: 10),
            Expanded(child: _FinSummaryCard(title: 'Payable', value: _money(kpi['supplier_payable']), icon: Icons.arrow_upward, color: AppTheme.danger)),
            const SizedBox(width: 10),
            Expanded(child: _FinSummaryCard(title: 'Monthly', value: _money(kpi['monthly_sales']), icon: Icons.calendar_month, color: AppTheme.info)),
          ],
        ),
        const SizedBox(height: 20),

        // ── Meter vs Sales reconciliation ───────────────────
        if (unrecorded.isNotEmpty) ...[
          _UnrecordedCard(
            items: unrecorded,
            totalValue: _money(_data!['unrecorded_value']?.toString()),
          ),
          const SizedBox(height: 20),
        ],

        // ── 7-Day Chart ─────────────────────────────────────
        if (chartData.isNotEmpty) ...[
          const Text('Last 7 Days', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Container(
            height: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: BarChart(
              BarChartData(
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < chartData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              (chartData[idx]['label'] as String).split(' ')[0],
                              style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: List.generate(chartData.length, (i) {
                  final sales = (chartData[i]['sales'] as num).toDouble();
                  final purchases = (chartData[i]['purchases'] as num).toDouble();
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(toY: sales, color: AppTheme.primary, width: 10, borderRadius: BorderRadius.circular(4)),
                      BarChartRodData(toY: purchases, color: AppTheme.accent, width: 10, borderRadius: BorderRadius.circular(4)),
                    ],
                  );
                }),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendDot(color: AppTheme.primary, label: 'Sales'),
                const SizedBox(width: 20),
                _LegendDot(color: AppTheme.accent, label: 'Purchases'),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // ── Tank Levels ─────────────────────────────────────
        if (tanks.isNotEmpty) ...[
          const Text('Tank Levels', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ...tanks.map((tank) => _TankLevelCard(tank: tank)),
          const SizedBox(height: 20),
        ],

        // ── Recent Sales ────────────────────────────────────
        if (recentSales.isNotEmpty) ...[
          const Text('Recent Sales', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: recentSales.take(8).map((s) {
                final isCash = s['payment_type'] == 'cash';
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: (isCash ? AppTheme.success : AppTheme.warning).withValues(alpha: 0.1),
                    child: Icon(
                      isCash ? Icons.payments : Icons.credit_card,
                      size: 18,
                      color: isCash ? AppTheme.success : AppTheme.warning,
                    ),
                  ),
                  title: Text(s['product_name'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${s['vehicle_no'] ?? '-'}  |  ${s['quantity']} L',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                  trailing: Text(
                    _money(s['total_amount']?.toString()),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDateBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeDate(-1),
          ),
          Expanded(
            child: InkWell(
              onTap: _pickDate,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today, size: 15, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      _isToday ? 'Today' : DateFormat('EEE, d MMM yyyy').format(_selectedDate),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _isToday ? null : () => _changeDate(1),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}

// ── Sub-widgets ──────────────────────────────────────────────

class _FinSummaryCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _FinSummaryCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _TankLevelCard extends StatelessWidget {
  final Map<String, dynamic> tank;
  const _TankLevelCard({required this.tank});

  @override
  Widget build(BuildContext context) {
    final pct = (tank['percentage'] as num).toDouble();
    final color = pct > 40 ? AppTheme.success : (pct > 15 ? AppTheme.warning : AppTheme.danger);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tank['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${pct.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${tank['product_name']} — ${NumberFormat('#,##0').format(tank['current_stock'])} / ${NumberFormat('#,##0').format(tank['capacity'])} L',
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 10,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnrecordedCard extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String totalValue;
  const _UnrecordedCard({required this.items, required this.totalValue});

  String _fmt(dynamic v) => NumberFormat('#,##0.##').format(double.tryParse(v.toString()) ?? 0);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text('Unrecorded fuel (meter vs sales)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Dispensed per nozzle readings but not yet entered as sales.',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          const SizedBox(height: 10),
          ...items.map((u) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('${u['name']} — ${_fmt(u['short'])} L short',
                          style: const TextStyle(fontSize: 12)),
                    ),
                    Text('Rs ${_fmt(u['value'])}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.danger)),
                  ],
                ),
              )),
          const Divider(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total (est.)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text(totalValue, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.danger)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }
}
