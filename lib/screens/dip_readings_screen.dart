import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/pump_switcher.dart';
import '../widgets/date_filter_bar.dart';
import '../widgets/empty_state.dart';

class DipReadingsScreen extends StatefulWidget {
  const DipReadingsScreen({super.key});

  @override
  State<DipReadingsScreen> createState() => _DipReadingsScreenState();
}

class _DipReadingsScreenState extends State<DipReadingsScreen> {
  DateTime _from = DateTime.now();
  DateTime _to = DateTime.now();
  List<Map<String, dynamic>> _readings = [];
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
      final data = await ApiService.getDipReadings(from: fmt.format(_from), to: fmt.format(_to));
      setState(() {
        _readings = List<Map<String, dynamic>>.from(data['readings'] ?? []);
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
        title: const Text('Dip Readings'),
        actions: [PumpSwitcher(onPumpChanged: _loadData)],
      ),
      drawer: const AppDrawer(currentRoute: 'dip_readings'),
      body: Column(
        children: [
          DateFilterBar(fromDate: _from, toDate: _to, onDateChanged: (f, t) {
            setState(() { _from = f; _to = t; });
            _loadData();
          }),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _readings.isEmpty
                    ? const EmptyState(icon: Icons.straighten_outlined, title: 'No Dip Readings')
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _readings.length,
                          itemBuilder: (_, i) => _DipCard(reading: _readings[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _DipCard extends StatelessWidget {
  final Map<String, dynamic> reading;
  const _DipCard({required this.reading});

  @override
  Widget build(BuildContext context) {
    final variation = double.tryParse(reading['variation']?.toString() ?? '0') ?? 0;
    final isPositive = variation >= 0;
    final variationColor = isPositive ? AppTheme.success : AppTheme.danger;
    final fmt = NumberFormat('#,##0.00');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.straighten, size: 18, color: AppTheme.info),
                ),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(reading['tank_name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(reading['product_name'] ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ]),
              ]),
              Text(reading['date'] ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _DipField(label: 'Dip', value: '${reading['dip_cm']} cm'),
              _DipField(label: 'Physical', value: '${fmt.format(double.tryParse(reading['stock_in_litres']?.toString() ?? '0') ?? 0)} L'),
              _DipField(label: 'Book', value: '${fmt.format(double.tryParse(reading['book_stock']?.toString() ?? '0') ?? 0)} L'),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: variationColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${isPositive ? '+' : ''}${fmt.format(variation)} L',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: variationColor),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text('Variation', style: TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          if ((reading['notes'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(reading['notes'], style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ],
      ),
    );
  }
}

class _DipField extends StatelessWidget {
  final String label, value;
  const _DipField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
