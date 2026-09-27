import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/vendor_auth_provider.dart';
import '../../../vendor/presentation/pages/vendor_dashboard_page.dart';
import 'vendor_login_page.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});
  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 900), _next);
  }

  void _next() {
    if (!mounted) return;
    final auth = ref.read(vendorAuthProvider);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => auth.isAuthenticated
            ? const VendorDashboardPage()
            : const VendorLoginPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.indigoDark,
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'kabakaba',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 26,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'ESPACE VENDEUR',
            style: TextStyle(
              color: Color(0x99FFFFFF),
              fontSize: 11,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 32),
          const CircularProgressIndicator(color: AppColors.accent),
        ],
      ),
    ),
  );
}
