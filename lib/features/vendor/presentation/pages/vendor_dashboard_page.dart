import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import 'vendor_orders_page.dart';
import 'vendor_profile_page.dart';
import 'vendor_stats_page.dart';
import 'vendor_wallet_page.dart';

class VendorDashboardPage extends ConsumerStatefulWidget {
  const VendorDashboardPage({super.key});
  @override
  ConsumerState<VendorDashboardPage> createState() =>
      _VendorDashboardPageState();
}

class _VendorDashboardPageState extends ConsumerState<VendorDashboardPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _tab,
          children: const [
            VendorOrdersPage(),
            VendorWalletPage(),
            VendorStatsPage(),
            VendorProfilePage(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomNavBar(
          currentIndex: _tab,
          onTap: (i) => setState(() => _tab = i),
        ),
      ),
    );
  }
}
