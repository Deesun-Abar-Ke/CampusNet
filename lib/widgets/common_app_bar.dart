import 'package:flutter/material.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final Color backgroundColor;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool centerTitle;
  final double? elevation;
  final IconThemeData? iconTheme;

  const CommonAppBar({
    super.key,
    required this.title,
    this.backgroundColor = const Color(0xFF003366),
    this.actions,
    this.showBackButton = true,
    this.centerTitle = false,
    this.elevation,
    this.iconTheme,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      backgroundColor: backgroundColor,
      foregroundColor: Colors.white,
      centerTitle: centerTitle,
      elevation: elevation,
      iconTheme: iconTheme,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      actions: [
        if (actions != null) ...actions!,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
