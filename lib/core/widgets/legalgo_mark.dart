import 'package:flutter/material.dart';

const _legalGoFavicon = 'assets/branding/legalgo_favicon.png';

class LegalGoMark extends StatelessWidget {
  const LegalGoMark({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = compact ? 36.0 : 44.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          padding: EdgeInsets.all(compact ? 5 : 6),
          child: Image.asset(
            _legalGoFavicon,
            fit: BoxFit.contain,
            semanticLabel: 'LegalGo',
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
