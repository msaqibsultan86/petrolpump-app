import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../config/theme.dart';

class PumpSwitcher extends StatelessWidget {
  final VoidCallback onPumpChanged;

  const PumpSwitcher({super.key, required this.onPumpChanged});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        AuthService.getPumps(),
        AuthService.getCurrentPumpId(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final pumps = snapshot.data![0] as List<Map<String, dynamic>>;
        final currentPumpId = snapshot.data![1] as int;

        if (pumps.length <= 1) return const SizedBox.shrink();

        return PopupMenuButton<int>(
          icon: const Icon(Icons.swap_horiz, color: Colors.white),
          tooltip: 'Switch Pump',
          onSelected: (pumpId) async {
            await AuthService.setCurrentPumpId(pumpId);
            onPumpChanged();
          },
          itemBuilder: (context) => pumps.map((pump) {
            final isActive = pump['id'] == currentPumpId;
            return PopupMenuItem<int>(
              value: pump['id'],
              child: Row(
                children: [
                  Icon(
                    Icons.local_gas_station,
                    color: isActive ? AppTheme.primary : AppTheme.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    pump['name'] ?? 'Pump ${pump['id']}',
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? AppTheme.primary : AppTheme.textPrimary,
                    ),
                  ),
                  if (isActive) ...[
                    const Spacer(),
                    const Icon(Icons.check, color: AppTheme.primary, size: 18),
                  ],
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
