import 'package:flutter/material.dart';
import 'package:legalgo_mobile/core/design_system/app_colors.dart';
import 'package:legalgo_mobile/core/design_system/app_spacing.dart';

const _legalGoFavicon = 'assets/branding/legalgo_favicon.png';

class PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PremiumAppBar({super.key, required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(72);

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
          const _HeaderLogo(),
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
                fontSize: 18,
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

class _HeaderLogo extends StatelessWidget {
  const _HeaderLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(5),
      child: Image.asset(
        _legalGoFavicon,
        fit: BoxFit.contain,
        semanticLabel: 'LegalGo',
      ),
    );
  }
}
