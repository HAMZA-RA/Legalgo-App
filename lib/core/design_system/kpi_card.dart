import 'package:flutter/material.dart';
import 'package:legalgo_mobile/core/design_system/app_card.dart';
import 'package:legalgo_mobile/core/design_system/app_colors.dart';
import 'package:legalgo_mobile/core/design_system/app_radius.dart';
import 'package:legalgo_mobile/core/design_system/app_spacing.dart';

class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
    this.accent = AppColors.softIndigo,
  });

  final String title;
  final String value;
  final IconData icon;
  final String? subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxHeight < 172 || constraints.maxWidth < 180;
        final iconSize = compact ? 36.0 : 42.0;
        final valueStyle =
            (compact
                    ? Theme.of(context).textTheme.titleLarge
                    : Theme.of(context).textTheme.headlineSmall)
                ?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : AppColors.navy,
                  letterSpacing: 0,
                );

        return AppCard(
          padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
          child: compact
              ? Row(
                  children: [
                    _KpiIconBadge(
                      icon: icon,
                      accent: accent,
                      size: iconSize,
                      iconSize: 19,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: valueStyle,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _KpiAccentDot(accent: accent),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _KpiIconBadge(
                          icon: icon,
                          accent: accent,
                          size: iconSize,
                          iconSize: 21,
                        ),
                        const Spacer(),
                        _KpiAccentDot(accent: accent),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: valueStyle,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }
}

class _KpiIconBadge extends StatelessWidget {
  const _KpiIconBadge({
    required this.icon,
    required this.accent,
    required this.size,
    required this.iconSize,
  });

  final IconData icon;
  final Color accent;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .10),
        borderRadius: AppRadius.icon,
      ),
      child: Icon(icon, color: accent, size: iconSize),
    );
  }
}

class _KpiAccentDot extends StatelessWidget {
  const _KpiAccentDot({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .55),
        shape: BoxShape.circle,
      ),
    );
  }
}
