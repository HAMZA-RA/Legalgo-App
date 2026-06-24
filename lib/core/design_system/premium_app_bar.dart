import 'package:flutter/material.dart';
import 'package:legalgo_mobile/core/design_system/app_colors.dart';
import 'package:legalgo_mobile/core/design_system/app_spacing.dart';
import 'package:legalgo_mobile/core/widgets/legalgo_mark.dart';

class PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PremiumAppBar({super.key, required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    final background = AppColors.pageBackground(context);
    return AppBar(
      toolbarHeight: preferredSize.height,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      backgroundColor: background,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: onBack == null,
      leading: onBack == null
          ? null
          : IconButton(
              tooltip: 'Retour',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
      titleSpacing: onBack == null ? AppSpacing.screenHorizontal : 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LegalGoMark(compact: true),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 1,
            height: 28,
            color: AppColors.subtleBorder(context),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
