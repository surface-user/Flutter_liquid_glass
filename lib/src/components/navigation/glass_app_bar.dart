import 'package:flutter/material.dart';
import '../../core/style.dart';
import '../../theme/theme.dart';
import '../surfaces/glass_surface.dart';

/// Use Scaffold.extendBodyBehindAppBar to provide content behind the blur.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.style,
    this.bottom,
    this.toolbarHeight = kToolbarHeight,
    this.automaticallyImplyLeading = true,
  });
  final Widget? title, leading;
  final List<Widget>? actions;
  final GlassStyle? style;
  final PreferredSizeWidget? bottom;
  final double toolbarHeight;
  final bool automaticallyImplyLeading;
  @override
  Size get preferredSize =>
      Size.fromHeight(toolbarHeight + (bottom?.preferredSize.height ?? 0));
  @override
  Widget build(BuildContext context) => GlassSurface(
    style: style ?? LiquidGlassTheme.of(context).appBarStyle,
    child: AppBar(
      title: title,
      leading: leading,
      actions: actions,
      bottom: bottom,
      automaticallyImplyLeading: automaticallyImplyLeading,
      toolbarHeight: toolbarHeight,
      foregroundColor: glassTextStyle(
        context,
        LiquidGlassTheme.of(context).textTheme.titleLarge,
      ).color,
      titleTextStyle: LiquidGlassTheme.of(context).textTheme.titleLarge == null
          ? null
          : Theme.of(context).textTheme.titleLarge?.merge(
              glassTextStyle(
                context,
                LiquidGlassTheme.of(context).textTheme.titleLarge,
              ),
            ),
      titleSpacing: LiquidGlassTheme.of(context).layout.appBarTitleSpacing,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
  );
}
