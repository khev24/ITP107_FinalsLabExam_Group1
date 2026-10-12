import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// Flat, clean AppBar used on every screen (replaces the old gradient bar).
/// Shows a round back button automatically when the screen can go back.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  /// When true the bar is deep green with white text (used on Details).
  final bool dark;

  const AppTopBar({
    super.key,
    required this.title,
    this.actions,
    this.dark = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return AppBar(
      backgroundColor: dark ? kPrimary : null,
      foregroundColor: dark ? Colors.white : null,
      systemOverlayStyle:
          dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      titleTextStyle: dark
          ? Theme.of(context)
              .appBarTheme
              .titleTextStyle
              ?.copyWith(color: Colors.white)
          : null,
      toolbarHeight: kToolbarHeight + 8,
      automaticallyImplyLeading: false,
      leadingWidth: canPop ? 68 : null,
      titleSpacing: canPop ? 4 : 20,
      leading: canPop
          ? Padding(
              padding: const EdgeInsets.only(left: 16),
              child: CircleIconButton(
                dark: dark,
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : null,
      title: Text(title),
      actions: actions,
    );
  }
}

/// Small round white button with a hairline border.
class CircleIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final bool dark;

  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: dark ? Colors.white.withAlpha(25) : kSurface,
        shape: CircleBorder(
            side:
                BorderSide(color: dark ? Colors.white.withAlpha(40) : kBorder)),
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: icon,
          color: dark ? Colors.white : kInk,
          iconSize: 20,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
