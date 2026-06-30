import 'package:flutter/material.dart';
import 'package:legalgo_mobile/core/design_system/app_colors.dart';
import 'package:legalgo_mobile/core/design_system/app_radius.dart';
import 'package:legalgo_mobile/core/design_system/app_shadows.dart';
import 'package:legalgo_mobile/core/design_system/app_spacing.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.onTap,
    this.color,
    this.gradient,
    this.borderColor,
    this.shadows,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final Color? borderColor;
  final List<BoxShadow>? shadows;

  @override
  Widget build(BuildContext context) {
    final radius = AppRadius.card;
    final decoration = BoxDecoration(
      color: gradient == null
          ? (color ?? AppColors.cardSurface(context))
          : null,
      gradient: gradient,
      borderRadius: radius,
      border: Border.all(color: borderColor ?? AppColors.subtleBorder(context)),
      boxShadow: shadows ?? AppShadows.soft(context),
    );

    final content = Ink(
      decoration: decoration,
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) {
      return Container(margin: margin, child: content);
    }

    return Container(
      margin: margin,
      child: Material(
        color: Colors.transparent,
        child: InkWell(borderRadius: radius, onTap: onTap, child: content),
      ),
    );
  }
}
