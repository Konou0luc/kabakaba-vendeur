import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class RemotePhoto extends StatelessWidget {
  final String? url;
  final double width;
  final double height;
  final double radius;
  final Widget fallback;

  const RemotePhoto({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    required this.radius,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final src = url?.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: src == null || src.isEmpty
            ? fallback
            : Image.network(
                src,
                fit: BoxFit.cover,
                width: width,
                height: height,
                errorBuilder: (_, _, _) => fallback,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return ColoredBox(
                    color: AppColors.indigoLight,
                    child: Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
