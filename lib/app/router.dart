import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../features/auth/data/vendor_auth_provider.dart';
import '../features/auth/presentation/pages/vendor_login_page.dart';
import '../features/vendor/presentation/pages/vendor_dashboard_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authRefresh = ValueNotifier(
    ref.read(vendorAuthProvider).isAuthenticated,
  );
  ref.listen(vendorAuthProvider, (_, auth) {
    authRefresh.value = auth.isAuthenticated;
  });
  ref.onDispose(authRefresh.dispose);

  return GoRouter(
    refreshListenable: authRefresh,
    initialLocation: '/',
    redirect: (context, state) {
      final auth = ref.read(vendorAuthProvider);
      final path = state.uri.path;
      final isPublic = path == '/' || path == '/login';
      if (path == '/') {
        if (auth.isAuthenticated) return '/dashboard';
        return '/login';
      }
      if (auth.isAuthenticated && path == '/login') return '/dashboard';
      if (!auth.isAuthenticated && !isPublic) {
        return '/login';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const _Bootstrap()),
      GoRoute(path: '/login', builder: (_, __) => const VendorLoginPage()),
      GoRoute(
        path: '/dashboard',
        builder: (_, __) => const VendorDashboardPage(),
      ),
    ],
  );
});

class _Bootstrap extends ConsumerStatefulWidget {
  const _Bootstrap();
  @override
  ConsumerState<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends ConsumerState<_Bootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _decide());
  }

  void _decide() {
    final auth = ref.read(vendorAuthProvider);
    if (auth.isAuthenticated) {
      context.go('/dashboard');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
}
