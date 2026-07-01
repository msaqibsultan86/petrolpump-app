import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import '../screens/dashboard_screen.dart';
import '../screens/sales_screen.dart';
import '../screens/purchases_screen.dart';
import '../screens/expenses_screen.dart';
import '../screens/loans_screen.dart';
import '../screens/tanks_screen.dart';
import '../screens/dip_readings_screen.dart';
import '../screens/daybook_screen.dart';
import '../screens/login_screen.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────
          FutureBuilder<List<dynamic>>(
            future: Future.wait([
              AuthService.getUser(),
              AuthService.getCurrentPumpName(),
            ]),
            builder: (context, snapshot) {
              final user = snapshot.data?[0] as Map<String, dynamic>?;
              final pumpName = snapshot.data?[1] as String? ?? 'Petrol Pump';
              return Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20,
                  bottom: 20,
                  left: 20,
                  right: 20,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryDark, AppTheme.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_gas_station,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      pumpName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (user != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        user['full_name'] ?? user['username'] ?? '',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          // ── Menu Items ──────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildItem(context, Icons.dashboard_rounded, 'Dashboard', 'dashboard', const DashboardScreen()),
                _buildItem(context, Icons.shopping_cart_rounded, 'Sales', 'sales', const SalesScreen()),
                _buildItem(context, Icons.inventory_rounded, 'Purchases', 'purchases', const PurchasesScreen()),
                _buildItem(context, Icons.receipt_long_rounded, 'Expenses', 'expenses', const ExpensesScreen()),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildItem(context, Icons.propane_tank_rounded, 'Tanks', 'tanks', const TanksScreen()),
                _buildItem(context, Icons.straighten_rounded, 'Dip Readings', 'dip_readings', const DipReadingsScreen()),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildItem(context, Icons.account_balance_wallet_rounded, 'Loans', 'loans', const LoansScreen()),
                _buildItem(context, Icons.menu_book_rounded, 'Day Book', 'daybook', const DaybookScreen()),
              ],
            ),
          ),
          // ── Logout ──────────────────────────────────────────
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppTheme.danger),
            title: const Text('Logout', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w600)),
            onTap: () async {
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
              if (confirm == true && context.mounted) {
                await AuthService.logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, IconData icon, String title, String route, Widget screen) {
    final isActive = currentRoute == route;
    return ListTile(
      leading: Icon(icon, color: isActive ? AppTheme.primary : AppTheme.textSecondary, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? AppTheme.primary : AppTheme.textPrimary,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          fontSize: 14,
        ),
      ),
      selected: isActive,
      selectedTileColor: AppTheme.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      onTap: isActive
          ? () => Navigator.pop(context)
          : () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => screen));
            },
    );
  }
}
