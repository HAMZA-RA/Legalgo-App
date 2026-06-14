import 'package:flutter/material.dart';

class LegalGoMark extends StatelessWidget {
  const LegalGoMark({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 36 : 44,
          height: compact ? 36 : 44,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.balance_rounded,
            color: scheme.onPrimary,
            size: compact ? 20 : 24,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'LegalGo',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
        ),
      ],
    );
  }
}
