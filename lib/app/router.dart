import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../features/auth/presentation/controllers/vendor_auth_controller.dart';
import '../features/auth/presentation/pages/vendor_activation_page.dart';
import '../features/auth/presentation/pages/vendor_pin_login_page.dart';
import '../features/vendor/presentation/pages/vendor_dashboard_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authRefresh = ValueNotifier(ref.read(vendorAuthControllerProvider));
  ref.listen(vendorAuthControllerProvider, (_, next) {
    authRefresh.value = next;
  });
  ref.onDispose(authRefresh.dispose);

  return GoRouter(
    refreshListenable: authRefresh,
    initialLocation: '/',
    redirect: (context, state) {
      final auth = ref.read(vendorAuthControllerProvider);
      final path = state.uri.path;

      if (auth.isAuthenticated) {
        if (path == '/' || path == '/activate' || path == '/pin') {
          return '/dashboard';
        }
        return null;
      }

      if (auth.status == VendorAuthStatus.needsPin) {
        return path == '/pin' ? null : '/pin';
      }

      return path == '/activate' ? null : '/activate';
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const _Bootstrap()),
      GoRoute(
        path: '/activate',
        builder: (context, state) => const VendorActivationPage(),
      ),
      GoRoute(
        path: '/pin',
        builder: (context, state) => const VendorPinLoginPage(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const VendorDashboardPage(),
      ),
    ],
  );
});

class _Bootstrap extends StatelessWidget {
  const _Bootstrap();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.indigoDark,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BrandMark(),
            SizedBox(height: 14),
            Text(
              'kabakaba',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 26,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'ESPACE VENDEUR',
              style: TextStyle(
                color: Color(0x99FFFFFF),
                fontSize: 11,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
