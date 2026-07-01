import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/pump_switcher.dart';
import '../widgets/empty_state.dart';

class TanksScreen extends StatefulWidget {
  const TanksScreen({super.key});

  @override
  State<TanksScreen> createState() => _TanksScreenState();
}

class _TanksScreenState extends State<TanksScreen> {
  List<Map<String, dynamic>> _tanks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getTanks();
      setState(() {
        _tanks = List<Map<String, dynamic>>.from(data['tanks'] ?? []);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tanks'),
        actions: [PumpSwitcher(onPumpChanged: _loadData)],
      ),
      drawer: const AppDrawer(currentRoute: 'tanks'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tanks.isEmpty
              ? const EmptyState(icon: Icons.propane_tank_outlined, title: 'No Tanks')
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tanks.length,
                    itemBuilder: (_, i) => _TankCard(tank: _tanks[i]),
                  ),
                ),
    );
  }
}

class _TankCard extends StatelessWidget {
  final Map<String, dynamic> tank;
  const _TankCard({required this.tank});

  @override
  Widget build(BuildContext context) {
    final capacity = (tank['capacity'] as num).toDouble();
    final stock = (tank['current_stock'] as num).toDouble();
    final pct = (tank['percentage'] as num).toDouble();
    final nozzles = List<Map<String, dynamic>>.from(tank['nozzles'] ?? []);
    final color = pct > 40 ? AppTheme.success : (pct > 15 ? AppTheme.warning : AppTheme.danger);
    final fmt = NumberFormat('#,##0');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.08), color.withValues(alpha: 0.02)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.propane_tank, size: 24, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tank['name'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(tank['product_name'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${pct.toStringAsFixed(1)}%', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                    Text('${fmt.format(stock)} L', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 14,
                    backgroundColor: color.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Stock: ${fmt.format(stock)} L', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    Text('Capacity: ${fmt.format(capacity)} L', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          // Nozzles
          if (nozzles.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nozzles', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: nozzles.map((n) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.gas_meter, size: 14, color: AppTheme.primary),
                          const SizedBox(width: 4),
                          Text(n['name'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.primary)),
                        ],
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
