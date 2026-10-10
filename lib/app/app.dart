import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/push/push_notifications.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/controllers/vendor_auth_controller.dart';
import '../features/notifications/data/notifications_repository.dart';
import 'router.dart';

class VendorApp extends ConsumerWidget {
  const VendorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'kabakaba Vendeur',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      builder: (context, child) {
        return _PushSessionBinder(child: child ?? const SizedBox.shrink());
      },
    );
  }
}

class _PushSessionBinder extends ConsumerStatefulWidget {
  final Widget child;

  const _PushSessionBinder({required this.child});

  @override
  ConsumerState<_PushSessionBinder> createState() => _PushSessionBinderState();
}

class _PushSessionBinderState extends ConsumerState<_PushSessionBinder> {
  PushNotifications? _push;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final push = ref.read(pushNotificationsProvider);
      _push = push;
      push.onForegroundMessage = () {
        ref.invalidate(vendorNotificationsProvider);
      };
      if (ref.read(vendorAuthControllerProvider).isAuthenticated) {
        push.syncToken();
      }
    });
  }

  @override
  void dispose() {
    _push?.onForegroundMessage = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(vendorAuthControllerProvider, (previous, next) {
      final push = ref.read(pushNotificationsProvider);
      if (next.isAuthenticated && previous?.isAuthenticated != true) {
        push.syncToken();
      } else if (!next.isAuthenticated && previous?.isAuthenticated == true) {
        push.unregister();
      }
    });
    return widget.child;
  }
}
