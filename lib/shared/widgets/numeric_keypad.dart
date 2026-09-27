import 'package:flutter/material.dart';

class NumericKeypad extends StatelessWidget {
  final void Function(String) onKeyPressed;
  final VoidCallback onDelete;
  final bool showDelete;
  final bool isLight;
  final Color? keyColor;
  final Color? keyBgColor;
  final Color? keyBorderColor;

  const NumericKeypad({
    super.key,
    required this.onKeyPressed,
    required this.onDelete,
    this.showDelete = true,
    this.isLight = false,
    this.keyColor,
    this.keyBgColor,
    this.keyBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isLight
        ? const Color(0xFFF1F3F8)
        : (isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFF1F3F8));
    final textColor = isLight ? const Color(0xFF0D1438) : Colors.white;
    final borderColor = isLight
        ? const Color(0xFFE4E9F4)
        : (isDark
              ? Colors.white.withValues(alpha: 0.12)
              : const Color(0xFFE4E9F4));

    Widget buildKey(
      String label, {
      bool isAction = false,
      bool isEmpty = false,
      Widget? child,
    }) {
      return GestureDetector(
        onTap: isAction ? onDelete : () => onKeyPressed(label),
        child: Container(
          height: isLight ? 52 : 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isLight ? 15 : 16),
            color: isEmpty
                ? Colors.transparent
                : (keyBgColor ?? backgroundColor),
            border: isEmpty
                ? null
                : Border.all(
                    color: keyBorderColor ?? borderColor,
                    width: isAction ? 1 : 1,
                  ),
          ),
          child:
              child ??
              Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: isLight ? 19 : 20,
                    fontWeight: isAction ? FontWeight.w600 : FontWeight.w600,
                    color: isAction
                        ? (keyColor ??
                              (isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF96A0BC)))
                        : (keyColor ?? textColor),
                  ),
                ),
              ),
        ),
      );
    }

    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', showDelete ? 'del' : ''],
    ];

    return Column(
      children: keys.map((row) {
        return Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((key) {
              if (key.isEmpty) {
                return const Spacer();
              }
              final isAction = key == 'del';
              final isEmpty = key == '';
              return Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: AspectRatio(
                      aspectRatio: isLight ? 1 : 1,
                      child: buildKey(
                        key,
                        isAction: isAction,
                        isEmpty: isEmpty,
                        child: isEmpty
                            ? null
                            : isAction
                            ? Icon(
                                Icons.backspace_rounded,
                                size: 20,
                                color:
                                    keyColor ??
                                    (isLight
                                        ? const Color(0xFF96A0BC)
                                        : const Color(0xFF94A3B8)),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
